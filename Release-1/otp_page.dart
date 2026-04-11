import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'donor_home_page.dart';
import 'app_design.dart';

class OtpPage extends StatefulWidget {
  String correctCode;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final bool isLogin;
  final String password;

  OtpPage({
    required this.correctCode,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.isLogin,
    required this.password,
  });

  @override
  _OtpPageState createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final codeController = TextEditingController();

  int seconds = 30;
  bool canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    canResend = false;
    seconds = 30;

    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 1));
      if (seconds > 0) {
        setState(() {
          seconds--;
        });
        return true;
      } else {
        setState(() {
          canResend = true;
        });
        return false;
      }
    });
  }

  Future<void> resendCode() async {
    String newOtp = (100000 + Random().nextInt(900000)).toString();

    final callable = FirebaseFunctions.instance.httpsCallable('sendSignupOtp');

    await callable.call({"email": widget.email, "otp": newOtp});

    widget.correctCode = newOtp;

    startTimer();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("تم إرسال كود جديد")));
  }

  Future<void> verifyCode() async {
    try {
      //  تحقق إذا الحقل فاضي
      if (codeController.text.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("رجاءً أدخل رمز التحقق")));
        return;
      }

      if (codeController.text.trim() == widget.correctCode) {
        //  تسجيل دخول
        if (widget.isLogin) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("أهلاً وسهلاً بك 👋"),
              backgroundColor: AppDesign.primary,
            ),
          );
        }
        //  إنشاء حساب
        else {
          final userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                email: widget.email,
                password: widget.password,
              );

          var userRef = FirebaseFirestore.instance
              .collection('Users')
              .doc(userCredential.user!.uid);

          await userRef.set({
            'userId': userCredential.user!.uid,
            'firstName': widget.firstName,
            'lastName': widget.lastName,
            'email': widget.email.trim().toLowerCase(),
            'phone': widget.phone,
            'role': 'donor',
            'createdAt': FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("أهلاً وسهلاً بك 👋"),
              backgroundColor: AppDesign.primary,
            ),
          );
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => DonorHomePage(userEmail: widget.email),
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("الكود غير صحيح")));

        codeController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(" خطأ ❌")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.background,
      body: Padding(
        padding: AppPadding.screen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 70, color: AppDesign.primary),

            AppGap.md,

            Text(
              "أدخل رمز التحقق",
              style: AppDesign.h2Style.copyWith(fontWeight: FontWeight.w600),
            ),

            AppGap.md,

            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              style: TextStyle(fontFamily: AppDesign.fontFamily),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppDesign.white,
                prefixIcon: Icon(Icons.lock, color: AppDesign.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            AppGap.lg,

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesign.primary,
                minimumSize: Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(60),
                ),
              ),
              onPressed: verifyCode,
              child: Text(
                "تأكيد",
                style: AppDesign.buttonOnPrimaryStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            AppGap.md,

            TextButton(
              onPressed: canResend ? resendCode : null,
              child: Text(
                canResend
                    ? "إعادة إرسال الكود"
                    : "إعادة الإرسال خلال $seconds ثانية",
                style: AppDesign.bodySecondaryStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}