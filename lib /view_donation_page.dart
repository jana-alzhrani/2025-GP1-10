import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'app_design.dart';
import 'edit_donation_page.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ViewDonationPage extends StatefulWidget {
  final String userEmail;

  const ViewDonationPage({
    super.key,
    required this.userEmail,
  });

  @override
  State<ViewDonationPage> createState() => _ViewDonationPageState();
}

class _ViewDonationPageState extends State<ViewDonationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomNavIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  bool _isDraftStatus(String status) {
    return status.toLowerCase() == 'draft';
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'مسودة';
      case 'published':
        return 'مؤكد';
      case 'available':
        return 'متاح';
      case 'reserved':
        return 'محجوز';
      case 'delivered':
        return 'تم التسليم';
      default:
        return status;
    }
  }

  String _formatDate(dynamic createdAt) {
    if (createdAt == null) return 'غير محدد';
    if (createdAt is Timestamp) {
      final date = createdAt.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'غير محدد';
  }

  Color _statusBackground(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return AppDesign.warning.withOpacity(0.35);
      case 'published':
        return AppDesign.softGreen.withOpacity(0.20);
      case 'available':
        return AppDesign.secondary.withOpacity(0.18);
      case 'reserved':
        return AppDesign.warning.withOpacity(0.35);
      case 'delivered':
        return AppDesign.softGreen.withOpacity(0.20);
      default:
        return AppDesign.surfaceAlt;
    }
  }

  Color _statusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return AppDesign.primary;
      case 'published':
        return AppDesign.success;
      case 'available':
        return AppDesign.primary;
      case 'reserved':
        return AppDesign.primary;
      case 'delivered':
        return AppDesign.success;
      default:
        return AppDesign.textPrimary;
    }
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spaceMD,
        vertical: AppDesign.spaceSM,
      ),
      decoration: BoxDecoration(
        color: AppDesign.surfaceAlt,
        borderRadius: BorderRadius.circular(AppDesign.radiusLG),
        border: Border.all(color: AppDesign.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDesign.iconSM, color: AppDesign.primary),
          const SizedBox(width: AppDesign.spaceSM),
          Text(
            text,
            style: AppDesign.captionStyle.copyWith(
              color: AppDesign.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDonation(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف التبرع'),
        content: const Text(
          'هل أنت متأكد من حذف هذا التبرع؟ سيتم حذف جميع الصناديق المرتبطة به أيضًا.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesign.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
        );
        return;
      }

      final donationDoc = await FirebaseFirestore.instance
          .collection('donations')
          .doc(docId)
          .get();

      if (!donationDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('التبرع غير موجود')),
        );
        return;
      }

      final donationData = donationDoc.data() as Map<String, dynamic>;
      final donorId = donationData['donorID']?.toString();

      if (donorId != currentUser.uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكنك حذف تبرع لا يخصك')),
        );
        return;
      }

      final boxesSnapshot = await FirebaseFirestore.instance
          .collection('donation_boxes')
          .where('donationId', isEqualTo: docId)
          .get();

      for (final boxDoc in boxesSnapshot.docs) {
        await boxDoc.reference.delete();
      }

      await FirebaseFirestore.instance
          .collection('donations')
          .doc(docId)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف التبرع بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حذف التبرع: $e')),
      );
    }
  }

  Future<void> _moveDraftToConfirmed(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد التبرع'),
        content: const Text(
          'هل أنت متأكد من اعتماد هذا التبرع؟ لن تتمكن من تعديله أو حذفه بعد اختيار طريقة التوصيل.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;

    Navigator.pushNamed(
      context,
      '/deliveryMethod',
      arguments: docId,
    );
  }

  Future<void> _openEditDonation(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditDonationPage(
          donationId: doc.id,
          initialGender: data['gender']?.toString(),
          initialAgeGroupLabel: data['ageGroup']?.toString(),
          initialItemCount: (data['numberOfItems'] ?? 0) as int,
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث التبرع بنجاح')),
      );
    }
  }

  Future<void> printBoxLabel(String boxCode, String boxId) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Center(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  boxCode,
                  style: pw.TextStyle(fontSize: 42),
                ),
                  pw.SizedBox(height: 10),
                  pw.Text("ID: $boxId"),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
    );
  }

  Widget _buildDonationCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final String gender = (data['gender'] ?? '-').toString();
    final String ageGroup = (data['ageGroup'] ?? '-').toString();
    final int numberOfItems = (data['numberOfItems'] ?? 0) as int;
    final String status = (data['status'] ?? '-').toString();
    final dynamic createdAt = data['createdAt'];

    final bool isDraft = _isDraftStatus(status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDesign.spaceLG),
      padding: const EdgeInsets.all(AppDesign.cardPadding),
      decoration: AppDesign.primaryCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'تبرع ($gender - $ageGroup)',
                  textAlign: TextAlign.right,
                  style: AppDesign.subtitleStyle.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppDesign.spaceSM),
              Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _statusBackground(status),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    _formatStatus(status),
                    style: AppDesign.captionStyle.copyWith(
                      color: _statusTextColor(status),
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: AppDesign.spaceSM),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppDesign.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppDesign.radiusMD),
                  border: Border.all(color: AppDesign.border),
                ),
                child: const Icon(
                  Icons.volunteer_activism,
                  color: AppDesign.primary,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesign.spaceLG),
          StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('donation_boxes')
      .where('donationId', isEqualTo: doc.id)
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Text(
        "لا توجد صناديق",
        style: AppDesign.captionStyle,
      );
    }

    final boxes = snapshot.data!.docs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AppGap.sm,

        Text(
          "الصناديق",
          style: AppDesign.subtitleStyle.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),

        AppGap.sm,

        ...boxes.map((box) {
final data = box.data() as Map<String, dynamic>;
final boxCode = data['boxCode'] ?? '---';
final boxId = box.id;
final donationId = data['donationId'] ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: AppDesign.spaceSM),
            padding: const EdgeInsets.all(AppDesign.cardPadding),
            decoration: AppDesign.softCardDecoration,
            child: Row(
              children: [

                // زر الطباعة
                Container(
                  decoration: BoxDecoration(
                    color: AppDesign.primary.withOpacity(0.08),
                    borderRadius:
                        BorderRadius.circular(AppDesign.radiusMD),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.print),
                    color: AppDesign.primary,
                    onPressed: () {
                      printBoxLabel(boxCode,  donationId);
                    },
                  ),
                ),

                AppGap.wMD,

                // النص
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        boxCode,
                        style: AppDesign.h2Style.copyWith(
                          color: AppDesign.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppGap.xs,
                      Text(
                        "ID: $donationId",
                        style: AppDesign.captionStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  },
),
          Align(
            alignment: Alignment.centerRight,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                alignment: WrapAlignment.start,
                runAlignment: WrapAlignment.start,
                spacing: AppDesign.spaceSM,
                runSpacing: AppDesign.spaceSM,
                children: [
                  _chip(Icons.wc_outlined, gender),
                  _chip(Icons.cake_outlined, ageGroup),
                  _chip(Icons.inventory_2_outlined, '$numberOfItems قطع'),
                  _chip(Icons.calendar_today_outlined, _formatDate(createdAt)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDesign.spaceSM),
          Row(
            children: isDraft
                ? [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openEditDonation(doc),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('تعديل'),
                      ),
                    ),
                    const SizedBox(width: AppDesign.spaceSM),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteDonation(doc.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppDesign.error,
                          side: const BorderSide(color: AppDesign.error),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('حذف'),
                      ),
                    ),
                    const SizedBox(width: AppDesign.spaceSM),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _moveDraftToConfirmed(doc.id),
                        icon: const Icon(Icons.check),
                        label: const Text('تأكيد'),
                      ),
                    ),
                  ]
                : [],
          ),
        ],
      ),
    );
  }

  Widget _buildDonationsList(bool draftsOnly) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Center(
        child: Text(
          'يجب تسجيل الدخول أولاً',
          style: AppDesign.bodyStyle.copyWith(
            color: AppDesign.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .where('donorID', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'حدث خطأ في تحميل التبرعات',
              style: AppDesign.bodyStyle.copyWith(color: AppDesign.primary),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? '').toString();
          return draftsOnly ? _isDraftStatus(status) : !_isDraftStatus(status);
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  draftsOnly
                      ? Icons.description_outlined
                      : Icons.volunteer_activism_outlined,
                  size: AppDesign.iconLG + 20,
                  color: AppDesign.secondary,
                ),
                const SizedBox(height: AppDesign.spaceMD),
                Text(
                  draftsOnly
                      ? 'لا توجد مسودات حالياً'
                      : 'لا توجد تبرعات حالياً',
                  style: AppDesign.subtitleStyle.copyWith(
                    color: AppDesign.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppDesign.screenPadding),
          itemCount: filteredDocs.length,
          itemBuilder: (_, index) => _buildDonationCard(filteredDocs[index]),
        );
      },
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
          if (index == _bottomNavIndex && index == 1) return;

          setState(() {
            _bottomNavIndex = index;
          });

          if (index == 0) {
            Navigator.pushReplacementNamed(
              context,
              '/donorHome',
              arguments: widget.userEmail,
            );
          } else if (index == 2) {
            Navigator.pushReplacementNamed(
              context,
              '/donorMore',
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppDesign.background,
                AppDesign.surfaceAlt,
                AppDesign.background,
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDesign.screenPadding,
                    AppDesign.screenPadding,
                    AppDesign.screenPadding,
                    AppDesign.spaceMD,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'تبرعاتي',
                        textAlign: TextAlign.center,
                        style: AppDesign.h1Style.copyWith(
                          color: AppDesign.primary,
                        ),
                      ),
                      const SizedBox(height: AppDesign.spaceXS),
                      Text(
                        'إدارة المسودات والتبرعات النشطة',
                        textAlign: TextAlign.center,
                        style: AppDesign.bodySecondaryStyle,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesign.screenPadding,
                  ),
                  child: Container(
                    height: 58,
                    padding: const EdgeInsets.all(AppDesign.spaceXS),
                    decoration: BoxDecoration(
                      color: AppDesign.white,
                      borderRadius: BorderRadius.circular(AppDesign.radiusLG),
                      border: Border.all(color: AppDesign.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppDesign.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: AppDesign.primary,
                        borderRadius: BorderRadius.circular(AppDesign.radiusMD),
                      ),
                      labelColor: AppDesign.white,
                      unselectedLabelColor: AppDesign.primary,
                      dividerColor: Colors.transparent,
                      splashBorderRadius:
                          BorderRadius.circular(AppDesign.radiusMD),
                      labelStyle: AppDesign.bodyStyle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      tabs: const [
                        Tab(text: 'التبرعات النشطة'),
                        Tab(text: 'المسودات'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDesign.spaceSM),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDonationsList(false),
                      _buildDonationsList(true),
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
}
