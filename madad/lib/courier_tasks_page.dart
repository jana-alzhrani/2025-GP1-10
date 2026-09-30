import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_design.dart';

class CourierTasksPage extends StatefulWidget {
  final String userId;

  const CourierTasksPage({super.key, required this.userId});

  @override
  State createState() => _CourierTasksPageState();
}

class _CourierTasksPageState extends State<CourierTasksPage> {
  int _selectedTab = 0;

  Future _acceptTask(String donationId, Map donationData) async {
    final confirm = await AppDesign.showAppDialog(
      context: context,
      title: 'قبول الطلب',
      message: 'هل أنت متأكد من رغبتك في قبول هذا الطلب؟',
      confirmText: 'قبول الطلب',
    );

    if (confirm != true) return;

    try {
      final currentStatus = donationData['status'] ?? 'published';
      final city = donationData['city'] ?? 'الرياض';
      final district = donationData['district'] ?? 'الحي';
      final deliveryLocation = '${city} - ${district}';

      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .update({
            'originalStatus': currentStatus,
            'courierID': widget.userId,
            'acceptedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      AppDesign.showSuccessSnackBar(
        context,
        'تم قبول الطلب بنجاح وإضافته لمهامك النشطة',
      );
    } catch (e) {
      if (!mounted) return;
      AppDesign.showErrorSnackBar(context, 'حدث خطأ أثناء قبول الطلب: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppDesign.background,
        appBar: AppBar(
          title: const Text('إدارة مهام التوصيل'),
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDesign.screenPadding),
              child: Container(
                height: 52,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppDesign.white,
                  borderRadius: BorderRadius.circular(AppDesign.radiusLG),
                  border: Border.all(color: AppDesign.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        title: 'الطلبات المتاحة',
                        index: 0,
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        title: 'الطلبات المكتملة',
                        index: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: _selectedTab == 0
                    ? FirebaseFirestore.instance
                          .collection('donations')
                          .where('status', whereIn: ['published', 'reserved'])
                          .snapshots()
                    : FirebaseFirestore.instance
                          .collection('donations')
                          .where('courierID', isEqualTo: widget.userId)
                          .where('status', whereIn: ['delivered', 'available'])
                          .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text('حدث خطأ في تحميل المهام'));
                  }

                  final allDocs = snapshot.data?.docs ?? [];

                  final docs = allDocs.where((doc) {
                    final data = doc.data() as Map;
                    final status = data['status'] ?? '';
                    final deliveryMethod = data['deliveryMethod'] ?? '';

                    if (_selectedTab == 0) {
                      return (status == 'published' || status == 'reserved') &&
                          deliveryMethod != 'self_delivery';
                    } else {
                      return (status == 'delivered' || status == 'available');
                    }
                  }).toList();

                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        _selectedTab == 0
                            ? 'لا توجد طلبات متاحة حالياً'
                            : 'لا توجد طلبات مكتملة',
                        style: AppDesign.bodySecondaryStyle,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDesign.screenPadding,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map;
                      final status = data['status'] ?? 'published';

                      final rawCity = (data['city'] ?? '').toString().trim();
                      final rawDistrict = (data['district'] ?? '')
                          .toString()
                          .trim();
                      final city = rawCity.isNotEmpty ? rawCity : 'لا يوجد';
                      final district = rawDistrict.isNotEmpty
                          ? rawDistrict
                          : 'لا يوجد';

                      final totalBoxes =
                          ((data['numberOfItems'] ?? 0) is num
                                  ? (data['numberOfItems'] as num) / 5
                                  : 1)
                              .ceil();
                      final boxCount =
                          ((data['boxCodes'] is List)
                                  ? (data['boxCodes'] as List).length
                                  : totalBoxes)
                              .clamp(0, 999999);
                      final donorId = data['donorID'] ?? '';

                      final String pickupLocation = status == 'reserved'
                          ? 'المستودع'
                          : '${city} - ${district}';
                      final String deliveryLocation = status == 'reserved'
                          ? '${city} - ${district}'
                          : 'المستودع';

                      return FutureBuilder(
                        future: donorId.isNotEmpty
                            ? FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(donorId)
                                  .get()
                            : Future.value(null),
                        builder: (context, userSnapshot) {
                          String donorName = 'صاحب الطلب';
                          String donorPhone = 'غير متوفر';

                          if (userSnapshot.hasData &&
                              userSnapshot.data != null &&
                              userSnapshot.data!.exists) {
                            final userData =
                                userSnapshot.data!.data() as Map? ?? {};
                            donorName =
                                '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                                    .trim();
                            donorPhone =
                                (userData['phone'] ??
                                        userData['phoneNumber'] ??
                                        '')
                                    .toString();
                          }

                          return Container(
                            margin: const EdgeInsets.only(
                              bottom: AppDesign.spaceMD,
                            ),
                            padding: const EdgeInsets.all(
                              AppDesign.cardPadding,
                            ),
                            decoration: AppDesign.primaryCardDecoration,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'طلب #${doc.id.substring(0, 5).toUpperCase()}',
                                      style: AppDesign.subtitleStyle.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (status == 'completed' ||
                                                status == 'available')
                                            ? AppDesign.success.withOpacity(0.2)
                                            : AppDesign.warning.withOpacity(
                                                0.3,
                                              ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status == 'published'
                                            ? 'متاح (تبرع جديد)'
                                            : status == 'reserved'
                                            ? 'متاح (محجوز لمستفيد)'
                                            : 'مكتمل',
                                        style: AppDesign.captionStyle.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 18,
                                      color: AppDesign.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'موقع الاستلام: $pickupLocation',
                                        style: AppDesign.bodySecondaryStyle,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.local_shipping_outlined,
                                      size: 18,
                                      color: AppDesign.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'موقع التسليم: $deliveryLocation',
                                        style: AppDesign.bodySecondaryStyle,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 18,
                                      color: AppDesign.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'عدد الصناديق: $boxCount',
                                        style: AppDesign.bodySecondaryStyle,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person_outline,
                                      size: 18,
                                      color: AppDesign.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'صاحب الطلب: $donorName',
                                        style: AppDesign.bodySecondaryStyle,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_outlined,
                                      size: 18,
                                      color: AppDesign.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'رقم الجوال: ${donorPhone.isNotEmpty ? donorPhone : 'غير متوفر'}',
                                        style: AppDesign.bodySecondaryStyle,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (_selectedTab == 0)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _acceptTask(doc.id, data),
                                      child: const Text('قبول الطلب'),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({required String title, required int index}) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppDesign.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDesign.radiusMD),
        ),
        child: Text(
          title,
          style: AppDesign.bodyStyle.copyWith(
            color: isSelected ? AppDesign.white : AppDesign.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
