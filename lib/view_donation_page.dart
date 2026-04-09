import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'edit_donation_page.dart';

class ViewDonationPage extends StatefulWidget {
  const ViewDonationPage({super.key});

  @override
  State<ViewDonationPage> createState() => _ViewDonationPageState();
}

class _ViewDonationPageState extends State<ViewDonationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
      case 'active':
        return 'نشط';
      case 'requested':
        return 'تم الطلب';
      case 'completed':
        return 'مكتمل';
      case 'pending':
        return 'قيد المراجعة';
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

  Widget _chip(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(left: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
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
        content: const Text('هل أنت متأكد من حذف هذا التبرع؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(docId)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف التبرع بنجاح')),
      );
    }
  }

  Future<void> _moveDraftToActive(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد التبرع'),
        content: const Text('هل تريد نقل هذا التبرع من مسودة إلى نشط؟'),
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

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(docId)
          .update({
        'status': 'pending',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث حالة التبرع')),
      );
    }
  }

  Future<void> _openEditDonation(DocumentSnapshot doc) async {
  final data = doc.data() as Map<String, dynamic>;

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EditDonationPage(
        donationId: doc.id,
        initialGender: data['gender']?.toString(),
        initialAgeGroup: data['ageGroup'] is Map<String, dynamic>
            ? data['ageGroup'] as Map<String, dynamic>
            : null,
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

  Widget _buildDonationCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final String gender = (data['gender'] ?? '-').toString();
    final String ageGroup = (data['ageGroup'] ?? '-').toString();
    final int numberOfItems = (data['numberOfItems'] ?? 0) as int;
    final String status = (data['status'] ?? '-').toString();
    final dynamic createdAt = data['createdAt'];

    final bool isDraft = _isDraftStatus(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'تبرع (${gender} - ${ageGroup})',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.volunteer_activism,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isDraft
                      ? AppColors.secondaryLight
                      : const Color(0xFFDFF7EA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatStatus(status),
                  style: TextStyle(
                    color: isDraft ? AppColors.primary : AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.end,
            children: [
              _chip(Icons.wc_outlined, gender),
              _chip(Icons.cake_outlined, ageGroup),
              _chip(Icons.inventory_2_outlined, '$numberOfItems قطع'),
              _chip(Icons.calendar_today_outlined, _formatDate(createdAt)),
            ],
          ),
          const SizedBox(height: 8),
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteDonation(doc.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side:
                              const BorderSide(color: AppColors.danger),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('حذف'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _moveDraftToActive(doc.id),
                        icon: const Icon(Icons.check),
                        label: const Text('تأكيد'),
                      ),
                    ),
                  ]
                : [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'الحالة الحالية: ${_formatStatus(status)}',
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryLight,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.visibility_outlined),
                            SizedBox(width: 8),
                            Text('عرض الحالة'),
                          ],
                        ),
                      ),
                    ),
                  ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonationsList(bool draftsOnly) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'حدث خطأ في تحميل التبرعات',
              style: const TextStyle(color: AppColors.primary),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? '').toString();
          return draftsOnly
              ? _isDraftStatus(status)
              : !_isDraftStatus(status);
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Text(
              draftsOnly
                  ? 'لا توجد مسودات حالياً'
                  : 'لا توجد تبرعات نشطة حالياً',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(18),
          itemCount: filteredDocs.length,
          itemBuilder: (_, index) => _buildDonationCard(filteredDocs[index]),
        );
      },
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
                AppColors.background,
                AppColors.secondaryLight,
                AppColors.background,
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text(
                              'تبرعاتي',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'إدارة المسودات والتبرعات النشطة',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    height: 58,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.primary,
                      dividerColor: Colors.transparent,
                      splashBorderRadius: BorderRadius.circular(16),
                      labelStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      tabs: const [
                        Tab(text: 'التبرعات النشطة'),
                        Tab(text: 'المسودات'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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
      ),
    );
  }
}