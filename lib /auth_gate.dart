import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'donor_home_page.dart';
import 'beneficiary_home_page.dart';
import 'welcome_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Widget> _getHome() async {
    final user = FirebaseAuth.instance.currentUser;

    //  إذا ما فيه مستخدم
    if (user == null) {
      return const WelcomePage();
    }

    final email = user.email?.trim().toLowerCase() ?? '';

    try {
      //  نجيب المستخدم من Firestore
      final userQuery = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      // إذا ما لقيه
      if (userQuery.docs.isEmpty) {
        return const WelcomePage();
      }

      final data = userQuery.docs.first.data();
      final role = (data['role'] ?? '').toString().trim().toLowerCase();

      //  توجيه حسب الدور
      if (role == 'beneficiary') {
        return BeneficiaryHomePage(userEmail: email);
      }

      // default = donor
      return DonorHomePage(userEmail: email);

    } catch (e) {
      debugPrint("AuthGate Error: $e");
      return const WelcomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getHome(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("حدث خطأ")),
          );
        }

        return snapshot.data ?? const WelcomePage();
      },
    );
  }
}
