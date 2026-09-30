import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'app_design.dart';
import 'Beneficiary_view_donation_page.dart';

class BeneficiaryCartPage extends StatefulWidget {
  final String userId;

  const BeneficiaryCartPage({
    super.key,
    required this.userId,
  });

  @override
  State<BeneficiaryCartPage> createState() =>
      _BeneficiaryCartPageState();
}

class _BeneficiaryCartPageState
    extends State<BeneficiaryCartPage> {

  bool _isDeleting = false;
  bool _isSubmittingOrder = false;

 Future<void> _deleteFromCart(String cartDocId) async {
  try {
    await FirebaseFirestore.instance
        .collection('cart')
        .doc(cartDocId)
        .delete();

    if (!mounted) return;

    AppDesign.showSuccessSnackBar(
      context,
      'تمت إزالة الصندوق من السلة',
    );
  } catch (e) {
    if (!mounted) return;

    AppDesign.showErrorSnackBar(
      context,
      'تعذر إزالة الصندوق من السلة',
    );
  }
}Future<void> _submitOrder(
  List<Map<String, dynamic>> availableItems,
) async {
  if (_isSubmittingOrder) return;

  try {
    setState(() {
      _isSubmittingOrder = true;
    });

    final firestore = FirebaseFirestore.instance;

    // إنشاء رقم الطلب
    final orderRef = firestore.collection('orders').doc();

    // تجهيز الصناديق الموجودة في الطلب
    final List<Map<String, dynamic>> orderItems =
        availableItems.map((item) {
      final box = item['box'] as Map<String, dynamic>;

      return {
        'boxId': item['boxId'],
        'donationId': box['donationId'] ?? '',
        'numberOfItems': box['items'] is List
            ? (box['items'] as List).length
            : 0,
        'gender': box['gender'] ?? '',
        'ageGroup': box['ageGroup']?['label'] ?? '',
        'generalSize': box['generalSize'] ?? '',
      };
    }).toList();

    // إنشاء Batch لتنفيذ كل عمليات الطلب معًا
final batch = firestore.batch();

// إنشاء الطلب
batch.set(orderRef, {
  'beneficiaryId': widget.userId,
  'status': 'pending',
  'items': orderItems,
  'numberOfBoxes': orderItems.length,
  'createdAt': FieldValue.serverTimestamp(),
});

// تحديث حالة الصناديق
for (final item in availableItems) {
  final boxId = item['boxId'].toString();

  final boxRef = firestore
      .collection('donation_boxes')
      .doc(boxId);

  batch.update(boxRef, {
    'status': 'reserved',
    'orderId': orderRef.id,
    'reservedBy': widget.userId,
    'reservedAt': FieldValue.serverTimestamp(),
  });
}

// تحديث حالة عناصر السلة
for (final item in availableItems) {
  final cartDocId = item['cartDocId'].toString();

  final cartRef = firestore
      .collection('cart')
      .doc(cartDocId);

  batch.update(cartRef, {
    'status': 'ordered',
    'orderId': orderRef.id,
    'orderedAt': FieldValue.serverTimestamp(),
  });
}

// تنفيذ جميع العمليات
await batch.commit();

    if (!mounted) return;

    AppDesign.showSuccessSnackBar(
      context,
      'تم إرسال طلب التبرع بنجاح',
    );
  } catch (e) {
    if (!mounted) return;

    AppDesign.showErrorSnackBar(
      context,
      'حدث خطأ أثناء إتمام الطلب',
    );
  } finally {
    if (mounted) {
      setState(() {
        _isSubmittingOrder = false;
      });
    }
  }
}
  Future<Map<String, dynamic>?> _getBoxData(
    String boxId,
  ) async {
    final doc = await FirebaseFirestore.instance
        .collection('donation_boxes')
        .doc(boxId)
        .get();

    if (!doc.exists) return null;

    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppDesign.background,

        appBar: AppBar(
          title: Text(
            'السلة',
            style: AppDesign.h2Style.copyWith(
              color: AppDesign.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
          backgroundColor: AppDesign.background,
          foregroundColor: AppDesign.textPrimary,
          elevation: 0,
        ),

        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('cart')
              .where(
                'beneficiaryId',
                isEqualTo: widget.userId,
              )
              .where(
                'status',
                isEqualTo: 'in_cart',
              )
              .snapshots(),

          builder: (context, snapshot) {

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'حدث خطأ أثناء تحميل السلة',
                  style: AppDesign.bodyStyle.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }

            final cartDocs =
                snapshot.data?.docs ?? [];

            if (cartDocs.isEmpty) {
              return _buildEmptyCart();
            }

            return FutureBuilder<
                List<Map<String, dynamic>>>(
              future: _loadCartItems(cartDocs),
              builder: (context, cartSnapshot) {

                if (cartSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final items =
                    cartSnapshot.data ?? [];

                final availableItems = items
                    .where((item) =>
                        item['isAvailable'] == true)
                    .toList();

                final unavailableItems = items
                    .where((item) =>
                        item['isAvailable'] == false)
                    .toList();

                return Column(
                  children: [

                    Expanded(
                      child: ListView(
                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          10,
                          16,
                          20,
                        ),
                        children: [

                          if (availableItems.isNotEmpty) ...[
                            _buildSectionTitle(
                              'الصناديق المتاحة',
                            ),

                            const SizedBox(height: 10),

                            ...availableItems.map(
                              (item) =>
                                  _buildCartCard(item),
                            ),
                          ],

                          if (unavailableItems.isNotEmpty) ...[
                            const SizedBox(height: 18),

                            _buildSectionTitle(
                              'الصناديق غير المتاحة',
                            ),

                            const SizedBox(height: 10),

                            ...unavailableItems.map(
                              (item) =>
                                  _buildCartCard(item),
                            ),
                          ],
                        ],
                      ),
                    ),

                    _buildBottomButton(
                      hasUnavailable:
                          unavailableItems.isNotEmpty,
                      hasAvailable:
                          availableItems.isNotEmpty,

                      availableItems:
                          availableItems,
                      
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadCartItems(
    List<QueryDocumentSnapshot> cartDocs,
  ) async {

    final List<Map<String, dynamic>> result = [];

    for (final cartDoc in cartDocs) {

      final cartData =
          cartDoc.data() as Map<String, dynamic>;

      final boxId =
          cartData['boxId']?.toString() ?? '';

      if (boxId.isEmpty) continue;

      final boxData =
          await _getBoxData(boxId);

      if (boxData == null) {
        result.add({
          'cartDocId': cartDoc.id,
          'boxId': boxId,
          'isAvailable': false,
          'box': <String, dynamic>{},
        });

        continue;
      }

      final status =
          boxData['status']?.toString() ?? '';

      result.add({
        'cartDocId': cartDoc.id,
        'boxId': boxId,
        'isAvailable': status == 'available',
        'box': boxData,
      });
    }

    result.sort((a, b) {

      final aAvailable =
          a['isAvailable'] == true;

      final bAvailable =
          b['isAvailable'] == true;

      if (aAvailable && !bAvailable) {
        return -1;
      }

      if (!aAvailable && bAvailable) {
        return 1;
      }

      return 0;
    });

    return result;
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: AppDesign.subtitleStyle.copyWith(
          color: AppDesign.primary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildCartCard(
    Map<String, dynamic> item,
  ) {

    final bool isAvailable =
        item['isAvailable'] == true;

    final box =
        item['box'] as Map<String, dynamic>;

    final cartDocId =
        item['cartDocId'].toString();

    final boxId =
         item['boxId'].toString();

    final gender =
        (box['gender'] ?? '-').toString();

    final ageGroup =
        (box['ageGroup']?['label'] ?? '-')
            .toString();

    final generalSize =
        (box['generalSize'] ?? '').toString();

    final items = box['items'];

    final int numberOfItems =
        items is List ? items.length : 0;

    final List images = [];

    if (items is List) {
  for (final item in items) {
    if (item is Map &&
        item['imageUrl'] != null &&
        item['imageUrl'].toString().isNotEmpty) {
      images.add(
        item['imageUrl'].toString(),
      );
    }
  }
}

    return GestureDetector(
      onTap: isAvailable
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BeneficiaryViewDonationPage(
                    boxId: boxId,
                    userId: widget.userId,
                  ),
                ),
              );
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isAvailable
            ? AppDesign.white
            : Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(
          AppDesign.radiusXL,
        ),
        border: Border.all(
          color: isAvailable
              ? AppDesign.border
              : Colors.grey.shade300,
        ),
        boxShadow: [
          if (isAvailable)
            BoxShadow(
              color: AppDesign.black
                  .withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [

            if (!isAvailable)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(12),
                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Text(
                  'هذا الصندوق وجد طريقه إلى مستفيد آخر، ويمكنك إزالته للمتابعة.',
                  textAlign: TextAlign.center,
                  style:
                      AppDesign.bodyStyle.copyWith(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                _buildImagePreview(
                  images,
                  isAvailable,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Text(
                        'صندوق تبرع',
                        style:
                            AppDesign.subtitleStyle
                                .copyWith(
                          color: isAvailable
                              ? AppDesign.textPrimary
                              : Colors.grey.shade600,
                          fontWeight:
                              FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),

                      const SizedBox(height: 10),

                      _buildInfoText(
                        'الجنس',
                        gender,
                        isAvailable,
                      ),

                      const SizedBox(height: 5),

                      _buildInfoText(
                        'الفئة العمرية',
                        ageGroup,
                        isAvailable,
                      ),

                      if (generalSize
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 5),

                        _buildInfoText(
                          'المقاس',
                          generalSize,
                          isAvailable,
                        ),
                      ],

                      const SizedBox(height: 5),

                      _buildInfoText(
                        'عدد القطع',
                        '$numberOfItems قطع',
                        isAvailable,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 45,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _deleteFromCart(cartDocId),

                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                ),

                label: const Text(
                  'إزالة من السلة',
                ),

                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      Colors.red.shade700,
                  side: BorderSide(
                    color: Colors.red.shade200,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      AppDesign.radiusLG,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildImagePreview(
  List images,
  bool isAvailable,
) {
  if (images.isEmpty) {
    return Container(
      width: 95,
      height: 115,
      decoration: BoxDecoration(
        color: AppDesign.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: 34,
        color: isAvailable
            ? AppDesign.primary
            : Colors.grey,
      ),
    );
  }

  return Container(
    width: 95,
    height: 115,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
    ),
    clipBehavior: Clip.antiAlias,
    child: Image.network(
      images.first.toString(),
      fit: BoxFit.cover,
      color: isAvailable
          ? null
          : Colors.grey.withOpacity(0.45),
      colorBlendMode: isAvailable
          ? null
          : BlendMode.saturation,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppDesign.surfaceAlt,
          child: Icon(
            Icons.broken_image_outlined,
            size: 34,
            color: isAvailable
                ? AppDesign.primary
                : Colors.grey,
          ),
        );
      },
    ),
  );
}

  Widget _buildInfoText(
    String title,
    String value,
    bool isAvailable,
  ) {
    return Text(
      '$title: $value',
      style: AppDesign.bodySecondaryStyle
          .copyWith(
        color: isAvailable
            ? AppDesign.textSecondary
            : Colors.grey.shade500,
        fontSize: 13,
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [

            Icon(
              Icons.shopping_cart_outlined,
              size: 75,
              color: AppDesign.primary
                  .withOpacity(0.45),
            ),

            const SizedBox(height: 18),

            Text(
              'السلة فارغة',
              style: AppDesign.h2Style.copyWith(
                color: AppDesign.primary,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'يمكنك إضافة صناديق التبرعات التي تناسبك من صفحة التبرعات.',
              textAlign: TextAlign.center,
              style: AppDesign.bodyStyle.copyWith(
                color: AppDesign.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required bool hasUnavailable,
    required bool hasAvailable,
    required List<Map<String, dynamic>> availableItems,
  }) {

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16,
        ),
        child: SizedBox(
          width: double.infinity,
          height: AppDesign.buttonHeightMD,
          child: ElevatedButton(
           onPressed:
    hasUnavailable || !hasAvailable || _isSubmittingOrder
        ? null
        : () async {
            await _submitOrder(availableItems);
          },
            child: Text(
              hasUnavailable
                  ? 'أزل الصناديق غير المتاحة للمتابعة'
                  : 'طلب التبرع',
            ),
          ),
        ),
      ),
    );
  }
}