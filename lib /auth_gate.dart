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

  if (user == null) {
    return const WelcomePage();
  }

  final userId = user.uid;

  try {
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .get();

    if (!doc.exists) {
      return const WelcomePage();
    }

    final data = doc.data()!;
    final role = (data['role'] ?? '').toString().trim().toLowerCase();

    if (role == 'beneficiary') {
    return BeneficiaryHomePage(userId: userId);


} else if (role == 'donor') {
  return DonorHomePage(userId: userId);
} else {
  // لو فيه خطأ في البيانات
  return const WelcomePage();
}

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
