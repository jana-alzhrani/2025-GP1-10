import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:math';
import 'signup_page.dart';
import 'otp_page.dart';

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

    // تحقق من الحقول
    if (emailText.isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("أدخل الإيميل وكلمة المرور")));
      return;
    }

    //  تحقق من الإيميل
    if (!emailText.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("الإيميل غير صحيح")));
      return;
    }

    try {
      //  تحقق من الباسورد
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailText,
        password: password.text,
      );

      //  توليد OTP
      String otp = (100000 + Random().nextInt(900000)).toString();

      //  إرسال OTP
      final callable = FirebaseFunctions.instance.httpsCallable(
        'sendSignupOtp',
      );

      await callable.call({"email": emailText, "otp": otp});

      // الانتقال لصفحة OTP
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

              SizedBox(height: 20),

              //  كلمة المرور
              TextField(
                controller: password,
                obscureText: true,
                decoration: InputDecoration(labelText: "كلمة المرور"),
              ),

              SizedBox(height: 30),

              //  زر تسجيل الدخول
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: login,
                child: Text(
                  "تسجيل الدخول",
                  style: TextStyle(color: Colors.white),
                ),
              ),

              SizedBox(height: 20),

              //  إنشاء حساب
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
