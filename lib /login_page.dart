import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:math';
import 'signup_page.dart';
import 'otp_page.dart';
import 'app_design.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  Future<void> login() async {
    String emailText = email.text.trim().toLowerCase();

    if (emailText.isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("أدخل الإيميل وكلمة المرور")));
      return;
    }

    if (!emailText.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("الإيميل غير صحيح")));
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailText,
        password: password.text,
      );

      String otp = (100000 + Random().nextInt(900000)).toString();

      final callable = FirebaseFunctions.instance.httpsCallable(
        'sendSignupOtp',
      );

      await callable.call({"email": emailText, "otp": otp});

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
        SnackBar(content: Text("الإيميل أو كلمة المرور غير صحيحة ❌")),
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
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/madad_identity.png'),
                  fit: BoxFit.cover,
                ),
              ),
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

                    buildField("البريد الإلكتروني", email, Icons.email),
                    buildField(
                      "كلمة المرور",
                      password,
                      Icons.lock,
                      isPassword: true,
                    ),

                    AppGap.xl,

                    Padding(
                      padding: AppPadding.horizontal,
                      child: ElevatedButton(
                        onPressed: login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppDesign.primary,
                          minimumSize: Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(60),
                          ),
                        ),
                        child: Text(
                          "تسجيل الدخول",
                          style: AppDesign.buttonOnPrimaryStyle.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    AppGap.md,

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SignUpPage()),
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

  Widget buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDesign.spaceLG,
        vertical: AppDesign.spaceSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: AppDesign.bodySecondaryStyle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),

          TextField(
            controller: controller,
            obscureText: isPassword,
            style: TextStyle(
              fontFamily: AppDesign.fontFamily,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppDesign.white,
              prefixIcon: Icon(icon, color: AppDesign.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
