import 'package:flutter/material.dart';
import 'app_design.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // App Icon
              Image.asset(
                'assets/images/icon.png',
                width: 160,
              ),

              const SizedBox(height: 60),

              // Log In Button
              SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login'); // Navigate to login page
                  },
                  child: const Text("تسجيل الدخول")
                ),
              ),

              const SizedBox(height: 20),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeight,
                child: OutlinedButton(
                  onPressed: () {
                     Navigator.pushNamed(context, '/signup'); // Navigate to sign up page
                  },
                  child: const Text("إنشاء حساب"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}