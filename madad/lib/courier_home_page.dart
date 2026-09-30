import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_design.dart';
import 'courier_tasks_page.dart';
import 'courier_more_page.dart';

class CourierHomePage extends StatefulWidget {
  final String userId;

  const CourierHomePage({super.key, required this.userId});

  @override
  State<CourierHomePage> createState() => _CourierHomePageState();
}

class _CourierHomePageState extends State<CourierHomePage> {
  int _bottomNavIndex = 0;
  String courierName = 'المندوب';
  int completedTasksCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourierData();
  }

  Future _loadCourierData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .get();

      // جلب المهام المكتملة مباشرة من جدول donations للمندوب الحالي
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('courierID', isEqualTo: widget.userId)
          .where('status', whereIn: ['completed', 'available'])
          .get();

      if (!mounted) return;

      String fetchedName = 'المندوب';
      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        final firstName = (data['firstName'] ?? '').toString().trim();
        final lastName = (data['lastName'] ?? '').toString().trim();
        final fullName = ('$firstName $lastName').trim();
        if (fullName.isNotEmpty) {
          fetchedName = fullName;
        }
      }

      setState(() {
        courierName = fetchedName;
        completedTasksCount = tasksSnapshot.docs.length;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    String formattedPhone = phone.trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '+966${formattedPhone.substring(1)}';
    }
    final url = Uri.parse('https://wa.me/$formattedPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      AppDesign.showErrorSnackBar(context, 'تعذر فتح تطبيق واتساب');
    }
  }

  Future _completeTask(String donationId, String originalStatus) async {
    final confirm = await AppDesign.showAppDialog(
      context: context,
      title: 'إتمام التوصيل',
      message: 'هل أنت متأكد من إتمام وتأكيد تسليم الطلب؟',
      confirmText: 'تأكيد التسليم',
    );

    if (confirm != true) return;

    try {
      final targetStatus = originalStatus == 'published'
          ? 'available'
          : 'completed';

      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .update({
            'status': targetStatus,
            'deliveredAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      AppDesign.showSuccessSnackBar(context, 'تم تسجيل التسليم بنجاح');
    } catch (e) {
      if (!mounted) return;
      AppDesign.showErrorSnackBar(context, 'حدث خطأ أثناء تحديث الحالة: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(),
      CourierTasksPage(userId: widget.userId),
      CourierMorePage(userId: widget.userId),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppDesign.background,
        body: pages[_bottomNavIndex],
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          decoration: BoxDecoration(
            color: AppDesign.white,
            borderRadius: BorderRadius.circular(AppDesign.radiusXL),
            boxShadow: [
              BoxShadow(
                color: AppDesign.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: NavigationBar(
            height: 78,
            selectedIndex: _bottomNavIndex,
            backgroundColor: Colors.transparent,
            indicatorColor: AppDesign.secondary.withOpacity(0.16),
            surfaceTintColor: Colors.transparent,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) {
              setState(() {
                _bottomNavIndex = index;
              });
              if (index == 0) {
                _loadCourierData();
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: AppDesign.primary),
                selectedIcon: Icon(
                  Icons.home_rounded,
                  color: AppDesign.primary,
                ),
                label: 'الرئيسية',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.local_shipping_outlined,
                  color: AppDesign.primary,
                ),
                selectedIcon: Icon(
                  Icons.local_shipping_rounded,
                  color: AppDesign.primary,
                ),
                label: 'المهام',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline, color: AppDesign.primary),
                selectedIcon: Icon(Icons.person, color: AppDesign.primary),
                label: 'حسابي',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    final firstLetter = courierName.trim().isNotEmpty
        ? courierName.trim()[0]
        : 'م';

    return SafeArea(
      child: RefreshIndicator(
        color: AppDesign.primary,
        onRefresh: _loadCourierData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppPadding.screen.copyWith(top: 22, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppDesign.primary,
                    child: Text(
                      firstLetter,
                      style: const TextStyle(
                        color: AppDesign.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  AppGap.wMD,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مرحبًا بك',
                          style: AppDesign.bodyStyle.copyWith(
                            color: AppDesign.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          courierName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppDesign.h1Style.copyWith(
                            color: AppDesign.primary,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppDesign.white,
                  borderRadius: BorderRadius.circular(AppDesign.radiusXL),
                  border: Border.all(color: AppDesign.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppDesign.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppDesign.secondary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.done_all_rounded,
                        color: AppDesign.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المهام المكتملة',
                            style: AppDesign.bodyStyle.copyWith(
                              color: AppDesign.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$completedTasksCount',
                            style: AppDesign.h1Style.copyWith(
                              color: AppDesign.primary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'الطلبات النشطة الحالية',
                style: AppDesign.h1Style.copyWith(
                  color: AppDesign.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('donations')
                    .where('courierID', isEqualTo: widget.userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // تصفية النتائج برمجياً لتجنب مشاكل فهارس فايربيس وعرض النشطة فقط
                  final allDocs = snapshot.data?.docs ?? [];
                  final docs = allDocs.where((doc) {
                    final data = doc.data() as Map;
                    final status = data['status'] ?? '';
                    // نعرض الطلبات التي تخص المندوب ولكنها لم تصل للحالة النهائية بعد
                    return status != 'completed' && status != 'available';
                  }).toList();

                  if (docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'لا توجد طلبات نشطة حالياً',
                          style: AppDesign.bodySecondaryStyle,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final rawCity = (data['city'] ?? '').toString().trim();
                      final rawDistrict = (data['district'] ?? '')
                          .toString()
                          .trim();

                      final city = rawCity.isNotEmpty ? rawCity : 'لا يوجد';
                      final district = rawDistrict.isNotEmpty
                          ? rawDistrict
                          : 'لا يوجد';

                      final donorId = data['donorID'] ?? '';

                      final originalStatus =
                          data['originalStatus'] ?? 'published';
                      final String pickupLocation = originalStatus == 'reserved'
                          ? 'المستودع'
                          : '$city - $district';
                      final String deliveryLocation =
                          originalStatus == 'reserved'
                          ? '$city - $district'
                          : 'المستودع';

                      return FutureBuilder<DocumentSnapshot>(
                        future: donorId.isNotEmpty
                            ? FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(donorId)
                                  .get()
                            : Future.value(null),
                        builder: (context, userSnap) {
                          String name = 'صاحب الطلب';
                          String phone = '';

                          if (userSnap.hasData &&
                              userSnap.data != null &&
                              userSnap.data!.exists) {
                            final uData =
                                userSnap.data!.data()
                                    as Map<String, dynamic>? ??
                                {};
                            name =
                                '${uData['firstName'] ?? ''} ${uData['lastName'] ?? ''}'
                                    .trim();
                            phone =
                                (uData['phone'] ?? uData['phoneNumber'] ?? '')
                                    .toString();
                          }

                          return FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('donation_boxes')
                                .where('donationId', isEqualTo: doc.id)
                                .get(),
                            builder: (context, boxesSnap) {
                              final boxesDocs = boxesSnap.data?.docs ?? [];
                              final int boxesCount = boxesDocs.length;

                              List<String> boxCodes = boxesDocs
                                  .map(
                                    (b) =>
                                        (b.data()
                                                as Map<
                                                  String,
                                                  dynamic
                                                >)['boxCode']
                                            ?.toString() ??
                                        'صندوق',
                                  )
                                  .toList();
                              if (boxCodes.isEmpty) {
                                boxCodes = ['لا توجد صناديق مضافة'];
                              }

                              String selectedBox = boxCodes.first;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
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
                                          style: AppDesign.subtitleStyle
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppDesign.warning
                                                .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Text(
                                            'قيد التوصيل',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'موقع الاستلام: $pickupLocation',
                                      style: AppDesign.bodySecondaryStyle,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'موقع التسليم: $deliveryLocation',
                                      style: AppDesign.bodySecondaryStyle,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'صاحب الطلب: $name',
                                      style: AppDesign.bodyStyle.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'الجوال: ${phone.isNotEmpty ? phone : 'غير متوفر'}',
                                          style: AppDesign.bodySecondaryStyle,
                                        ),
                                        if (phone.isNotEmpty)
                                          InkWell(
                                            onTap: () => _launchWhatsApp(phone),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(
                                                  0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.chat,
                                                    color: Colors.green,
                                                    size: 18,
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    'واتساب',
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'عدد الصناديق: $boxesCount',
                                          style: AppDesign.bodyStyle.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppDesign.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppDesign.background,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: AppDesign.border,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'الصناديق المرتبطة بالطلب:',
                                            style: AppDesign.bodySecondaryStyle
                                                .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          ...boxCodes.map(
                                            (code) => Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 3,
                                                  ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.inventory_2_outlined,
                                                    size: 16,
                                                    color: AppDesign.primary,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'رمز الصندوق: $code',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppDesign.success,
                                        ),
                                        onPressed: () => _completeTask(
                                          doc.id,
                                          originalStatus,
                                        ),
                                        child: const Text('تم التسليم'),
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
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
