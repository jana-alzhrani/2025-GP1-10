import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_design.dart';

class AdminBeneficiariesPage extends StatefulWidget {
  final String userId;

  const AdminBeneficiariesPage({
    super.key,
    required this.userId,
  });

  @override
  State<AdminBeneficiariesPage> createState() =>
      _AdminBeneficiariesPageState();
}

class _AdminBeneficiariesPageState
    extends State<AdminBeneficiariesPage> {
  int selectedTab = 0;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // =========================================================
  // Firestore
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _beneficiariesStream() {
    return _firestore
        .collection('Users')
        .where('role', isEqualTo: 'beneficiary')
        .snapshots();
  }

  String _getName(Map<String, dynamic> data) {
    final firstName =
        (data['firstName'] ?? '').toString().trim();
    final lastName =
        (data['lastName'] ?? '').toString().trim();

    final fullName = '$firstName $lastName'.trim();

    if (fullName.isNotEmpty) {
      return fullName;
    }

    return (data['fullName'] ?? 'مستفيد').toString();
  }

  String _getPhone(Map<String, dynamic> data) {
    return (data['phoneNumber'] ??
            data['phone'] ??
            'غير متوفر')
        .toString();
  }

  String _getSocialSecurityNumber(
      Map<String, dynamic> data) {
    return (data['socialSecurityNumber'] ??
            data['socialSecurity'] ??
            'غير متوفر')
        .toString();
  }

  String _getPdfUrl(Map<String, dynamic> data) {
    return (data['socialSecurityPdfUrl'] ??
            data['socialSecurityFile'] ??
            '')
        .toString();
  }

  String _getStatus(Map<String, dynamic> data) {
    return (data['status'] ?? 'pending')
        .toString()
        .trim()
        .toLowerCase();
  }

  // =========================================================
  // Approve
  // =========================================================

  Future<void> _approveBeneficiary(
    String documentId,
    String name,
  ) async {
    final confirmed = await _showConfirmDialog(
      title: 'قبول الطلب',
      message:
          'هل أنت متأكد من قبول طلب $name؟',
      confirmText: 'قبول',
    );

    if (!confirmed) return;

    try {
      await _firestore
          .collection('Users')
          .doc(documentId)
          .update({
        'status': 'approved',
        'isVerified': true,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': widget.userId,
      });

      if (!mounted) return;

      _showSuccessSnackBar(
        'تم قبول المستفيد بنجاح',
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      _showErrorSnackBar(
        'حدث خطأ أثناء قبول الطلب',
      );
    }
  }

  // =========================================================
  // Reject
  // =========================================================

  Future<void> _showRejectDialog(
    String documentId,
    String name,
  ) async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppDesign.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              'رفض الطلب',
              textAlign: TextAlign.center,
              style: AppDesign.h1Style.copyWith(
                color: AppDesign.primary,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'يرجى كتابة سبب رفض طلب $name',
                  textAlign: TextAlign.center,
                  style: AppDesign.bodyStyle.copyWith(
                    color: AppDesign.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'سبب الرفض',
                    filled: true,
                    fillColor: AppDesign.background,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: AppDesign.border,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: AppDesign.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppDesign.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actionsAlignment:
                MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: Text(
                  'إلغاء',
                  style: AppDesign.bodyStyle.copyWith(
                    color: AppDesign.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  final value =
                      controller.text.trim();

                  if (value.isEmpty) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'يرجى كتابة سبب الرفض',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(
                    dialogContext,
                    value,
                  );
                },
                child: Text(
                  'رفض الطلب',
                  style: AppDesign.bodyStyle.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();

    if (reason == null || reason.isEmpty) return;

    try {
      await _firestore
          .collection('Users')
          .doc(documentId)
          .update({
        'status': 'rejected',
        'isVerified': false,
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'reviewedBy': widget.userId,
      });

      if (!mounted) return;

      _showSuccessSnackBar(
        'تم رفض الطلب',
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      _showErrorSnackBar(
        'حدث خطأ أثناء رفض الطلب',
      );
    }
  }

  // =========================================================
  // Delete approved beneficiary
  // =========================================================

  Future<void> _deleteBeneficiary(
    String documentId,
    String name,
  ) async {
    final confirmed = await _showConfirmDialog(
      title: 'حذف المستفيد',
      message:
          'هل أنت متأكد من حذف $name من قائمة المستفيدين؟',
      confirmText: 'حذف',
      destructive: true,
    );

    if (!confirmed) return;

    try {
      // مبدئيًا Soft Delete أفضل من حذف المستند نهائيًا.
      await _firestore
          .collection('Users')
          .doc(documentId)
          .update({
        'status': 'deleted',
        'isVerified': false,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': widget.userId,
      });

      if (!mounted) return;

      _showSuccessSnackBar(
        'تم حذف المستفيد من القائمة',
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      _showErrorSnackBar(
        'حدث خطأ أثناء حذف المستفيد',
      );
    }
  }

  // =========================================================
  // PDF
  // =========================================================

  Future<void> _openPdf(String url) async {
    if (url.trim().isEmpty) {
      _showErrorSnackBar(
        'ملف إثبات الضمان غير متوفر',
      );
      return;
    }

    try {
      final uri = Uri.parse(url);

      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        _showErrorSnackBar(
          'تعذر فتح الملف',
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showErrorSnackBar(
        'تعذر فتح الملف',
      );
    }
  }

  // =========================================================
  // Build
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppDesign.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),

              const SizedBox(height: 18),

              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: _buildTabs(),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: StreamBuilder<
                    QuerySnapshot<
                        Map<String, dynamic>>>(
                  stream: _beneficiariesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(
                          color: AppDesign.primary,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return _buildErrorState();
                    }

                    final allDocs =
                        snapshot.data?.docs ?? [];

                    final filteredDocs =
                        allDocs.where((doc) {
                      final status =
                          _getStatus(doc.data());

                      if (selectedTab == 0) {
                        return status == 'pending';
                      }

                      return status == 'approved';
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(
                        20,
                        5,
                        20,
                        30,
                      ),
                      itemCount:
                          filteredDocs.length,
                      separatorBuilder:
                          (context, index) =>
                              const SizedBox(
                        height: 12,
                      ),
                      itemBuilder:
                          (context, index) {
                        final doc =
                            filteredDocs[index];

                        return _buildBeneficiaryCard(
                          documentId: doc.id,
                          data: doc.data(),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // Header
  // =========================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: AppDesign.primary,
            ),
          ),

          Expanded(
            child: Text(
              'المستفيدون',
              textAlign: TextAlign.center,
              style: AppDesign.h1Style.copyWith(
                color: AppDesign.primary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // =========================================================
  // Tabs
  // =========================================================

  Widget _buildTabs() {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppDesign.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppDesign.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              title: 'طلبات التسجيل',
              index: 0,
            ),
          ),
          Expanded(
            child: _buildTab(
              title: 'المستفيدون',
              index: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String title,
    required int index,
  }) {
    final selected = selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppDesign.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          title,
          style: AppDesign.bodyStyle.copyWith(
            color: selected
                ? AppDesign.white
                : AppDesign.primary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // Beneficiary card
  // =========================================================

  Widget _buildBeneficiaryCard({
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    final name = _getName(data);
    final phone = _getPhone(data);

    final firstLetter =
        name.trim().isNotEmpty
            ? name.trim()[0]
            : 'م';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          _showBeneficiaryDetails(
            documentId,
            data,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppDesign.white,
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color: AppDesign.border,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.035),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor:
                    AppDesign.secondary
                        .withOpacity(0.17),
                child: Text(
                  firstLetter,
                  style:
                      AppDesign.h1Style.copyWith(
                    color: AppDesign.primary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          AppDesign.h1Style.copyWith(
                        color: AppDesign.primary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color:
                              AppDesign.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          phone,
                          style:
                              AppDesign.bodyStyle.copyWith(
                            color: AppDesign
                                .textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (selectedTab == 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppDesign.softGreen
                        .withOpacity(0.16),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    'قيد المراجعة',
                    style:
                        AppDesign.bodyStyle.copyWith(
                      color: AppDesign.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

              const SizedBox(width: 7),

              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 17,
                color:
                    AppDesign.primary.withOpacity(0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // Details Bottom Sheet
  // =========================================================

  void _showBeneficiaryDetails(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final name = _getName(data);
    final phone = _getPhone(data);
    final socialNumber =
        _getSocialSecurityNumber(data);
    final pdfUrl = _getPdfUrl(data);
    final status = _getStatus(data);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height *
                      0.82,
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              24 +
                  MediaQuery.of(context)
                      .padding
                      .bottom,
            ),
            decoration: const BoxDecoration(
              color: AppDesign.background,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppDesign.border,
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Text(
                    status == 'pending'
                        ? 'تفاصيل طلب التسجيل'
                        : 'بيانات المستفيد',
                    textAlign: TextAlign.center,
                    style:
                        AppDesign.h1Style.copyWith(
                      color: AppDesign.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildDetailItem(
                    icon: Icons.person_outline,
                    label: 'الاسم',
                    value: name,
                  ),

                  _buildDetailItem(
                    icon: Icons.phone_outlined,
                    label: 'رقم الجوال',
                    value: phone,
                  ),

                  _buildDetailItem(
                    icon:
                        Icons.badge_outlined,
                    label: 'رقم الضمان الاجتماعي',
                    value: socialNumber,
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppDesign.white,
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color: AppDesign.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: AppDesign.secondary
                                .withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(
                                    14),
                          ),
                          child: const Icon(
                            Icons
                                .picture_as_pdf_outlined,
                            color:
                                AppDesign.primary,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'إثبات الضمان الاجتماعي',
                                style: AppDesign
                                    .bodyStyle
                                    .copyWith(
                                  color:
                                      AppDesign.primary,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                pdfUrl.isEmpty
                                    ? 'لا يوجد ملف مرفق'
                                    : 'عرض الملف المرفق',
                                style: AppDesign
                                    .bodyStyle
                                    .copyWith(
                                  color: AppDesign
                                      .textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (pdfUrl.isNotEmpty)
                          IconButton(
                            onPressed: () {
                              _openPdf(pdfUrl);
                            },
                            icon: const Icon(
                              Icons
                                  .open_in_new_rounded,
                              color:
                                  AppDesign.primary,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  if (status == 'pending') ...[
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _approveBeneficiary(
                            documentId,
                            name,
                          );
                        },
                        icon: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'قبول الطلب',
                        ),
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              AppDesign.primary,
                          foregroundColor:
                              Colors.white,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    18),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      height: 52,
                      child: TextButton.icon(
                        onPressed: () {
                          _showRejectDialog(
                            documentId,
                            name,
                          );
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color:
                              Colors.red.shade700,
                        ),
                        label: Text(
                          'رفض الطلب',
                          style: TextStyle(
                            color:
                                Colors.red.shade700,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (status == 'approved')
                    SizedBox(
                      height: 52,
                      child: TextButton.icon(
                        onPressed: () {
                          _deleteBeneficiary(
                            documentId,
                            name,
                          );
                        },
                        icon: Icon(
                          Icons
                              .delete_outline_rounded,
                          color:
                              Colors.red.shade700,
                        ),
                        label: Text(
                          'حذف المستفيد',
                          style: TextStyle(
                            color:
                                Colors.red.shade700,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppDesign.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppDesign.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppDesign.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      AppDesign.bodyStyle.copyWith(
                    color:
                        AppDesign.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style:
                      AppDesign.bodyStyle.copyWith(
                    color: AppDesign.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Empty / Error
  // =========================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppDesign.secondary
                    .withOpacity(0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(
                selectedTab == 0
                    ? Icons
                        .pending_actions_outlined
                    : Icons.people_outline,
                color: AppDesign.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              selectedTab == 0
                  ? 'لا توجد طلبات تسجيل حاليًا'
                  : 'لا يوجد مستفيدون حاليًا',
              textAlign: TextAlign.center,
              style: AppDesign.h1Style.copyWith(
                color: AppDesign.primary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Text(
          'تعذر تحميل بيانات المستفيدين',
          textAlign: TextAlign.center,
          style: AppDesign.bodyStyle.copyWith(
            color: AppDesign.textSecondary,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // Confirmation Dialog
  // =========================================================

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppDesign.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              title,
              textAlign: TextAlign.center,
              style: AppDesign.h1Style.copyWith(
                color: AppDesign.primary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              message,
              textAlign: TextAlign.center,
              style: AppDesign.bodyStyle.copyWith(
                color: AppDesign.textSecondary,
              ),
            ),
            actionsAlignment:
                MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },
                child: Text(
                  'إلغاء',
                  style: AppDesign.bodyStyle.copyWith(
                    color:
                        AppDesign.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                child: Text(
                  confirmText,
                  style: AppDesign.bodyStyle.copyWith(
                    color: destructive
                        ? Colors.red.shade700
                        : AppDesign.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    return result ?? false;
  }

  // =========================================================
  // Messages
  // =========================================================

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
