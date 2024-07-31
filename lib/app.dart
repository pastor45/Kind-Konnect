// ignore_for_file: deprecated_member_use

import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/chatbot_screen.dart';
import 'screens/home_screen.dart';
import 'screens/opportunities_screen.dart';
import 'screens/profile_screen.dart';
import 'service/auth_service.dart';
import 'service/firestore_service.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        title: 'KindKonnect',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          hintColor: Colors.tealAccent,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ),
          appBarTheme: AppBarTheme(
            color: Colors.teal,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            systemOverlayStyle: SystemUiOverlayStyle.light,
            toolbarTextStyle: GoogleFonts.poppinsTextTheme(
              Theme.of(context).textTheme,
            ).apply(bodyColor: Colors.white).bodyMedium,
            titleTextStyle: GoogleFonts.poppinsTextTheme(
              Theme.of(context).textTheme,
            ).apply(bodyColor: Colors.white).titleLarge,
          ),
          buttonTheme: ButtonThemeData(
            buttonColor: Colors.teal,
            textTheme: ButtonTextTheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
            ),
          ),
          cardTheme: CardTheme(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          scaffoldBackgroundColor: Colors.teal[50],
        ),

        home: WillPopScope(
          onWillPop: () async {
            Navigator.of(context).pop();
            return false; 
          },
          child: AnimatedSplashScreen(
            duration: 2500,
            splash: "assets/help_icon.png",
            splashIconSize: 180,
            nextScreen: const HomeScreen(),
            splashTransition: SplashTransition.fadeTransition,
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        locale: const Locale('en', 'EN'),
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        routes: {
          '/home': (context) => const HomeScreen(),
          '/chat': (context) => const ChatbotScreen(),
          '/opportunities': (context) => const OpportunitiesScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}
