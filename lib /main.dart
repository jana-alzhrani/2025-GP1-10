import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:madad_app/firebase_options.dart';

import 'auth_gate.dart';
import 'welcome_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'donor_home_page.dart';
import 'view_donation_page.dart';
import 'add_donation_page.dart';
import 'donor_more_page.dart';
import 'Beneficiary_home_page.dart';
import 'delivery_method_page.dart';
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

  String _currentUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppDesign.lightTheme,

      home: user == null ? const WelcomePage() : const AuthGate(),

      routes: {
        '/welcome': (context) => const WelcomePage(),

        '/login': (context) => LoginPage(),

        '/signup': (context) => SignUpPage(),

        '/donorHome': (context) {
          final uid =
              (ModalRoute.of(context)?.settings.arguments as String?) ??
                  _currentUserId();

          return DonorHomePage(userId: uid);
        },

        '/beneficiaryHome': (context) {
          final uid =
              (ModalRoute.of(context)?.settings.arguments as String?) ??
                  _currentUserId();

          return BeneficiaryHomePage(userId: uid);
        },

        '/viewDonation': (context) {
          final uid =
              (ModalRoute.of(context)?.settings.arguments as String?) ??
                  _currentUserId();

          return ViewDonationPage(userId: uid);
        },

        '/donorMore': (context) {
          final uid =
              (ModalRoute.of(context)?.settings.arguments as String?) ??
                  _currentUserId();

          return DonorMorePage(userId: uid);
        },

        '/addDonation': (context) {
          final uid =
              (ModalRoute.of(context)?.settings.arguments as String?) ??
                  _currentUserId();

          return AddDonationPage(userId: uid);
        },

        '/deliveryMethod': (context) {
          final donationId =
              ModalRoute.of(context)!.settings.arguments as String;

          return DeliveryMethodPage(
            donationId: donationId,
          );
        },
      },
    );
  }
}
