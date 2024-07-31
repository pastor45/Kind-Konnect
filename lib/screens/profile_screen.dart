// ignore_for_file: library_private_types_in_public_api, use_super_parameters

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voluntariado_app/screens/edit_profile_screen.dart';
import '../models/badge.dart';
import '../models/user_profile.dart';
import '../service/firestore_service.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import 'package:flutter_glassmorpism/flutter_glassmorpism.dart';

import 'chatbot_screen.dart';
import 'home_screen.dart';
import 'opportunities_screen.dart';
import 'package:page_transition/page_transition.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 2;
void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = const HomeScreen();
        break;
      case 1:
        nextScreen =
            const OpportunitiesScreen();
        break;
      case 2:
        nextScreen = const ProfileScreen(); 
        break;
      case 3:
        nextScreen = const ChatbotScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageTransition(
        type: PageTransitionType.fade,
        child: nextScreen,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        elevation: 0,
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
          return _buildProfileContent(user, userProfile);
        },
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildProfileContent(User? user, UserProfile? userProfile) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(
            height: 15,
          ),
          _buildProfileHeader(user, userProfile),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: _buildProfileCard(user, userProfile),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(User? user, UserProfile? userProfile) {
    return SizedBox(
      height: 270,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          _buildStartProfile(user, userProfile),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 130,
              width: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color.fromARGB(255, 255, 255, 255),
                image: DecorationImage(
                    image: NetworkImage(userProfile!.photoURL!)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProfileCard(User? user, UserProfile? userProfile) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBadgesRow(userProfile?.badges ?? []),
            _buildInfoRow(Icons.info, 'Bio', userProfile?.bio ?? ''),
            _buildInfoRow(
                Icons.build, 'Skills', userProfile?.skills?.join(', ') ?? ''),
            _buildInfoRow(Icons.favorite, 'Interests',
                userProfile?.interests?.join(', ') ?? ''),
            const SizedBox(height: 20),
            _buildEditProfileButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEditProfileButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => const EditProfileScreen())),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child:
            const Text('Edit Profile', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.teal, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesRow(List<String> badges) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.badge, color: Colors.teal, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Badges',
                    style: TextStyle(
                        color: Colors.teal, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: badges.map((badge) {
                    final badgeData = badgeInfo[badge];
                    return Tooltip(
                      message: badgeData?['description'] ?? 'Unknown badge',
                      child: Icon(badgeData?['icon'] ?? Icons.help_outline,
                          color: Colors.teal, size: 30),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

@override
Widget _buildStartProfile(User? user, UserProfile? userProfile) {
  String? userName;

  if (user!.displayName.toString() != 'null') {
    userName = user.displayName;
  } else {
    userName = userProfile!.name;
  }
  return GlassmorphicContainer(
    width: double.maxFinite,
    height: 200,
    backgroundColor: Colors.teal,
    border: 0,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            user.email ?? 'Anonymous',
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    '${userProfile?.points ?? 0}',
                    style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                  const Text("Points",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ))
                ],
              ),
              Column(
                children: [
                  Text(
                    "$userName",
                    style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                  const Text("Name",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ))
                ],
              ),
              Column(
                children: [
                  Text(
                    "${userProfile?.badges.length ?? 0}",
                    style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                  const Text("Badges",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ))
                ],
              )
            ],
          )
        ],
      ),
    ),
  );
}
