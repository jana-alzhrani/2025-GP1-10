import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'otp_page.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final phone = TextEditingController();

  String? firstNameError;
  String? lastNameError;
  String? phoneError;

  Timer? _debouncePhone;

  Future<void> sendPhoneOTP(String phoneNumber) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber.startsWith('0')
          ? "+966${phoneNumber.substring(1)}"
          : "+966$phoneNumber",
      verificationCompleted: (_) {},
      verificationFailed: (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("فشل إرسال الكود")));
      },
      codeSent: (verificationId, _) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpPage(
              correctCode: verificationId,
              firstName: firstName.text,
              lastName: lastName.text,
              email: '',
              phone: phone.text,
              isLogin: false,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> signup() async {
    setState(() {
      firstNameError = null;
      lastNameError = null;
      phoneError = null;
    });

    bool hasError = false;

    // الاسم الأول
    if (firstName.text.isEmpty) {
      firstNameError = "الرجاء تعبئة الحقل";
      hasError = true;
    } else if (firstName.text.length < 2 || firstName.text.length > 50) {
      firstNameError = "يجب أن يكون بين 2 و 50 حرف";
      hasError = true;
    }

    // الاسم الأخير
    if (lastName.text.isEmpty) {
      lastNameError = "الرجاء تعبئة الحقل";
      hasError = true;
    } else if (lastName.text.length < 2 || lastName.text.length > 50) {
      lastNameError = "يجب أن يكون بين 2 و 50 حرف";
      hasError = true;
    }

    // رقم الجوال
    if (phone.text.isEmpty) {
      phoneError = "الرجاء تعبئة الحقل";
      hasError = true;
    } else if (phone.text.length != 10 || !phone.text.startsWith('05')) {
      phoneError = "رقم الجوال غير صحيح";
      hasError = true;
    }

    // التحقق من التكرار
    if (!hasError) {
      var phoneCheck = await FirebaseFirestore.instance
          .collection('Users')
          .where('phone', isEqualTo: phone.text.trim())
          .get();

      if (phoneCheck.docs.isNotEmpty) {
        phoneError = "رقم الجوال مستخدم مسبقاً";
        hasError = true;
      }
    }

    if (hasError) {
      setState(() {});
      return;
    }

    await sendPhoneOTP(phone.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F6),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // الهيدر
            Stack(
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
                Positioned(
                  top: 40,
                  left: 10,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),

            Text(
              "البيانات الشخصية",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            // الحقول
            buildField("الاسم الأول", firstName, Icons.person, firstNameError),
            buildField("اسم العائلة", lastName, Icons.person, lastNameError),
            buildField("رقم الجوال", phone, Icons.phone, phoneError),

            SizedBox(height: 20),

            // زر
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0F5C63),
                  minimumSize: Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text("إنشاء الحساب"),
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
    IconData icon,
    String? errorText,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label),
          SizedBox(height: 6),
          TextField(
            controller: controller,
            textAlign: TextAlign.right,
            onChanged: (value) {
              setState(() {
                if (controller == phone && value.isNotEmpty) phoneError = null;
              });

              if (controller == phone) {
                if (_debouncePhone?.isActive ?? false) _debouncePhone!.cancel();
                _debouncePhone = Timer(Duration(milliseconds: 500), () async {
                  var result = await FirebaseFirestore.instance
                      .collection('Users')
                      .where('phone', isEqualTo: value.trim())
                      .get();

                  if (result.docs.isNotEmpty) {
                    setState(() {
                      phoneError = "رقم الجوال مستخدم مسبقاً";
                    });
                  }
                });
              }
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(icon),
              errorText: errorText,
              errorStyle: TextStyle(color: Colors.red),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
