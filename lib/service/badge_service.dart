import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/badge.dart';

class BadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Badge> _badges = [
    Badge(
      id: 'newcomer',
      name: 'Newcomer',
      description: 'Awarded when you create your first opportunity',
      iconUrl: 'path_to_icon',
      requiredPoints: 200,
    ),
    Badge(
      id: 'active_contributor',
      name: 'Active Contributor',
      description: 'Awarded when you create 10 opportunities',
      iconUrl: 'path_to_icon',
      requiredPoints: 0,
    ),
    Badge(
      id: 'veteran',
      name: 'Veteran',
      description: 'Awarded when you create 50 opportunities',
      iconUrl: 'path_to_icon',
      requiredPoints: 0,
    ),
  ];

  Future<void> checkAndAwardBadges(String userId) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('opportunities')
        .where('creator', isEqualTo: userId)
        .get();

    final int opportunityCount = snapshot.docs.length;

    await _firestore.runTransaction((transaction) async {
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      DocumentSnapshot userSnapshot = await transaction.get(userRef);

      if (!userSnapshot.exists) {
        throw Exception('User does not exist!');
      }

      List<dynamic> currentBadges = userSnapshot.get('badges') ?? [];
      List<String> newBadges = [];

      for (Badge badge in _badges) {
        if (!currentBadges.contains(badge.id)) {
          if ((badge.id == 'newcomer' && opportunityCount == 0) ||
              (badge.id == 'active_contributor' && opportunityCount >= 10) ||
              (badge.id == 'veteran' && opportunityCount >= 50)) {
            newBadges.add(badge.id);
          }
        }
      }

      if (newBadges.isNotEmpty) {
        transaction.update(userRef, {
          'badges': FieldValue.arrayUnion(newBadges),
        });
      }
    });
  }
}
