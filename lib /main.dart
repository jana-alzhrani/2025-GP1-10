import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'welcome_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'donor_home_page.dart';
import 'donor_more_page.dart';
import 'edit_donation_page.dart';
import 'view_donation_page.dart';
import 'add_donation_page.dart';

void main() {
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

      // Decide first page based on login state
      initialRoute: user == null ? '/' : '/home',

      routes: {

        // Authentication
        '/': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),

        // Donor pages
        '/donorHome': (context) => const DonorHomePage(),
        '/donorMore': (context) => const DonorMorePage(),

        // Donation pages
        '/addDonation': (context) => const AddDonationPage(),
        '/viewDonation': (context) => const ViewDonationPage(),
        '/editDonation': (context) => const EditDonationPage(),
      },
    );
  }
}
