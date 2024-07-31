import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voluntariado_app/models/chat_message.dart';
import 'package:voluntariado_app/screens/chat_screen.dart';
import '../service/firestore_service.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Chats', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: StreamBuilder<List<ChatPreview>>(
        stream: firestoreService.getChatPreviews(user!.email!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.teal));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }
          final chatPreviews = snapshot.data ?? [];
          if (chatPreviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  Text('No chats available',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: chatPreviews.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey[300]),
            itemBuilder: (context, index) {
              final preview = chatPreviews[index];
              return _buildChatPreviewTile(context, preview);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatPreviewTile(BuildContext context, ChatPreview preview) {
    return FutureBuilder<String?>(
      future: preview.isGroup
          ? getUserProfilePictureGroup(preview.chatId)
          : getUserProfilePicture(preview.userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(
            backgroundColor: Colors.grey,
            radius: 30,
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const CircleAvatar(
            backgroundImage: AssetImage('assets/help_icon.png'),
            radius: 30,
            backgroundColor: Colors.white,
          );
        }
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundImage: NetworkImage(snapshot.data!),
            radius: 30,
            backgroundColor: Colors.white,
            onBackgroundImageError: (exception, stackTrace) {},
          ),
          title: Text(
            preview.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                preview.lastMessage,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatLastMessageTime(preview.lastMessageTime),
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  receiverId: preview.name,
                  receiverName: preview.name,
                  receiverPhotoUrl: snapshot.data,
                  isGroup: preview.isGroup,
                ),
              ),
            );
          },
        );
      },
    );
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

  Future<String?> getUserProfilePictureGroup(String chatId) async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final snapshot = await db.collection('chats').doc(chatId).get();
    if (snapshot.exists) {
      final data = snapshot.data();
      if (data != null && data.containsKey('groupPhotoUrl')) {
        final photoUrl = data['groupPhotoUrl'] as String?;
        return photoUrl;
      } else {}
    } else {}
    return null;
  }

  String _formatLastMessageTime(String timestamp) {
    DateTime? dateTime;
    try {
      dateTime = DateTime.parse(timestamp);
    } catch (e) {
      try {
        final now = DateTime.now();
        final time = DateFormat("hh:mm a").parse(timestamp);
        dateTime =
            DateTime(now.year, now.month, now.day, time.hour, time.minute);
      } catch (e) {
        return timestamp;
      }
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat.jm().format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat.MMMd().format(dateTime);
    }
  }
}
