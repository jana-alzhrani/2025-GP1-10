import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_design.dart';

class CourierTasksPage extends StatefulWidget {
  final String userId;

  const CourierTasksPage({super.key, required this.userId});

  @override
  State<CourierTasksPage> createState() => _CourierTasksPageState();
}

class _CourierTasksPageState extends State<CourierTasksPage> {
  int _selectedTab = 0;

  Future _acceptTask(String requestId) async {
    final confirm = await AppDesign.showAppDialog(
      context: context,
      title: 'قبول المهمة',
      message: 'هل أنت متأكد من قبول هذه المهمة؟',
      confirmText: 'قبول',
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
        'status': 'in_transit',
        'courierId': widget.userId,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      AppDesign.showSuccessSnackBar(context, 'تم قبول المهمة بنجاح');
    } catch (e) {
      if (!mounted) return;
      AppDesign.showErrorSnackBar(context, 'حدث خطأ أثناء قبول المهمة: $e');
    }
  }

  Future _completeTask(String requestId) async {
    final confirm = await AppDesign.showAppDialog(
      context: context,
      title: 'إتمام التوصيل',
      message: 'تأكيد التسليم للمستفيد؟',
      confirmText: 'تأكيد التسليم',
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
        'status': 'completed',
        'deliveredAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      AppDesign.showSuccessSnackBar(context, 'تم تسجيل التسليم بنجاح');
    } catch (e) {
      if (!mounted) return;
      AppDesign.showErrorSnackBar(context, 'حدث خطأ أثناء تحديث حالة التسليم: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppDesign.background,
        appBar: AppBar(
          title: const Text('مهام التوصيل'),
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
                      child: _buildTabButton(title: 'المهام المتاحة', index: 0),
                    ),
                    Expanded(
                      child: _buildTabButton(title: 'مهامي النشطة', index: 1),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: _selectedTab == 0
                    ? FirebaseFirestore.instance
                        .collection('requests')
                        .where('status', isEqualTo: 'pending')
                        .snapshots()
                    : FirebaseFirestore.instance
                        .collection('requests')
                        .where('courierId', isEqualTo: widget.userId)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text('حدث خطأ في تحميل المهام'));
                  }

                  final docs = snapshot.data?.docs ?? [];

                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map;
                    final status = (data['status'] ?? '').toString();
                    if (_selectedTab == 1) {
                      return status == 'in_transit' || status == 'completed';
                    }
                    return true;
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Text(
                        _selectedTab == 0 ? 'لا توجد مهام متاحة حالياً' : 'ليس لديك مهام نشطة',
                        style: AppDesign.bodySecondaryStyle,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppDesign.screenPadding),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data() as Map;
                      final status = (data['status'] ?? 'pending').toString();
                      final deliveryLocation = data['deliveryLocation'] ?? 'غير محدد';

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppDesign.spaceMD),
                        padding: const EdgeInsets.all(AppDesign.cardPadding),
                        decoration: AppDesign.primaryCardDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'طلب توصيل #${doc.id.substring(0, 5).toUpperCase()}',
                                  style: AppDesign.subtitleStyle.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: status == 'completed'
                                        ? AppDesign.success.withOpacity(0.2)
                                        : AppDesign.warning.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status == 'pending'
                                        ? 'متاح'
                                        : status == 'in_transit'
                                            ? 'قيد التوصيل'
                                            : 'مكتمل',
                                    style: AppDesign.captionStyle.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 18, color: AppDesign.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'الوجهة: $deliveryLocation',
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
                                  onPressed: () => _acceptTask(doc.id),
                                  child: const Text('قبول المهمة'),
                                ),
                              )
                            else if (status == 'in_transit')
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppDesign.success),
                                  onPressed: () => _completeTask(doc.id),
                                  child: const Text('تحديد كـ تم التسليم'),
                                ),
                              ),
                          ],
                        ),
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
