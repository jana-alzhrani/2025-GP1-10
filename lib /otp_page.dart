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
      await Future.delayed(const Duration(seconds: 1));
      if (seconds > 0) {
        setState(() => seconds--);
        return true;
      } else {
        setState(() => canResend = true);
        return false;
      }
    });
  }

  Future<void> resendCode() async {
    String newOtp = (100000 + Random().nextInt(900000)).toString();

    final callable =
        FirebaseFunctions.instance.httpsCallable('sendSignupOtp');

    await callable.call({"email": widget.email, "otp": newOtp});

    widget.correctCode = newOtp;

    startTimer();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("تم إرسال كود جديد")));
  }

  /// 🔥 دالة التوجيه حسب الدور
  Future<void> navigateBasedOnRole() async {
    try {
      final normalizedEmail = widget.email.trim().toLowerCase();

      final userQuery = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("المستخدم غير موجود")),
        );
        return;
      }

      final userData = userQuery.docs.first.data();
      final role =
          userData['role']?.toString().trim().toLowerCase() ?? '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("أهلاً وسهلاً بك 👋"),
          backgroundColor: AppDesign.primary,
        ),
      );

      /// 🔥 التوجيه
      if (role == 'donor') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => DonorHomePage(userEmail: widget.email),
          ),
          (route) => false,
        );
      } else if (role == 'beneficiary') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/beneficiaryHome',
          (route) => false,
          arguments: widget.email,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("نوع المستخدم غير معروف")),
        );
      }
    } catch (e) {
      debugPrint("Role Error: $e");
    }
  }

  Future<void> verifyCode() async {
    try {
      if (codeController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("رجاءً أدخل رمز التحقق")),
        );
        return;
      }

      if (codeController.text.trim() == widget.correctCode) {

        /// 🔹 تسجيل جديد
        if (!widget.isLogin) {
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
        }

        /// 🔥 أهم خطوة: التوجيه حسب الدور
        await navigateBasedOnRole();

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("الكود غير صحيح")),
        );

        codeController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("خطأ ❌")),
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
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/madad_icon.jpeg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Padding(
              padding: AppPadding.screen,
              child: Column(
                children: [
                  const Icon(Icons.lock, size: 70, color: AppDesign.primary),

                  AppGap.md,

                  Text(
                    "أدخل رمز التحقق",
                    style: AppDesign.h2Style.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  AppGap.md,

                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppDesign.white,
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  AppGap.lg,

                  ElevatedButton(
                    onPressed: verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppDesign.primary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(60),
                      ),
                    ),
                    child: Text(
                      "تأكيد",
                      style: AppDesign.buttonOnPrimaryStyle,
                    ),
                  ),

                  AppGap.md,

                  TextButton(
                    onPressed: canResend ? resendCode : null,
                    child: Text(
                      canResend
                          ? "إعادة إرسال الكود"
                          : "إعادة الإرسال خلال $seconds ثانية",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
