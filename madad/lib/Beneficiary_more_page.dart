import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_design.dart';
import 'package:url_launcher/url_launcher.dart';

class BeneficiaryMorePage extends StatefulWidget {
  final String userId;

  const BeneficiaryMorePage({
    super.key,
    required this.userId,
  });

  @override
  State<BeneficiaryMorePage> createState() =>
      _BeneficiaryMorePageState();
}

class _BeneficiaryMorePageState
    extends State<BeneficiaryMorePage> {
  int _bottomNavIndex = 2;

  String firstName = '';
  String lastName = '';
  String phone = '';
  String email = '';

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

      if (!mounted) return;

      final data = userDoc.data() ?? {};

      setState(() {
        firstName = (data['firstName'] ?? '').toString().trim();
        lastName = (data['lastName'] ?? '').toString().trim();
        phone = (data['phone'] ?? '').toString().trim();
        email = FirebaseAuth.instance.currentUser?.email ?? '';
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _showLogoutDialog() async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تسجيل الخروج', textAlign: TextAlign.center),
        content: const Text(
          'هل أنت متأكد من تسجيل الخروج؟',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء', style: TextStyle(color: Color.fromARGB(255, 10, 77, 92))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await FirebaseAuth.instance.signOut();

              if (!mounted) return;

              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            child: const Text(
              'تسجيل الخروج',
              style: TextStyle(color: Color.fromARGB(255, 10, 77, 92)),
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
                    children: [
                      _buildHeader(),
                      Padding(
                        padding:
                            AppPadding.screen.copyWith(
                          top: 18,
                          bottom: 18,
                        ),
                        child: Column(
                          children: [
                            _buildPersonalCard(),
                            const SizedBox(height: 26),
                            _buildDivider(),
                            const SizedBox(height: 24),
                            _buildAboutMadadCard(),
                            const SizedBox(height: 26),
                            _buildLogoutButton(),
                            const SizedBox(height: 18),
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

  Widget _buildHeader() {
    return SizedBox(
      width: double.infinity,
      height: 150,
      child: Image.asset(
        'assets/images/madad_identity.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildPersonalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'البيانات الشخصية',
            textAlign: TextAlign.right,
            style: AppDesign.h1Style.copyWith(
              color: AppDesign.primary,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 22),
          _buildInfoField(
              label: 'الاسم الأول',
              value: firstName,
              icon: Icons.person_outline_rounded),
          const SizedBox(height: 16),
          _buildInfoField(
              label: 'الاسم الأخير',
              value: lastName,
              icon: Icons.person_outline_rounded),
          const SizedBox(height: 16),
          _buildInfoField(
              label: 'رقم الجوال',
              value: phone,
              icon: Icons.phone_outlined),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: TextAlign.right,
          style: AppDesign.bodyStyle.copyWith(
            color: AppDesign.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: AppDesign.inputHeight,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppDesign.white,
            borderRadius:
                BorderRadius.circular(AppDesign.radiusLG),
            border: Border.all(color: AppDesign.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value.isEmpty ? '-' : value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppDesign.subtitleStyle.copyWith(
                    color: AppDesign.primary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: AppDesign.primary, size: 22),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppDesign.primary.withOpacity(0.35),
            thickness: 1.1,
            endIndent: 12,
          ),
        ),
        Icon(Icons.local_florist_outlined,
            color: AppDesign.primary, size: 30),
        Expanded(
          child: Divider(
            color: AppDesign.primary.withOpacity(0.35),
            thickness: 1.1,
            indent: 12,
          ),
        ),
      ],
    );
  }

 Widget _buildAboutMadadCard() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        Row(
          children: [
            _circleIcon(Icons.info_outline_rounded),
            const SizedBox(width: 12),
            Text(
              'حول مدد',
              style: AppDesign.h1Style.copyWith(
                color: AppDesign.primary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),
        Divider(color: AppDesign.border),
        const SizedBox(height: 20),

        // ===== الموقع =====
        Row(
          textDirection: TextDirection.rtl,
          children: [
            _circleIcon(Icons.storefront_outlined),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'موقع المستودع',
                      style: AppDesign.subtitleStyle.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'مستودع مدد - واجهة الرياض',
                      style: AppDesign.bodyStyle.copyWith(
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            SizedBox(
              height: 48,
              width: 140,
              child: OutlinedButton.icon(
                onPressed: () async {
                  const url =
                      'https://www.google.com/maps/search/?api=1&query=24.768932,46.728328';

                  final uri = Uri.parse(url);

                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  }
                },
                icon: Icon(Icons.location_on_outlined,
                    color: AppDesign.primary, size: 18),
                label: Text(
                  'فتح الخريطة',
                  style: AppDesign.bodyStyle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppDesign.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDesign.radiusLG),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        Divider(color: AppDesign.border),
        const SizedBox(height: 20),

        // ===== ساعات العمل =====
        Row(
          children: [
            _circleIcon(Icons.access_time_rounded),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'ساعات العمل',
                      style: AppDesign.subtitleStyle.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'الأحد - الخميس: 9:00 ص - 5:00 م\nالجمعة والسبت: مغلق',
                      style: AppDesign.bodyStyle.copyWith(
                        fontSize: 13,
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _circleIcon(IconData icon) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppDesign.secondary.withOpacity(0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppDesign.primary, size: 24),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _showLogoutDialog,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('تسجيل الخروج',
              style: AppDesign.subtitleStyle.copyWith(
                  color: Colors.red,
                  fontSize: 21,
                  fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          const Icon(Icons.logout_rounded,
              color: Colors.red, size: 24),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppDesign.white,
      borderRadius: BorderRadius.circular(AppDesign.radiusXL),
      border: Border.all(color: AppDesign.border),
      boxShadow: [
        BoxShadow(
          color: AppDesign.black.withOpacity(0.05),
          blurRadius: 14,
          offset: const Offset(0, 8),
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

      // مهم جدًا
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
          Navigator.pushReplacementNamed(
            context,
            '/beneficiaryHome',
            arguments: widget.userId,
          );
        }

        if (index == 1) {
          Navigator.pushReplacementNamed(
            context,
            '/orders',
            arguments: widget.userId,
          );
        }

        // index 2 = more page (نفس الصفحة)
      },

      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'الرئيسية',
        ),
        NavigationDestination(
          icon: Icon(Icons.volunteer_activism_outlined),
          selectedIcon: Icon(Icons.volunteer_activism_rounded),
          label: 'طلباتي',
        ),
        NavigationDestination(
          icon: Icon(Icons.more_horiz_rounded),
          selectedIcon: Icon(Icons.more_horiz_rounded),
          label: 'المزيد',
        ),
      ],
    ),
  );
}
}