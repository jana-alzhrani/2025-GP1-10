import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:math';

import 'signup_page.dart';
import 'otp_page.dart';
import 'donor_home_page.dart';
import 'beneficiary_home_page.dart';
import 'app_design.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});


  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  Future<void> login() async {
    String emailText = email.text.trim().toLowerCase();

    if (emailText.isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("أدخل الإيميل وكلمة المرور")),
      );
      return;
    }

    if (!emailText.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الإيميل غير صحيح")),
      );
      return;
    }

    try {
      // 🔐 تسجيل دخول Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailText,
        password: password.text,
      );

      // 🔎 جلب بيانات المستخدم من Firestore
      final userQuery = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: emailText)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("المستخدم غير موجود في النظام")),
        );
        return;
      }

      final userData = userQuery.docs.first.data();
      final role = userData['role'] ?? '';

      // 🔑 إرسال OTP
      String otp = (100000 + Random().nextInt(900000)).toString();

      final callable =
          FirebaseFunctions.instance.httpsCallable('sendSignupOtp');

      await callable.call({
        "email": emailText,
        "otp": otp,
      });

      // 📩 فتح صفحة OTP
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpPage(
            correctCode: otp,
            firstName: '',
            lastName: '',
            email: emailText,
            phone: '',
            isLogin: true,
            password: password.text,
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الإيميل أو كلمة المرور غير صحيحة ❌")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.background,
      body: SingleChildScrollView(
        child: Column(
          children: [

            /// 🔹 صورة
            Stack(
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/madad_icon.jpeg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/');
                    },
                  ),
                ),
              ],
            ),

            SafeArea(
              child: Padding(
                padding: AppPadding.screen,
                child: Column(
                  children: [

                    AppGap.md,

                    Text(
                      "تسجيل الدخول",
                      style: AppDesign.h2Style.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    AppGap.lg,

                    /// email
                    _field("البريد الإلكتروني", email, Icons.email),

                    /// password
                    _field("كلمة المرور", password, Icons.lock,
                        isPassword: true),

                    AppGap.xl,

                    /// button
                    ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppDesign.primary,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(60),
                        ),
                      ),
                      child: Text(
                        "تسجيل الدخول",
                        style: AppDesign.buttonOnPrimaryStyle,
                      ),
                    ),

                    AppGap.md,

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>  SignUpPage()),
                        );
                      },
                      child: Text(
                        "ما عندك حساب؟ إنشاء حساب",
                        style: AppDesign.bodySecondaryStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, IconData icon,
      {bool isPassword = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDesign.spaceLG,
        vertical: AppDesign.spaceSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label,
              style: AppDesign.bodySecondaryStyle
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppDesign.white,
              prefixIcon: Icon(icon),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
