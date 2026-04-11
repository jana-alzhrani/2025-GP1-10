import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'otp_page.dart';
import 'app_design.dart';

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

  // 🔥 نفس التحقق بالكامل (ما لمسته)
  Future<void> signup() async {
    String phoneText = phone.text.trim();
    String emailText = email.text.trim();

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

    if (password.text != confirmPassword.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("كلمتا المرور غير متطابقة")));
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
    return Scaffold(
      backgroundColor: AppDesign.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            //  الهيدر
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
                      "البيانات الشخصية",
                      style: AppDesign.h2Style.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    AppGap.lg,

                    buildField("الاسم الأول", firstName, Icons.person),
                    buildField("الاسم الأخير", lastName, Icons.person),
                    buildField("رقم الجوال", phone, Icons.phone),
                    buildField("البريد الإلكتروني", email, Icons.email),
                    buildField(
                      "كلمة المرور",
                      password,
                      Icons.lock,
                      isPassword: true,
                    ),
                    buildField(
                      "تأكيد كلمة المرور",
                      confirmPassword,
                      Icons.lock,
                      isPassword: true,
                    ),

                    AppGap.xl,

                    Padding(
                      padding: AppPadding.horizontal,
                      child: ElevatedButton(
                        onPressed: signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppDesign.primary,
                          minimumSize: Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(60),
                          ),
                        ),
                        child: Text(
                          "إنشاء الحساب",
                          style: AppDesign.buttonOnPrimaryStyle.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    AppGap.xl,
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
