import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_design.dart';

class AddCourierPage extends StatefulWidget {
  const AddCourierPage({super.key});

  @override
  State<AddCourierPage> createState() => _AddCourierPageState();
}

class _AddCourierPageState extends State<AddCourierPage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final cityController = TextEditingController();

  final String status = 'active';

  bool isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // رسائل الأخطاء
  String? firstNameError;
  String? lastNameError;
  String? phoneError;
  String? cityError;

  // لمنع استخدام نتيجة فحص رقم قديم
  int phoneCheckRequestId = 0;

  // =========================
  // التحقق الفوري من رقم الجوال
  // =========================
  Future<void> checkPhoneExists(String value) async {
    final phone = value.trim();
    final requestId = ++phoneCheckRequestId;

    // إذا كان الحقل فارغًا أو الرقم غير مكتمل
    if (phone.isEmpty || phone.length < 10) {
      if (!mounted) return;

      setState(() {
        phoneError = null;
      });
      return;
    }

    // التحقق من صيغة رقم الجوال السعودي
    if (!RegExp(r'^05[0-9]{8}$').hasMatch(phone)) {
      if (!mounted) return;

      setState(() {
        phoneError = 'رقم الجوال غير صحيح';
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      phoneError = null;
    });

    try {
      final normalizedPhone = '+966${phone.substring(1)}';

      // البحث عن الرقم بالصيغة المحلية
      final phoneCheck = await _firestore
          .collection('Users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      // البحث عن الرقم بالصيغة الدولية
      final normalizedPhoneCheck = await _firestore
          .collection('Users')
          .where('phoneNumber', isEqualTo: normalizedPhone)
          .limit(1)
          .get();

      // تجاهل نتيجة الفحص إذا تغيّر الرقم أثناء البحث
      if (!mounted || requestId != phoneCheckRequestId) return;

      setState(() {
        if (phoneCheck.docs.isNotEmpty ||
            normalizedPhoneCheck.docs.isNotEmpty) {
          phoneError = 'رقم الجوال مسجل مسبقًا';
        } else {
          phoneError = null;
        }
      });
    } catch (e) {
      debugPrint('Phone duplicate check error: $e');

      // لا نمسح أي رسالة خطأ موجودة بسبب فشل الاتصال
    }
  }

  // =========================
  // Add Courier
  // =========================
  Future<void> addCourier() async {
    FocusScope.of(context).unfocus();

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final phone = phoneController.text.trim();
    final city = cityController.text.trim();

    bool hasError = false;

    setState(() {
      firstNameError = null;
      lastNameError = null;
      phoneError = null;
      cityError = null;

      // الاسم الأول
      if (firstName.isEmpty) {
        firstNameError = 'الرجاء تعبئة الحقل';
        hasError = true;
      } else if (firstName.length < 2 || firstName.length > 50) {
        firstNameError = 'يجب أن يكون الاسم بين 2 و50 حرفًا';
        hasError = true;
      }

      // اسم العائلة
      if (lastName.isEmpty) {
        lastNameError = 'الرجاء تعبئة الحقل';
        hasError = true;
      } else if (lastName.length < 2 || lastName.length > 50) {
        lastNameError = 'يجب أن يكون الاسم بين 2 و50 حرفًا';
        hasError = true;
      }

      // رقم الجوال
      if (phone.isEmpty) {
        phoneError = 'الرجاء تعبئة الحقل';
        hasError = true;
      } else if (!RegExp(r'^05[0-9]{8}$').hasMatch(phone)) {
        phoneError = 'رقم الجوال غير صحيح';
        hasError = true;
      }

      // المدينة
      if (city.isEmpty) {
        cityError = 'الرجاء تعبئة الحقل';
        hasError = true;
      }
    });

    if (hasError) return;

    setState(() {
      isLoading = true;
    });

    try {
      final normalizedPhone = '+966${phone.substring(1)}';

      // إعادة فحص الرقم قبل الحفظ للتأكد من عدم تكراره
      final phoneCheck = await _firestore
          .collection('Users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      final normalizedPhoneCheck = await _firestore
          .collection('Users')
          .where('phoneNumber', isEqualTo: normalizedPhone)
          .limit(1)
          .get();

      if (phoneCheck.docs.isNotEmpty || normalizedPhoneCheck.docs.isNotEmpty) {
        if (!mounted) return;

        setState(() {
          phoneError = 'رقم الجوال مسجل مسبقًا';
        });

        return;
      }

      // =========================
      // Create IDs
      // =========================
      final userRef = _firestore.collection('Users').doc();
      final courierRef = _firestore.collection('couriers').doc();

      final userId = userRef.id;

      // =========================
      // Batch
      // =========================
      final batch = _firestore.batch();

      // =========================
      // Users Document
      // =========================
      batch.set(userRef, {
        'userId': userId,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'phoneNumber': normalizedPhone,
        'role': 'courier',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // =========================
      // Courier Document
      // =========================
      batch.set(courierRef, {
        'userID': userId,
        'statues': status,
        'city': city,
        'completedDeliveries': 0,
      });

      // =========================
      // Save Both Documents
      // =========================
      await batch.commit();

      if (!mounted) return;

      AppDesign.showSuccessSnackBar(context, 'تم إضافة السائق بنجاح');

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Add Courier Error: $e');

      if (!mounted) return;

      AppDesign.showErrorSnackBar(context, 'حدث خطأ أثناء إضافة السائق');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =========================
  // Dispose
  // =========================
  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    cityController.dispose();

    super.dispose();
  }

  // =========================
  // Build
  // =========================
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppDesign.background,
        appBar: AppBar(title: const Text('إضافة سائق'), centerTitle: true),
        body: SingleChildScrollView(
          padding: AppPadding.screen,
          child: Column(
            children: [
              // الاسم الأول
              _buildField(
                controller: firstNameController,
                label: 'الاسم الأول',
                icon: Icons.person_outline,
                errorText: firstNameError,
                onChanged: (value) {
                  setState(() {
                    if (value.trim().isEmpty) {
                      firstNameError = 'الرجاء تعبئة الحقل';
                    } else if (value.trim().length < 2 ||
                        value.trim().length > 50) {
                      firstNameError = 'يجب أن يكون الاسم بين 2 و50 حرفًا';
                    } else {
                      firstNameError = null;
                    }
                  });
                },
              ),

              AppGap.md,

              // اسم العائلة
              _buildField(
                controller: lastNameController,
                label: 'اسم العائلة',
                icon: Icons.person_outline,
                errorText: lastNameError,
                onChanged: (value) {
                  setState(() {
                    if (value.trim().isEmpty) {
                      lastNameError = 'الرجاء تعبئة الحقل';
                    } else if (value.trim().length < 2 ||
                        value.trim().length > 50) {
                      lastNameError = 'يجب أن يكون الاسم بين 2 و50 حرفًا';
                    } else {
                      lastNameError = null;
                    }
                  });
                },
              ),

              AppGap.md,

              // رقم الجوال
              _buildField(
                controller: phoneController,
                label: 'رقم الجوال',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
                errorText: phoneError,
                onChanged: (value) {
                  checkPhoneExists(value);
                },
              ),

              AppGap.md,

              // المدينة
              _buildField(
                controller: cityController,
                label: 'المدينة',
                icon: Icons.location_on_outlined,
                errorText: cityError,
                onChanged: (value) {
                  setState(() {
                    cityError = value.trim().isEmpty
                        ? 'الرجاء تعبئة الحقل'
                        : null;
                  });
                },
              ),

              AppGap.lg,

              // زر إضافة السائق
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : addCourier,
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text('إضافة السائق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // Text Field
  // =========================
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? errorText,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        errorText: errorText,
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
        counterText: '',
      ),
    );
  }
}
