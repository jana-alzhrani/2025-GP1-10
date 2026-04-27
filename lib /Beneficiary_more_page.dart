import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_design.dart';

class BeneficiaryMorePage extends StatefulWidget {
  final String userId;

  const BeneficiaryMorePage({
    super.key,
    required this.userId,
  });

  @override
  State<BeneficiaryMorePage> createState() => _BeneficiaryMorePageState();
}

class _BeneficiaryMorePageState extends State<BeneficiaryMorePage> {
  final int _bottomNavIndex = 2;

  String firstName = '';
  String lastName = '';
  String phone = '';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() ?? {};

        setState(() {
          firstName = (data['firstName'] ?? '').toString().trim();
          lastName = (data['lastName'] ?? '').toString().trim();
          phone = (data['phone'] ?? '').toString().trim();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _showLogoutDialog() async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'تسجيل الخروج',
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'هل أنت متأكد من تسجيل الخروج؟',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              await FirebaseAuth.instance.signOut();

              if (!mounted) return;

              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            },
            child: const Text(
              'تسجيل الخروج',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppDesign.background,
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
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
                        padding:
                            AppPadding.screen.copyWith(top: 10, bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildInfoField('الاسم الأول', firstName),
                            AppGap.md,
                            _buildInfoField('الاسم الأخير', lastName),
                            AppGap.md,
                            _buildInfoField('رقم الجوال', phone),

                            AppGap.xl,

                            SizedBox(
                              height: AppDesign.buttonHeightMD,
                              child: ElevatedButton(
                                onPressed: () {},
                                child: Text(
                                  'تعديل',
                                  style:
                                      AppDesign.buttonOnPrimaryStyle.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),

                            AppGap.lg,

                            GestureDetector(
                              onTap: _showLogoutDialog,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.logout_rounded,
                                    color: Colors.red,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'تسجيل الخروج',
                                    style:
                                        AppDesign.subtitleStyle.copyWith(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
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
          ),
        ),
        AppGap.sm,
        Container(
          height: AppDesign.inputHeight,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppDesign.surface,
            borderRadius: BorderRadius.circular(AppDesign.radiusLG),
            border: Border.all(color: AppDesign.border),
          ),
          child: Text(
            value.isEmpty ? '-' : value,
            style: AppDesign.subtitleStyle.copyWith(
              color: AppDesign.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: _bottomNavIndex,
      onDestinationSelected: (index) {
        if (index == 0) {
          Navigator.pushReplacementNamed(
            context,
            '/beneficiaryHome',
            arguments: widget.userId,
          );
        } else if (index == 1) {
          Navigator.pushReplacementNamed(
            context,
            '/',
            arguments: widget.userId,
          );
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          label: 'الرئيسية',
        ),
        NavigationDestination(
          icon: Icon(Icons.volunteer_activism_outlined),
          label: 'تبرعاتي',
        ),
        NavigationDestination(
          icon: Icon(Icons.more_horiz),
          label: 'المزيد',
        ),
      ],
    );
  }
}
