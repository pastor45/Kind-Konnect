// ignore_for_file: unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../models/volunteer_opportunity.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<VolunteerOpportunity>> getOpportunitiesByCategory(
      String category) {
    return _db
        .collection('opportunities')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VolunteerOpportunity.fromFirestore(doc.data()))
            .toList());
  }

  Stream<List<VolunteerOpportunity>> getSubscribedOpportunities(
      String userEmail) {
    return _db
        .collection('opportunities')
        .where('volunteers', arrayContains: userEmail)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VolunteerOpportunity.fromFirestore(doc.data()))
            .toList());
  }

  Stream<List<VolunteerOpportunity>> getOpportunitiesByCategories(
      List<String> categories) {
    return _db
        .collection('opportunities')
        .where('category', whereIn: categories)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VolunteerOpportunity.fromFirestore(doc.data()))
            .toList());
  }

  Future<void> updateOpportunityStatus(
      String opportunityId, String status) async {
    final docRef = _db.collection('opportunities').doc(opportunityId);
    await docRef.update({
      'status': status,
    });
  }

  Future<void> registerVolunteer(
      String opportunityId, String volunteerId) async {
    final docRef = _db.collection('opportunities').doc(opportunityId);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      await docRef.update({
        'volunteers': FieldValue.arrayUnion([volunteerId]),
      });

      await createOrJoinGroupChat(opportunityId, volunteerId);
    } else {
      throw Exception('Document with ID $opportunityId not found');
    }
  }

  Stream<List<String>> getVolunteers(String opportunityId) {
    return _db
        .collection('opportunities')
        .doc(opportunityId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return List<String>.from(doc['volunteers'] ?? []);
      } else {
        throw Exception('Document with ID $opportunityId not found');
      }
    });
  }

  Future<void> createUserProfile(UserProfile profile) {
    return _db.collection('users').doc(profile.uid).set(profile.toMap());
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _db
          .collection('users')
          .doc(profile.uid)
          .set(profile.toMap(), SetOptions(merge: true));
    } catch (e) {
      rethrow; 
    }
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserProfile.fromFirestore(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Stream<List<VolunteerOpportunity>> getOpportunities() {
    return _db.collection('opportunities').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => VolunteerOpportunity.fromFirestore(doc.data()))
            .toList());
  }

  Future<void> addOpportunity(VolunteerOpportunity opportunity) async {
    final docRef = await _db
        .collection('opportunities')
        .doc(opportunity.id)
        .set(opportunity.toMap());
  }

  Future<void> joinOpportunity(
      VolunteerOpportunity opportunity, String userEmail) async {
    final docRef = _db.collection('opportunities').doc(opportunity.id);
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      final data = snapshot.data()!;
      final List<String> volunteers =
          List<String>.from(data['volunteers'] ?? []);

      if (!volunteers.contains(userEmail) &&
          volunteers.length < opportunity.limit) {
        volunteers.add(userEmail);
        await docRef.update({'volunteers': volunteers});
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(opportunity.id)
            .update({
          'members': FieldValue.arrayUnion([userEmail])
        });
        final userQuery = await _db
            .collection('users')
            .where('email', isEqualTo: userEmail)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final userDoc = userQuery.docs.first;
          final userDocRef = userDoc.reference;

          await userDocRef.update({
            'points': FieldValue.increment(10),
          });
          final updatedUserDoc = await userDocRef.get();
          int points = updatedUserDoc['points'];

          if (points >= 100) {
            await userDocRef.update({
              'badges': FieldValue.arrayUnion(['active_contributor'])
            });
          }
        } else {
          throw Exception('Usuario no encontrado.');
        }
      } else {
        throw Exception(
            'No se puede unir, el límite de personas se ha alcanzado o ya estás inscrito.');
      }
    } else {
      throw Exception('Oportunidad no encontrada.');
    }
  }

  Future<void> leaveOpportunity(
      VolunteerOpportunity opportunity, String userEmail) async {
    final docRef = _db.collection('opportunities').doc(opportunity.id);
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      final data = snapshot.data()!;
      final List<String> volunteers =
          List<String>.from(data['volunteers'] ?? []);

      if (volunteers.contains(userEmail)) {
        volunteers.remove(userEmail);
        await docRef.update({'volunteers': volunteers});

        final userQuery = await _db
            .collection('users')
            .where('email', isEqualTo: userEmail)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final userDoc = userQuery.docs.first;
          final userDocRef = userDoc.reference;

          await userDocRef.update({
            'points': FieldValue.increment(-10), // Restar 10 puntos
          });
          await userDocRef.update({
            'badges': FieldValue.arrayUnion(['quitter'])
          });
        } else {
          throw Exception('Usuario no encontrado.');
        }
      } else {
        throw Exception('No estás inscrito en esta oportunidad.');
      }
    } else {
      throw Exception('Oportunidad no encontrada.');
    }
  }

  Future<void> deleteOpportunity(String opportunityId) async {
    final docRef = _db.collection('opportunities').doc(opportunityId);
    final docRefGroup = _db.collection('chats').doc(opportunityId);
    await docRefGroup.delete();
    await docRef.delete();
  }

  Future<void> addRating(
      String opportunityId, String userId, double rating) async {
    final docRef = _db.collection('opportunities').doc(opportunityId);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      await docRef.update({
        'ratings.$userId': rating,
      });
    } else {
      throw Exception('Document with ID $opportunityId not found');
    }
  }

  Future<void> updateUserPoints(String userEmail, int points) async {
    final userQuery = await _db
        .collection('users')
        .where('email', isEqualTo: userEmail)
        .get();

    if (userQuery.docs.isNotEmpty) {
      final userDoc = userQuery.docs.first;
      final userDocRef = userDoc.reference;

      await userDocRef.update({
        'points': FieldValue.increment(points), 
      });

      final updatedUserDoc = await userDocRef.get();
      int totalPoints = updatedUserDoc['points'];

      if (totalPoints >= 100) {
        await userDocRef.update({
          'badges': FieldValue.arrayUnion(['Voluntario Estrella'])
        });
      }
    } else {
      throw Exception('Usuario no encontrado.');
    }
  }

  Future<void> checkAndAwardBadges(String userId) async {
    final userRef = _db.collection('users').doc(userId);
    final userSnapshot = await userRef.get();

    if (userSnapshot.exists) {
      final userBadges = List<String>.from(userSnapshot.get('badges') ?? []);
      final userPoints = userSnapshot.get('points');

      List<String> newBadges = [];

      if (userPoints >= 100 && !userBadges.contains('active_contributor')) {
        newBadges.add('active_contributor');
      }

      if (newBadges.isNotEmpty) {
        await userRef.update({
          'badges': FieldValue.arrayUnion(newBadges),
        });
      }
    } else {
      throw Exception('User not found.');
    }
  }

  Stream<double> getAverageRating(String opportunityId) {
    return _db
        .collection('opportunities')
        .doc(opportunityId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        Map<String, dynamic> data = snapshot.data()!;
        Map<String, double> ratings =
            Map<String, double>.from(data['ratings'] ?? {});
        if (ratings.isEmpty) {
          return 0.0;
        }
        double sum = ratings.values.reduce((a, b) => a + b);
        return sum / ratings.length;
      } else {
        return 0.0;
      }
    });
  }

  Future<void> createOrJoinGroupChat(
      String opportunityId, String userEmail) async {
    final chatRef = _db.collection('group_chats').doc(opportunityId);
    final chatSnapshot = await chatRef.get();

    if (!chatSnapshot.exists) {
      await chatRef.set({
        'opportunityId': opportunityId,
        'participants': [userEmail],
      });
    } else {
      await chatRef.update({
        'participants': FieldValue.arrayUnion([userEmail]),
      });
    }
  }

  Future<List<String>> getGroupMembers(String groupId) async {
    final querySnapshot =
        await _db.collection('chats').where('name', isEqualTo: groupId).get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      return List<String>.from(doc.data()['members']);
    } else {
      throw Exception('Group not found');
    }
  }

  Future<void> sendMessage(ChatMessage message) async {
    await _db.collection('messages').doc(message.id).set(message.toMap());
  }

  String getChatId(String userId1, String userId2) {
    List<String> users = [userId1, userId2];
    users.sort();
    return users.join('_');
  }

  Stream<List<ChatMessage>> getMySentMessages(String userId, String groupId) {
    return _db
        .collection('messages')
        .where('senderId', isEqualTo: userId)
        .where('groupId', isEqualTo: groupId)
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc.data()))
            .toList());
  }

  Stream<List<ChatMessage>> getMessages(
      String userId, String receiverId, bool isGroup) {
    if (isGroup) {
      return _db
          .collection('messages')
          .where('groupId', isEqualTo: receiverId)
          .orderBy('timestamp')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc.data()))
              .toList())
          .handleError((error) {
        return [];
      });
    } else {
      return _db
          .collection('messages')
          .where('participants', arrayContainsAny: [userId, receiverId])
          .orderBy('timestamp')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                final participants = List<String>.from(data['participants']);
                if (participants.length <= 2 &&
                    participants.contains(userId) &&
                    participants.contains(receiverId)) {
                  return ChatMessage.fromFirestore(data);
                }
                return null;
              })
              .where((message) => message != null)
              .cast<ChatMessage>()
              .toList())
          .handleError((error) {
            return [];
          });
    }
  }

  Future<void> markMessageAsRead(String messageId) {
    return _db.collection('messages').doc(messageId).update({'isRead': true});
  }

  Stream<int> getUnreadMessagesCount(String userId) {
    return _db
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<ChatPreview>> getChatPreviews(String userEmail) {
    final groupChats = _db
        .collection('chats')
        .where('members', arrayContains: userEmail)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return ChatPreview(
                chatId: doc.id,
                name: data['name'] ?? 'Unnamed Group',
                lastMessage: data['lastMessage'] ?? '',
                lastMessageTime: data['lastMessageTime'] ?? '',
                isGroup: true,
                groupPhotoUrl: data['groupPhotoUrl'],
              );
            }).toList());

    final individualChats = _db
        .collection('messages')
        .where('participants', arrayContains: userEmail)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      final chatsMap = <String, ChatPreview>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants']);
        participants.remove(userEmail);
        final otherUserEmail =
            participants.isNotEmpty ? participants.first : '';
        if (!chatsMap.containsKey(otherUserEmail)) {
          chatsMap[otherUserEmail] = ChatPreview(
            chatId: getChatId(userEmail, otherUserEmail),
            name: otherUserEmail,
            lastMessage: data['message'],
            lastMessageTime: data['timestamp'].toDate().toString(),
            isGroup: false,
            userId: otherUserEmail,
          );
        }
      }
      return chatsMap.values.toList();
    });

    return Rx.combineLatest2(groupChats, individualChats,
        (List<ChatPreview> groups, List<ChatPreview> individuals) {
      return [...groups, ...individuals];
    });
  }

  Future<String?> getUserProfilePicture(String email) async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final snapshot =
        await db.collection('users').where('email', isEqualTo: email).get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first['photoURL'] as String?;
    }
    return null;
  }
}
