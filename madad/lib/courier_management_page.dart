import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'app_design.dart';
import 'add_courier_page.dart';
import 'edit_courier_page.dart';

class CourierManagementPage extends StatefulWidget {
  const CourierManagementPage({super.key});

  @override
  State<CourierManagementPage> createState() => _CourierManagementPageState();
}

class _CourierManagementPageState extends State<CourierManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =========================
  // Delete Courier
  // =========================

  Future<void> deleteCourier(String courierId) async {
    try {
      // جلب بيانات السائق لمعرفة userID
      final courierDoc = await _firestore
          .collection('couriers')
          .doc(courierId)
          .get();

      if (!courierDoc.exists) {
        if (!mounted) return;

        AppDesign.showErrorSnackBar(context, 'بيانات السائق غير موجودة');

        return;
      }

      final courierData = courierDoc.data() as Map<String, dynamic>;

      final userId = courierData['userID']?.toString() ?? '';

      // إنشاء Batch للحذف
      final batch = _firestore.batch();

      // حذف بيانات السائق من couriers
      final courierRef = _firestore.collection('couriers').doc(courierId);

      batch.delete(courierRef);

      // حذف بيانات المستخدم من Users
      if (userId.isNotEmpty) {
        final userRef = _firestore.collection('Users').doc(userId);

        batch.delete(userRef);
      }

      // تنفيذ الحذف
      await batch.commit();

      if (!mounted) return;

      AppDesign.showSuccessSnackBar(context, 'تم حذف السائق بنجاح');
    } catch (e) {
      debugPrint('Delete Courier Error: $e');

      if (!mounted) return;

      AppDesign.showErrorSnackBar(context, 'حدث خطأ أثناء حذف السائق');
    }
  }

  // =========================
  // Delete Confirmation
  // =========================

  Future<void> showDeleteDialog(String courierId, String courierName) async {
    final confirmed = await AppDesign.showAppDialog(
      context: context,
      title: 'حذف السائق',
      message: 'هل أنت متأكد من حذف هذا المندوب؟',
      confirmText: 'حذف',
      cancelText: 'إلغاء',
    );

    if (confirmed) {
      await deleteCourier(courierId);
    }
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

        appBar: AppBar(title: const Text('إدارة السائقين'), centerTitle: true),

        // =========================
        // Add Courier
        // =========================
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppDesign.primary,

          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddCourierPage()),
            );

            // إعادة تحميل القائمة بعد إضافة سائق
            if (mounted) {
              setState(() {});
            }
          },

          child: const Icon(Icons.add, color: Colors.white),
        ),

        // =========================
        // Courier List
        // =========================
        body: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('couriers').snapshots(),

          builder: (context, snapshot) {
            // Loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Error
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'حدث خطأ أثناء تحميل السائقين',
                  style: AppDesign.bodyStyle,
                ),
              );
            }

            final courierDocs = snapshot.data?.docs ?? [];

            // Empty
            if (courierDocs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 70,
                      color: AppDesign.textSecondary,
                    ),

                    AppGap.md,

                    Text('لا يوجد سائقون حاليًا', style: AppDesign.h2Style),

                    AppGap.sm,

                    Text(
                      'اضغط + لإضافة سائق جديد',
                      style: AppDesign.bodySecondaryStyle,
                    ),
                  ],
                ),
              );
            }

            // =========================
            // Courier List
            // =========================

            return ListView.builder(
              padding: AppPadding.screen,
              itemCount: courierDocs.length,

              itemBuilder: (context, index) {
                final courierDoc = courierDocs[index];

                final courierData = courierDoc.data() as Map<String, dynamic>;

                // userID الموجود في couriers
                final userId = courierData['userID']?.toString() ?? '';

                // statues الموجود في Firebase
                final status =
                    courierData['statues']?.toString().trim().isNotEmpty == true
                    ? courierData['statues'].toString()
                    : 'غير محدد';

                // إذا userID غير موجود
                if (userId.isEmpty) {
                  return _buildInvalidCourierCard(courierDoc.id, status);
                }

                // =========================
                // Get User Data
                // =========================

                return FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('Users').doc(userId).get(),

                  builder: (context, userSnapshot) {
                    // Loading user data
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }

                    String firstName = '';
                    String lastName = '';
                    String phone = '';

                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      final userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;

                      firstName = userData['firstName']?.toString() ?? '';

                      lastName = userData['lastName']?.toString() ?? '';

                      phone = userData['phone']?.toString() ?? '';
                    }

                    final courierName = '$firstName $lastName'.trim();

                    return _buildCourierCard(
                      courierId: courierDoc.id,
                      userId: userId,
                      courierName: courierName.isEmpty
                          ? 'اسم غير متوفر'
                          : courierName,
                      phone: phone,
                      status: status,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  // =========================
  // Courier Card
  // =========================

  Widget _buildCourierCard({
    required String courierId,
    required String userId,
    required String courierName,
    required String phone,
    required String status,
  }) {
    final isActive = status.toLowerCase() == 'active' || status == 'نشط';

    final displayedStatus = status.toLowerCase() == 'active'
        ? 'نشط'
        : status.toLowerCase() == 'inactive'
        ? 'غير نشط'
        : status;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            // =========================
            // Name + Status
            // =========================
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppDesign.primary,

                  child: const Icon(Icons.person, color: Colors.white),
                ),

                AppGap.sm,

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(courierName, style: AppDesign.h2Style),

                      const SizedBox(height: 4),

                      Text(
                        phone.isEmpty ? 'رقم الجوال غير متوفر' : phone,
                        style: AppDesign.bodySecondaryStyle,
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),

                  decoration: BoxDecoration(
                    color: isActive ? AppDesign.softGreen : AppDesign.secondary,

                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Text(
                    displayedStatus,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),

            AppGap.md,

            const Divider(),

            AppGap.sm,

            // =========================
            // Completed Deliveries
            // =========================
            FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('couriers').doc(courierId).get(),

              builder: (context, snapshot) {
                int completedDeliveries = 0;

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;

                  completedDeliveries =
                      data['completedDeliveries'] as int? ?? 0;
                }

                return Row(
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      color: AppDesign.primary,
                    ),

                    AppGap.sm,

                    Text(
                      'الرحلات المكتملة: ',
                      style: AppDesign.bodySecondaryStyle,
                    ),

                    Text('$completedDeliveries', style: AppDesign.bodyStyle),
                  ],
                );
              },
            ),

            AppGap.md,

            // =========================
            // Buttons
            // =========================
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditCourierPage(
                            courierId: courierId,
                            userId: userId,
                          ),
                        ),
                      );

                      // إعادة تحميل البيانات بعد التعديل
                      if (mounted) {
                        setState(() {});
                      }
                    },

                    icon: const Icon(Icons.edit_outlined),

                    label: const Text('تعديل'),
                  ),
                ),

                AppGap.sm,

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDeleteDialog(courierId, courierName);
                    },

                    icon: const Icon(Icons.delete_outline),

                    label: const Text('حذف'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Invalid Courier Card
  // =========================

  Widget _buildInvalidCourierCard(String courierId, String status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 45,
              color: Colors.orange,
            ),

            AppGap.sm,

            Text('بيانات السائق غير مكتملة', style: AppDesign.h2Style),

            AppGap.sm,

            Text(
              'لم يتم ربط هذا السائق بحساب مستخدم.',
              textAlign: TextAlign.center,
              style: AppDesign.bodySecondaryStyle,
            ),

            AppGap.sm,

            Text('الحالة: $status', style: AppDesign.bodyStyle),

            AppGap.md,

            ElevatedButton.icon(
              onPressed: () {
                showDeleteDialog(courierId, 'هذا السائق');
              },

              icon: const Icon(Icons.delete_outline),

              label: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }
}
