import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:math';
import 'signup_page.dart';
import 'otp_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();

  Future<void> sendLoginOTP() async {
    String emailText = email.text.trim().toLowerCase();

    //  تحقق من الحقل
    if (emailText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("أدخل البريد الإلكتروني")));
      return;
    }

    // تحقق من صحة الإيميل
    if (!emailText.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("الإيميل غير صحيح")));
      return;
    }

    // تحقق إذا الإيميل موجود
    var user = await FirebaseFirestore.instance
        .collection('Users')
        .where('email', isEqualTo: emailText)
        .get();

    if (user.docs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("هذا الإيميل غير مسجل")));
      return;
    }

    // توليد OTP
    String otp = (100000 + Random().nextInt(900000)).toString();

    //  (try/catch)
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'sendSignupOtp',
      );

      await callable.call({"email": emailText, "otp": otp});

      print("OTP SENT ✅");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpPage(
            correctCode: otp,
            firstName: '',
            lastName: '',
            email: emailText,
            phone: '',
            password: '',
            isLogin: true,
          ),
        ),
      );
    } catch (e) {
      print("ERROR: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("فشل إرسال الكود ❌")));
    }
  }

  @override
  Widget build(BuildContext context) {
    Color primary = Color(0xFF2F6F73);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              SizedBox(height: 100),

              Icon(Icons.login, size: 70, color: primary),

              SizedBox(height: 20),

              Text(
                "تسجيل الدخول",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 30),

              // 📧 الإيميل
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: "البريد الإلكتروني"),
              ),

              SizedBox(height: 30),

              //  زر تسجيل الدخول
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: sendLoginOTP,
                child: Text(
                  "تسجيل الدخول",
                  style: TextStyle(color: Colors.white),
                ),
              ),

              SizedBox(height: 20),

              //  زر إنشاء حساب
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SignUpPage()),
                  );
                },
                child: Text("ما عندك حساب؟ إنشاء حساب"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
