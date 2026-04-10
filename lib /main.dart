import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:madad_app/firebase_options.dart'; // name project folder (madad_app) 

import 'welcome_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'donor_home_page.dart';
import 'edit_donation_page.dart';
import 'view_donation_page.dart';
import 'add_donation_page.dart';
import 'donor_more_page.dart';
import 'app_design.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    // Check if user is logged in
    User? user = FirebaseAuth.instance.currentUser;

    return MaterialApp(
      debugShowCheckedModeBanner: false,


  theme: AppDesign.lightTheme,


      // Decide first page based on login state
      initialRoute: user == null ? '/' : '/donorHome',

      routes: {

        // Authentication
        '/': (context) => const WelcomePage(),
        '/login': (context) =>  LoginPage(),
        '/signup': (context) =>  SignUpPage(),

        // Donor pages
        '/donorHome': (context) {
    final email = ModalRoute.of(context)!.settings.arguments as String;

    return DonorHomePage(userEmail: email);
  },
        '/addDonation': (context) => const AddDonationPage(),
        '/viewDonation': (context) => const ViewDonationPage(),
      },
    );
  }
}
