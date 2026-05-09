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

  int? resendToken;

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

      forceResendingToken: resendToken,

      verificationCompleted: (PhoneAuthCredential credential) async {},

      verificationFailed: (FirebaseAuthException e) {
        print(e.message);
       AppDesign.showErrorSnackBar(
  context,
  e.message ?? "فشل إرسال الكود",
);
      },

      codeSent: (String verificationId, int? token) {
        widget.correctCode = verificationId;
        resendToken = token;
      },

      codeAutoRetrievalTimeout: (String verificationId) {},
    );

    startTimer();

    AppDesign.showSuccessSnackBar(
      context,
      "تم إرسال كود جديد",
    );
  
  }

  Future<void> verifyCode() async {
    try {
      if (codeController.text.trim().isEmpty) {
        AppDesign.showErrorSnackBar(
        context,
        "أدخل رمز التحقق",
      );

        return;
      }
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.correctCode,
        smsCode: codeController.text.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      final uid = FirebaseAuth.instance.currentUser!.uid;

      var userRef = FirebaseFirestore.instance.collection('Users').doc(uid);

      var userDoc = await userRef.get();

      if (!userDoc.exists) {
        await userRef.set({
          'userId': uid,
          'firstName': widget.firstName,
          'lastName': widget.lastName,
          'email': widget.email,
          'phone': widget.phone,
          'role': 'donor',
          'createdAt': FieldValue.serverTimestamp(),
        });

        AppDesign.showSuccessSnackBar(
          context,
          "أهلاً وسهلاً بك",
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => DonorHomePage(userId: uid)),
          (route) => false,
        );
      } else {
        final role = (userDoc.data()?['role'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        if (role == 'donor') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => DonorHomePage(userId: uid)),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => BeneficiaryHomePage(userId: uid)),
            (route) => false,
          );
        }
      }
    } catch (e) {
      AppDesign.showErrorSnackBar(
        context,
        "الكود غير صحيح",
      );
        
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
            Stack(
              children: [
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/madad_icon.jpeg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                Positioned(
                  top: 40,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      codeController.clear();

                      FocusScope.of(context).unfocus();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),

            Padding(
              padding: AppPadding.screen,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                    style: TextStyle(fontFamily: AppDesign.fontFamily),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppDesign.white,
                      suffixIcon: const Icon(
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
                      minimumSize: const Size(double.infinity, 56),
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