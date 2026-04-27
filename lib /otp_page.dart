import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'donor_home_page.dart';
import 'Beneficiary_home_page.dart';
import 'app_design.dart';

class OtpPage extends StatefulWidget {
  String correctCode;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final bool isLogin;

  OtpPage({
    required this.correctCode,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
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
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phone.startsWith('0')
          ? "+966${widget.phone.substring(1)}"
          : "+966${widget.phone}",
      verificationCompleted: (PhoneAuthCredential credential) async {},
      verificationFailed: (FirebaseAuthException e) {
        print(e.message);
      },
      codeSent: (String verificationId, int? resendToken) {
        widget.correctCode = verificationId;
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );

    startTimer();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("تم إرسال كود جديد")));
  }

  Future<void> verifyCode() async {
    try {
      if (codeController.text.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("رجاءً أدخل رمز التحقق")));
        return;
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.correctCode,
        smsCode: codeController.text.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

    final uid = FirebaseAuth.instance.currentUser!.uid;

var userDoc = await FirebaseFirestore.instance
    .collection('Users')
    .doc(uid)
    .get();

final role = (userDoc.data()?['role'] ?? '')
    .toString()
    .trim()
    .toLowerCase();

if (role == 'donor') {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => DonorHomePage(userId: uid),
    ),
    (route) => false,
  );
} else {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => BeneficiaryHomePage(userId: uid),
    ),
    (route) => false,
  );
}
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("الكود غير صحيح")));

      codeController.clear();
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
                  image: AssetImage('assets/images/madad_icon.jpeg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Padding(
              padding: AppPadding.screen,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 70, color: AppDesign.primary),

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
                    style: TextStyle(fontFamily: AppDesign.fontFamily),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppDesign.white,
                      prefixIcon: Icon(
                        Icons.lock,
                        color: AppDesign.textSecondary,
                      ),
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
          ],
        ),
      ),
    );
  }
}
