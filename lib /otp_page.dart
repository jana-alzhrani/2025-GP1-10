import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:math';
import 'login_page.dart';

class OtpPage extends StatefulWidget {
  String correctCode;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String password;
  final bool isLogin;

  OtpPage({
    required this.correctCode,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.isLogin,
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
    if (codeController.text.trim() == widget.correctCode) {
      if (widget.isLogin) {
        // تسجيل دخول
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("تم تسجيل الدخول بنجاح 🎉")));
      } else {
        // إنشاء حساب
        await FirebaseFirestore.instance.collection('Users').add({
          'firstName': widget.firstName,
          'lastName': widget.lastName,
          'email': widget.email,
          'phone': widget.phone,
          'password': widget.password,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("تم إنشاء الحساب بنجاح 🎉")));
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("الكود غير صحيح")));

      codeController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color primary = Color(0xFF2F6F73);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 70, color: primary),

            SizedBox(height: 20),

            Text(
              "أدخل رمز التحقق",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20),

            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "رمز التحقق",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 25),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: verifyCode,
              child: Text("تأكيد", style: TextStyle(color: Colors.white)),
            ),

            SizedBox(height: 15),

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
    );
  }
}
