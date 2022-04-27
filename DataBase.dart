import 'package:bil/model/Activity.dart';
import 'package:bil/model/posting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bil/constant/constants.dart';
//import 'package:twitter/Models/Activity.dart';
import 'package:bil/model/posting.dart';
import 'package:bil/model/user.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseServices {
  static void updateUserData(Usermodel user) {
    usersRef.doc(user.id).update({
      'name': user.name,
      'bio': user.bio,
      'profilePicture': user.profilePicture,
      'coverImage': user.coverImage,
    });
  }

  static void createPost(Posting posting) {
    postsRef.doc(posting.authorId).set({'postTime': posting.timestamp});
    postsRef.doc(posting.authorId).collection('userposts').add({
      'text': posting.text,
      'image': posting.image,
      "authorId": posting.authorId,
      "timestamp": posting.timestamp,
      'likes': posting.likes,
    }).then((doc) async {
      QuerySnapshot feedSnapshot =
          await postsRef.doc(posting.authorId).collection('userposts').get();
      for (var docSnapshot in feedSnapshot.docs) {
        FirebaseFirestore.instance.collection('userfeed').doc(doc.id).set({
          'text': posting.text,
          'image': posting.image,
          "authorId": posting.authorId,
          "timestamp": posting.timestamp,
          'likes': posting.likes,
        });
      }
    });
  }

  static Future<List> getHomePosts(String currentUserId) async {
    QuerySnapshot homeposts = await FirebaseFirestore.instance
        .collection('userfeed')
        .orderBy('timestamp', descending: true)
        .get();
    List<Posting> userposts =
        homeposts.docs.map((doc) => Posting.fromDoc(doc)).toList();
    return userposts;
  }

  static void likePosting(String currentUserId, Posting posting) {
    DocumentReference postingDocProfile =
        postsRef.doc(posting.authorId).collection('userposts').doc(posting.id);
    postingDocProfile.get().then((doc) {
      int likes =
          doc.data().toString().contains('likes') ? doc.get('likes') : '';
      postingDocProfile.update({'likes': likes + 1});
    });
    DocumentReference postingDocFeed =
        FirebaseFirestore.instance.collection('userfeed').doc(posting.id);
    postingDocFeed.get().then((doc) {
      if (doc.exists) {
        int likes =
            doc.data().toString().contains('likes') ? doc.get('likes') : '';
        //doc.data().toString().contains('likes') ? doc.get('likes') : '';
        postingDocFeed.update({'likes': likes + 1});
      }
    });
    likesRef
        .doc(posting.id)
        .collection('postingLikes')
        .doc(currentUserId)
        .set({});
  }

  static void unlikePosting(String currentUserId, Posting posting) {
    DocumentReference postingDocProfile =
        postsRef.doc(posting.authorId).collection('userposts').doc(posting.id);
    postingDocProfile.get().then((doc) {
      int likes =
          doc.data().toString().contains('likes') ? doc.get('likes') : '';
      postingDocProfile.update({'likes': likes - 1});
    });
    DocumentReference postingDocFeed =
        FirebaseFirestore.instance.collection('userfeed').doc(posting.id);
    postingDocFeed.get().then((doc) {
      if (doc.exists) {
        int likes =
            doc.data().toString().contains('likes') ? doc.get('likes') : '';
        postingDocFeed.update({'likes': likes - 1});
      }
    });
    likesRef
        .doc(posting.id)
        .collection('postingLikes')
        .doc(currentUserId)
        .get()
        .then((doc) => doc.reference.delete());
  }

  static Future<bool> isLikePosting(
      String currentUserId, Posting posting) async {
    DocumentSnapshot userDoc = await likesRef
        .doc(posting.id)
        .collection('postingLikes')
        .doc(currentUserId)
        .get();

    return userDoc.exists;
  }

  static Future<List<Activity>> getActivities(String userId) async {
    QuerySnapshot userActivitiesSnapshot = await activitiesRef
        .doc(userId)
        .collection('userActivities')
        .orderBy('timestamp', descending: true)
        .get();

    List<Activity> activities = userActivitiesSnapshot.docs
        .map((doc) => Activity.fromDoc(doc))
        .toList();

    return activities;
  }

  static void addActivity(
    String currentUserId,
    bool userId,
    Posting posting,
    Usermodel usermodel,
  ) {
    if (userId) {
      activitiesRef.doc(currentUserId).collection('userActivities').add({
        'fromUserId': currentUserId,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        "follow": true,
      });
    } else {
      //like

      activitiesRef.doc(posting.authorId).collection('userActivities').add({
        'fromUserId': currentUserId,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        "follow": false,
      });
    }
  }
}
