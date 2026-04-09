import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'otp_page.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();

  // إرسال OTP
  Future<void> sendEmailOTP(String emailText) async {
    try {
      // توليد الكود هنا
      String otp = (100000 + Random().nextInt(900000)).toString();

      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendSignupOtp');

      await callable.call({"email": emailText, "otp": otp});

      // الانتقال لصفحة OTP
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpPage(
            correctCode: otp,
            firstName: firstName.text,
            lastName: lastName.text,
            email: emailText,
            phone: phone.text.trim(),
            isLogin: false,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("فشل إرسال الكود ❌")));
      print(e);
    }
  }

  Future<void> signup() async {
    String phoneText = phone.text.trim();
    String emailText = email.text.trim();

    if (firstName.text.isEmpty ||
        lastName.text.isEmpty ||
        emailText.isEmpty ||
        phoneText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("الرجاء تعبئة جميع الحقول")));
      return;
    }

    if (!emailText.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("الإيميل غير صحيح")));
      return;
    }

    if (phoneText.length != 10 || !phoneText.startsWith('05')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("رقم الجوال غير صحيح")));
      return;
    }

    var existingEmail = await FirebaseFirestore.instance
        .collection('Users')
        .where('email', isEqualTo: emailText)
        .get();

    if (existingEmail.docs.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("الإيميل مسجل مسبقاً")));
      return;
    }

    var existingUser = await FirebaseFirestore.instance
        .collection('Users')
        .where('phone', isEqualTo: phoneText)
        .get();

    if (existingUser.docs.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("رقم الجوال مسجل مسبقاً")));
      return;
    }

    await sendEmailOTP(emailText);
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
              SizedBox(height: 80),

              Icon(Icons.person_add, size: 70, color: primary),

              SizedBox(height: 15),

              Text(
                "إنشاء حساب جديد",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 30),

              TextField(
                controller: firstName,
                decoration: InputDecoration(labelText: "الاسم الأول"),
              ),

              SizedBox(height: 20),

              TextField(
                controller: lastName,
                decoration: InputDecoration(labelText: "اسم العائلة"),
              ),

              SizedBox(height: 20),

              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: "البريد الإلكتروني"),
              ),

              SizedBox(height: 20),

              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: "رقم الجوال"),
              ),

              SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: signup,
                child: Text(
                  "إنشاء الحساب",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
