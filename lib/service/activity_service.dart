import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity.dart';

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> completeActivity(String userId, Activity activity) async {
    DocumentReference userRef = _firestore.collection('users').doc(userId);

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot userSnapshot = await transaction.get(userRef);

        if (!userSnapshot.exists) {
          throw Exception('User does not exist!');
        }

        int currentPoints = userSnapshot.get('points') ?? 0;
        int newPoints = currentPoints + activity.points;


        Timestamp now = Timestamp.now();

        transaction.update(userRef, {
          'points': newPoints,
          'activityHistory': FieldValue.arrayUnion([
            {
              'id': activity.id,
              'name': activity.name,
              'points': activity.points,
              'completedAt': now,
            }
          ]),
        });

      }, timeout: const Duration(seconds: 10));
    } catch (e) {
      rethrow;
    }
  }
}
