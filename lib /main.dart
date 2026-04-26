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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? '';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppDesign.lightTheme,

      home: user == null
          ? const WelcomePage()
          : AuthGate(),

      routes: {
        '/login': (context) => LoginPage(),

        '/signup': (context) => SignUpPage(),

        '/welcome': (context) => const WelcomePage(),

        '/donorHome': (context) {
          final email =
              (ModalRoute.of(context)?.settings.arguments as String?) ??
                  userEmail;

          return DonorHomePage(userEmail: email);
        },

        '/beneficiaryHome': (context) {
          final email =
              (ModalRoute.of(context)?.settings.arguments as String?) ??
                  userEmail;

          return BeneficiaryHomePage(userEmail: email);
        },

        '/viewDonation': (context) {
          final email =
              (ModalRoute.of(context)?.settings.arguments as String?) ??
                  userEmail;

          return ViewDonationPage(userEmail: email);
        },

        '/donorMore': (context) {
          final email =
              (ModalRoute.of(context)?.settings.arguments as String?) ??
                  userEmail;

          return DonorMorePage(userEmail: email);
        },

        '/addDonation': (context) => const AddDonationPage(),

        // صفحة اختيار طريقة التوصيل
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
