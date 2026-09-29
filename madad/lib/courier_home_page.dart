import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_design.dart';
import 'courier_tasks_page.dart';
import 'courier_more_page.dart';

class CourierHomePage extends StatefulWidget {
  final String userId;

  const CourierHomePage({super.key, required this.userId});

  @override
  State createState() => _CourierHomePageState();
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

      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('courierId', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'completed')
          .get();

      if (!mounted) return;

      String fetchedName = 'المندوب';
      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        final firstName = (data['firstName'] ?? '').toString().trim();
        final lastName = (data['lastName'] ?? '').toString().trim();
        final fullName = (firstName + ' ' + lastName).trim();
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

  @override
  Widget build(BuildContext context) {
    final List pages = [
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
            },
            destinations: const [
  NavigationDestination(
    icon: Icon(Icons.home_outlined, color: AppDesign.primary),
    selectedIcon: Icon(Icons.home_rounded, color: AppDesign.primary),
    label: 'الرئيسية',
  ),
  NavigationDestination(
    icon: Icon(Icons.local_shipping_outlined, color: AppDesign.primary),
    selectedIcon: Icon(Icons.local_shipping_rounded, color: AppDesign.primary),
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
    final firstLetter = courierName.trim().isNotEmpty ? courierName.trim()[0] : 'م';

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
              const SizedBox(height: 34),
              Text(
                'لوحة تحكم المندوب',
                style: AppDesign.h1Style.copyWith(
                  color: AppDesign.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'تابع مهام التوصيل الخاصة بك وحالة التسليم للمستفيدين',
                style: AppDesign.bodyStyle.copyWith(
                  color: AppDesign.textSecondary,
                  fontSize: 14,
                ),
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
            ],
          ),
        ),
      ),
    );
  }
}
