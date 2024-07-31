// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_profile.dart';
import '../widgets/custom_button.dart';
import '../service/auth_service.dart';
import '../service/firestore_service.dart';
import 'chat_list_screen.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import 'chatbot_screen.dart';
import 'edit_profile_screen.dart';
import 'email_signIn_screen.dart';
import 'opportunities_screen.dart';
import 'profile_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:icons_plus/icons_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  @override
  void initState() {
    super.initState();
    saveFCMToken();
  }

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
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        User? user = snapshot.data;
        if (user == null) {
          return _buildLoginScreen(authService, firestoreService);
        }
        return _buildHomeScreen(user, firestoreService);
      },
    );
  }

  Future<void> saveFCMToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get()
            .then((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            snapshot.docs.first.reference.update({'fcmToken': token});
          }
        });
      }
    }
  }

  Widget _buildLoginScreen(
      AuthService authService, FirestoreService firestoreService) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade200, Colors.teal.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: Image.asset(
                        "assets/help_icon.png",
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Welcome',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Choose a sign-in method',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 50),
                    CustomButton(
                      icon: Icons.login,
                      text: 'Sign in with Google',
                      color: Colors.white,
                      textColor: Colors.teal,
                      onPressed: () =>
                          _signInWithGoogle(authService, firestoreService),
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      icon: Icons.email,
                      text: 'Sign in with Email',
                      color: Colors.tealAccent,
                      textColor: Colors.teal,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const EmailSignInScreen()),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeScreen(User user, FirestoreService firestoreService) {
    return Scaffold(
      appBar: _buildAppBar(user, firestoreService),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.teal.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: Image.asset(
                    "assets/help_icon.png",
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  'Welcome back, ${user.displayName ?? "Volunteer"}!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.teal.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  AppBar _buildAppBar(User user, FirestoreService firestoreService) {
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: Text(
        'KindKonnect',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      actions: [
        _buildChatButton(user, firestoreService),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => _signOut(),
        ),
      ],
    );
  }

  Widget _buildChatButton(User user, FirestoreService firestoreService) {
    return StreamBuilder<int>(
      stream: firestoreService.getUnreadMessagesCount(user.uid),
      builder: (context, snapshot) {
        return Stack(
          children: [
            IconButton(
              icon: const Icon(
                OctIcons.discussion_closed,
              ),
              onPressed: () => _navigateToChatScreen(user),
            ),
            if (snapshot.hasData && snapshot.data! > 0)
              Positioned(
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text(
                    '${snapshot.data}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
          ],
        );
      },
    );
  }

  void _signInWithGoogle(
      AuthService authService, FirestoreService firestoreService) async {
    User? user = await authService.signInWithGoogle();
    if (user != null) {
      UserProfile? profile = await firestoreService.getUserProfile(user.uid);
      if (profile == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  void _navigateToChatScreen(User user) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const ChatListScreen(),
    ));
  }

  void _signOut() {
    Provider.of<AuthService>(context, listen: false).signOut();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => const HomeScreen(),
    ));
  }
}
