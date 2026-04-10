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
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  // إرسال OTP
  Future<void> sendEmailOTP(String emailText) async {
    try {
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
            firstName: firstName.text,
            lastName: lastName.text,
            email: emailText,
            phone: phone.text.trim(),
            isLogin: false,
            password: password.text,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("فشل إرسال الكود ❌")));
    }
  }

  Future<void> signup() async {
    String phoneText = phone.text.trim();
    String emailText = email.text.trim();

    //  تحقق الحقول
    if (firstName.text.isEmpty ||
        lastName.text.isEmpty ||
        emailText.isEmpty ||
        phoneText.isEmpty ||
        password.text.isEmpty ||
        confirmPassword.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("الرجاء تعبئة جميع الحقول")));
      return;
    }

    if (password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("كلمة المرور لازم تكون 6 خانات على الأقل")),
      );
      return;
    }

    //  تحقق الإيميل
    if (!emailText.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("الإيميل غير صحيح")));
      return;
    }

    //  تحقق رقم الجوال
    if (phoneText.length != 10 || !phoneText.startsWith('05')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("رقم الجوال غير صحيح")));
      return;
    }

    //تحقق الباسورد
    if (password.text != confirmPassword.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("كلمتا المرور غير متطابقة")));
      return;
    }

    // تحقق تكرار الإيميل
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

    //  تحقق تكرار الجوال
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

              TextField(
                controller: password,
                obscureText: true,
                decoration: InputDecoration(labelText: "كلمة المرور"),
              ),

              SizedBox(height: 20),

              TextField(
                controller: confirmPassword,
                obscureText: true,
                decoration: InputDecoration(labelText: "تأكيد كلمة المرور"),
              ),

              SizedBox(height: 30),

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
