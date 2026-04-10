import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_design.dart';

class DonorMorePage extends StatefulWidget {
  final String userEmail;

  const DonorMorePage({
    super.key,
    required this.userEmail,
  });

  @override
  State<DonorMorePage> createState() => _DonorMorePageState();
}

class _DonorMorePageState extends State<DonorMorePage> {
  int _bottomNavIndex = 2;

  String firstName = '';
  String lastName = '';
  String phone = '';
  String email = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final normalizedEmail = widget.userEmail.trim().toLowerCase();

      final userQuery = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (!mounted) return;

      if (userQuery.docs.isNotEmpty) {
        final data = userQuery.docs.first.data();

        setState(() {
          firstName = (data['firstName'] ?? '').toString().trim();
          lastName = (data['lastName'] ?? '').toString().trim();
          phone = (data['phone'] ?? '').toString().trim();
          email = (data['email'] ?? widget.userEmail).toString().trim();
        });
      } else {
        setState(() {
          email = widget.userEmail;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppDesign.background,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopIdentityHeader(),
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 10),
                  child: Text(
                    'البيانات الشخصية',
                    textAlign: TextAlign.center,
                    style: AppDesign.h1Style.copyWith(
                      color: AppDesign.primary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Padding(
                  padding: AppPadding.screen.copyWith(top: 10, bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInfoField('الاسم الأول', firstName),
                      AppGap.md,
                      _buildInfoField('الاسم الأخير', lastName),
                      AppGap.md,
                      _buildInfoField('رقم الجوال', phone),
                      AppGap.md,
                      _buildInfoField('البريد الإلكتروني', email),
                      AppGap.xl,
                      SizedBox(
                        height: AppDesign.buttonHeightMD,
                        child: ElevatedButton(
                          onPressed: () {
                            // لاحقًا: التنقل لصفحة التعديل
                          },
                          child: Text(
                            'تعديل',
                            style: AppDesign.buttonOnPrimaryStyle.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildTopIdentityHeader() {
    return SizedBox(
      width: double.infinity,
      height: 220,
      child: Image.asset(
        'assets/images/madad_identity.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppDesign.bodyStyle.copyWith(
            color: AppDesign.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        AppGap.sm,
        SizedBox(
          height: AppDesign.inputHeight,
          child: TextFormField(
            initialValue: value.isEmpty ? '-' : value,
            readOnly: true,
            enabled: false,
            style: AppDesign.subtitleStyle.copyWith(
              color: AppDesign.primary,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: label,
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDesign.radiusLG),
                borderSide: const BorderSide(color: AppDesign.border, width: 1),
              ),
              filled: true,
              fillColor: AppDesign.surface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
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
          if (index == _bottomNavIndex && index == 2) return;

          setState(() {
            _bottomNavIndex = index;
          });

          if (index == 0) {
            Navigator.pushReplacementNamed(
              context,
              '/donorHome',
              arguments: widget.userEmail,
            );
          } else if (index == 1) {
            Navigator.pushReplacementNamed(
              context,
              '/viewDonation',
              arguments: widget.userEmail,
            );
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppDesign.primary),
            selectedIcon: Icon(Icons.home_rounded, color: AppDesign.primary),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.volunteer_activism_outlined,
              color: AppDesign.primary,
            ),
            selectedIcon: Icon(
              Icons.volunteer_activism_rounded,
              color: AppDesign.primary,
            ),
            label: 'تبرعاتي',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded, color: AppDesign.primary),
            selectedIcon:
                Icon(Icons.more_horiz_rounded, color: AppDesign.primary),
            label: 'المزيد',
          ),
        ],
      ),
    );
  }
}
