// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voluntariado_app/screens/profile_screen.dart';
import '../models/user_profile.dart';
import '../service/firestore_service.dart';
import 'home_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _bio = '';
  List<String> _skills = [];
  List<String> _interests = [];

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<UserProfile?>(
        future: firestoreService.getUserProfile(user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.teal));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }

          final userProfile = snapshot.data;
          _name = userProfile?.name ?? user.displayName ?? '';
          _bio = userProfile?.bio ?? '';
          _skills = userProfile?.skills ?? [];
          _interests = userProfile?.interests ?? [];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: <Widget>[
                  TextFormField(
                    initialValue: _name,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(color: Colors.teal),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal)),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Required field' : null,
                    onSaved: (value) => _name = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _bio,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      labelStyle: TextStyle(color: Colors.teal),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal)),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Required field' : null,
                    onSaved: (value) => _bio = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _skills.join(', '),
                    decoration: const InputDecoration(
                      labelText: 'Skills (comma separated)',
                      labelStyle: TextStyle(color: Colors.teal),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal)),
                    ),
                    onSaved: (value) => _skills =
                        value!.split(',').map((e) => e.trim()).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _interests.join(', '),
                    decoration: const InputDecoration(
                      labelText: 'Interests (comma separated)',
                      labelStyle: TextStyle(color: Colors.teal),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal)),
                    ),
                    onSaved: (value) => _interests =
                        value!.split(',').map((e) => e.trim()).toList(),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();

                        final updatedProfile = UserProfile(
                          uid: user.uid,
                          name: _name,
                          email: user.email!,
                          photoURL: user.photoURL,
                          bio: _bio,
                          skills: _skills,
                          interests: _interests,
                        );

                        try {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return const AlertDialog(
                                content: Row(
                                  children: [
                                    CircularProgressIndicator(
                                        color: Colors.teal),
                                    SizedBox(width: 20),
                                    Text("Saving changes..."),
                                  ],
                                ),
                              );
                            },
                          );

                          await firestoreService
                              .updateUserProfile(updatedProfile);

                          if (mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (context) => const HomeScreen()),
                            );
                          }

                          if (mounted) {
                            ElegantNotification.success(
                                    description:
                                        const Text('Profile successfully updated'))
                                .show(context);

                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (context) => const ProfileScreen()),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error updating profile: $e')),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
