// ignore_for_file: empty_catches, library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voluntariado_app/models/chat_message.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../service/firestore_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart' as auth;

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? receiverPhotoUrl;
  final bool isGroup;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverPhotoUrl,
    required this.isGroup,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserPhotoUrl;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserPhotoUrl();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchCurrentUserPhotoUrl() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      _currentUserPhotoUrl =
          await firestoreService.getUserProfilePicture(user.email!);
      setState(() {});
    }
  }

  void _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    List<String> participants;
    if (widget.isGroup) {
      participants = await firestoreService.getGroupMembers(widget.receiverId);
    } else {
      participants = [user!.email!, widget.receiverId];
    }

    final message = ChatMessage(
      id: const Uuid().v4(),
      senderId: user!.email!,
      receiverId: widget.receiverId,
      message: _messageController.text,
      timestamp: DateTime.now(),
      participants: participants,
      isGroup: widget.isGroup,
      groupId: widget.isGroup ? widget.receiverId : null,
    );
    final String serverKey = await getAccessToken();
    List<String> recipientTokens =
        await _getRecipientTokens(message.participants);
    const String fcmUrl =
        'https://fcm.googleapis.com/v1/projects/thevolunteeringapp/messages:send';

    for (String token in recipientTokens) {
      final Map<String, dynamic> notificationMessage = {
        "message": {
          "token": token,
          "notification": {
            "title": widget.isGroup ? widget.receiverName : "Nuevo mensaje",
            "body": message.message,
          },
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "senderId": message.senderId,
            "messageId": message.id,
          },
        }
      };

      try {
        final http.Response response = await http.post(
          Uri.parse(fcmUrl),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $serverKey',
          },
          body: jsonEncode(notificationMessage),
        );

        if (response.statusCode == 200) {
        } else {
        }
      } catch (e) {
      }
    }

    await firestoreService.sendMessage(message);
    _messageController.clear();
    _scrollToBottom();
  }

  Future<List<String>> _getRecipientTokens(List<String> participants) async {
    List<String> tokens = [];
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    for (String participantEmail in participants) {
      // Excluir al remitente actual
      if (participantEmail != FirebaseAuth.instance.currentUser?.email) {
        try {
          QuerySnapshot userQuery = await firestore
              .collection('users')
              .where('email', isEqualTo: participantEmail)
              .limit(1)
              .get();

          if (userQuery.docs.isNotEmpty) {
            String? token = userQuery.docs.first.get('fcmToken') as String?;
            if (token != null && token.isNotEmpty) {
              tokens.add(token);
            }
          }
        } catch (e) {
        }
      }
    }

    return tokens;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.receiverPhotoUrl != null
                  ? NetworkImage(widget.receiverPhotoUrl!)
                  : const AssetImage('assets/help_icon.png') as ImageProvider,
              radius: 20,
            ),
            const SizedBox(width: 10),
            Text(
              widget.receiverName,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: firestoreService.getMessages(
                  user!.email!, widget.receiverId, widget.isGroup),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(child: Text('No prior conversations'));
                }
                if (messages.isEmpty) {
                  return const Center(child: Text('No prior conversations'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == user.email;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    final timeFormatted = DateFormat('hh:mm a').format(message.timestamp);
    final dateFormatted = DateFormat('dd MMM yyyy').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) _buildAvatar(widget.receiverPhotoUrl),
          if (!isMe) const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? Colors.teal[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$timeFormatted, $dateFormatted',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (isMe) const SizedBox(width: 5),
                      if (isMe)
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 16,
                          color: message.isRead ? Colors.teal : Colors.grey,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 10),
          if (isMe) _buildAvatar(_currentUserPhotoUrl),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? photoUrl) {
    return CircleAvatar(
      backgroundImage: photoUrl != null
          ? NetworkImage(photoUrl)
          : const AssetImage('assets/help_icon.png') as ImageProvider,
      radius: 15,
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Colors.white,
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Write a message...',
                hintStyle: const TextStyle(color: Colors.teal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.all(12.0),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          FloatingActionButton(
            onPressed: _sendMessage,
            backgroundColor: Colors.teal,
            elevation: 0,
            mini: true,
            child: const Icon(
              Icons.send,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<String> getAccessToken() async {
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "thevolunteeringapp",
      "private_key_id": "c41647a516884d47715eda7cc4af370ee746d03d",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCzbqaMoiTxKobZ\ncwW6ld66mldygBTSTf7AkKpWK2Xtd0vX2RGo0KkldL3aJMrR6ds7bSSysx7wdkZa\n8zpciuWzftftVv5uBi68G3iJ66wklrozoU9FZ4fAHM9V4FgX9fhnMqs3bOnPDMh5\n2PJRkpT+fF4lcsuc/NYs143prWvAt6ivG8FJ4EzN0RwIe58C2GwfLXDCU6twN4I2\n1iMlX+1XifBx9wsVgfsGsn4sxZnud3ezpLb6dq/pmk5WSeoCQRZdSmsiOdvoyP5i\nqmTfR6JuBBjI+vit/NnzMKyKrW0VyvhRzP2vvhBbNIqScb76a7NoEI689EhJ/vMa\nZWlbQFiDAgMBAAECggEAQu/d6OvaLS+os7kho3wiZWmLgtb+LYBUL4EoUlIJSb+t\nxv2fBWOmHieBZb5A/XMoynAKdzG0Mo9k6qv/EyPr0fzZT5ya+O+MgrcazhThmJq0\nJuuf92vKbCQzQr2ZD4M+ojz4O4qBZLDHnxEMQNsWgyNhOcYr6Eo4Ge1l7w03e+JH\n3nMPItA4fDga4Objkwqn4hIHrvaCiWOrRUwQfJJPQcL8E/eNNSFOHDxejE0tNxqQ\nVyFBRoJb5Nqs8iN43+95VbC/xhvry1MdjQOQSY/Fl8ftF1vUQ75G4hutLkk3zqfu\nPhofcWwTTNvPbEm2z4AHH2r+umE2BRU+H6fvBSVnQQKBgQDe7w58Fdfw0D0CpzHG\n6ZJmcZXz90FZMLrpTZH9bZ58KMAJofRnmR5qJfEy+z2XRCE7YMlXDvsGqiL3wYA/\n6z2CNgkSs0rBEtaXglxv/UE7egcFxr7TA+xOqaymsItav/kcrtnS91UU2o0tBRed\n85kRj4L0oCjtlO1A+VuxfbdawwKBgQDOC89pfI+8UwP/EP0mTVKJKklUT/5XtwQh\n0zHwx8CQeX3OLMAhWxNJngCxTgaWu5MNPnq5I/Dz83IwRmhznDzrlvF1GAsvDXm5\nmdQM1tdkGrslHt0MXZrirzr0CTznDgHY+f8ifrLz0UoqWmzK4oLWNOfxtXeebjrp\npwziRE2vQQKBgGrqzdCXDUySImCOXSIfzTXSje9GixHCfDH+IOEhXJwBUzCLetLg\nraSM8+PWeNB+PU3j+kwFhEDLAiA+rkp5gLNdRPayBE0aws5BGCIhnNJwkMOlcMl1\nHTUQzRvYmcz5OvkVpqQ2OJjaxFBuG8iGFshEQrMdyONAxJSfwukZ+QDPAoGAcyKc\nUticxOIqkIPgwV9hqG3treRJPqBw+am29VHZY6HPz76n2bu3qmJVBr6P5fiIslTg\nZMYVpWu6ugkN4tRCIm8lG4ZE8ZT5GOJBYK9IipJ5UsPNR1Si8Npz+duToZTtKV6A\n17iurJmddM80jaZG8AV+Ok1puyjjWJ7VDzaVpkECgYEA24TpV7u9Hl+Pb7XOw+BD\nF4YmegR6AOLdMG3Qw5KAuqklrJ/KVZYZ2O7SzhQxzXnQPfySIQASJyRBAEErpMM5\n9lhfQfmFmtSUSS+gOZ/6kb7gatPQJOIBqFU8EFA98UlwsGuPHCm/ZV/k3ZYfRHEd\nGhaCpVWe9ubFJ6J/XxUifqs=\n-----END PRIVATE KEY-----\n",
      "client_email":
          "firebase-adminsdk-s1z5e@thevolunteeringapp.iam.gserviceaccount.com",
      "client_id": "102007347345887580377",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-s1z5e%40thevolunteeringapp.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };

    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging",
    ];

    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    auth.AccessCredentials credentials =
        await auth.obtainAccessCredentialsViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
      client,
    );

    client.close();

    return credentials.accessToken.data;
  }
}
