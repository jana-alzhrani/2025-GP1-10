import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'app_design.dart';

class BeneficiaryViewDonationPage extends StatefulWidget {
  final String donationId;
  final String userId;

  const BeneficiaryViewDonationPage({
    super.key,
    required this.donationId,
    required this.userId,
  });

  @override
  State<BeneficiaryViewDonationPage> createState() =>
      _BeneficiaryViewDonationPageState();
}

class _BeneficiaryViewDonationPageState
    extends State<BeneficiaryViewDonationPage> {
  bool _isAddingToCart = false;

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<Map<String, dynamic>> _loadDonationDetails() async {
    final donationDoc = await FirebaseFirestore.instance
        .collection('donations')
        .doc(widget.donationId)
        .get();

    if (!donationDoc.exists) {
      throw Exception('لم يتم العثور على التبرع');
    }

    final donationData = donationDoc.data()!;

    final boxesSnapshot = await FirebaseFirestore.instance
        .collection('donation_boxes')
        .where('donationId', isEqualTo: widget.donationId)
        .get();

    final boxes = boxesSnapshot.docs.map((boxDoc) {
      final data = boxDoc.data();

      final items = data['items'];
      List<Map<String, dynamic>> parsedItems = [];

      if (items is List) {
        parsedItems = items
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      return {
        'boxId': boxDoc.id,
        'boxNumber': _parseInt(data['boxNumber']),
        'items': parsedItems,
      };
    }).toList();

    boxes.sort(
      (a, b) =>
          _parseInt(a['boxNumber']).compareTo(_parseInt(b['boxNumber'])),
    );

    return {
      'donation': donationData,
      'boxes': boxes,
    };
  }

  Uint8List? _decodeImage(String? imageBase64) {
    if (imageBase64 == null || imageBase64.trim().isEmpty) return null;

    try {
      return base64Decode(imageBase64);
    } catch (_) {
      return null;
    }
  }

  Future<void> _addToCart(Map<String, dynamic> donationData) async {
    try {
      setState(() => _isAddingToCart = true);

      final existingCartItem = await FirebaseFirestore.instance
          .collection('cart')
          .where('beneficiaryId', isEqualTo: widget.userId)
          .where('donationId', isEqualTo: widget.donationId)
          .where('status', isEqualTo: 'in_cart')
          .limit(1)
          .get();

      if (existingCartItem.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('هذا التبرع مضاف للسلة مسبقًا')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('cart').add({
        'beneficiaryId': widget.userId,
        'donationId': widget.donationId,
        'status': 'in_cart',
        'gender': donationData['gender'] ?? '',
        'ageGroup': donationData['ageGroup'] ?? '',
        'generalSize': donationData['generalSize'] ?? '',
        'numberOfItems': _parseInt(donationData['numberOfItems']),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة التبرع إلى السلة ✅')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إضافة التبرع إلى السلة: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
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

Widget _buildItemCard(Map<String, dynamic> item, int itemIndex) {
  final imageBytes = _decodeImage(item['imageBase64']?.toString());
  final type = (item['type'] ?? 'غير محدد').toString();
  final size = (item['size'] ?? '').toString();

  return Container(
    margin: const EdgeInsets.only(bottom: AppDesign.spaceLG),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppDesign.spaceMD,
            AppDesign.spaceLG,
            AppDesign.spaceMD,
            AppDesign.spaceMD,
          ),
          decoration: BoxDecoration(
            color: AppDesign.white,
            borderRadius: BorderRadius.circular(AppDesign.radiusLG),
            border: Border.all(color: AppDesign.border),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
             GestureDetector(
  onTap: imageBytes == null ? null : () => _showImagePreview(imageBytes),
  child: Container(
    width: 88,
    height: 88,
    decoration: BoxDecoration(
      color: AppDesign.surfaceAlt,
      borderRadius: BorderRadius.circular(AppDesign.radiusMD),
      border: Border.all(color: AppDesign.border),
    ),
    child: imageBytes != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(AppDesign.radiusMD),
            child: Image.memory(
              imageBytes,
              fit: BoxFit.cover,
            ),
          )
        : const Icon(
            Icons.image_not_supported_outlined,
            color: AppDesign.secondary,
            size: 30,
          ),
  ),
),const SizedBox(width: 10),

              Flexible(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'النوع: $type',
                      textAlign: TextAlign.right,
                      style: AppDesign.bodyStyle.copyWith(
                        color: AppDesign.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (size.trim().isNotEmpty) ...[
                      const SizedBox(height: AppDesign.spaceXS),
                      Text(
                        'المقاس: $size',
                        textAlign: TextAlign.right,
                        style: AppDesign.bodySecondaryStyle,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        Positioned(
          top: -10,
          right: 22,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesign.spaceMD,
              vertical: 2,
            ),
            color: AppDesign.background,
            child: Text(
              'القطعة ${itemIndex + 1}',
              style: AppDesign.subtitleStyle.copyWith(
                fontWeight: FontWeight.w800,
                color: AppDesign.textPrimary,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
  Widget _buildBoxCard(Map<String, dynamic> box) {
    final boxNumber = _parseInt(box['boxNumber']);
    final items = List<Map<String, dynamic>>.from(box['items'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDesign.spaceLG),
      padding: const EdgeInsets.all(AppDesign.cardPadding),
      decoration: AppDesign.primaryCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppDesign.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppDesign.radiusMD),
                  border: Border.all(color: AppDesign.border),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppDesign.primary,
                ),
              ),
              const SizedBox(width: AppDesign.spaceSM),
              Expanded(
                child: Text(
                  'الصندوق $boxNumber',
                  textAlign: TextAlign.right,
                  style: AppDesign.subtitleStyle.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesign.spaceMD),
          Center(
          child: Text(
            'محتويات الصندوق',
            textAlign: TextAlign.center,
            style: AppDesign.bodySecondaryStyle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
          const SizedBox(height: AppDesign.spaceMD),
          if (items.isEmpty)
            Text(
              'لا توجد عناصر داخل هذا الصندوق',
              style: AppDesign.bodyStyle,
            )
          else
            ...List.generate(
              items.length,
              (index) => _buildItemCard(items[index], index),
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
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            'تفاصيل التبرع',
            style: AppDesign.h2Style.copyWith(
              color: AppDesign.textPrimary,
            ),
          ),
          centerTitle: true,
          backgroundColor: AppDesign.background,
          foregroundColor: AppDesign.textPrimary,
          elevation: 0,
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _loadDonationDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDesign.screenPadding),
                  child: Text(
                    'حدث خطأ أثناء تحميل تفاصيل التبرع\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: AppDesign.bodyStyle.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return Center(
                child: Text(
                  'لا توجد بيانات',
                  style: AppDesign.bodyStyle,
                ),
              );
            }

            final donationData =
                snapshot.data!['donation'] as Map<String, dynamic>;
            final boxes = snapshot.data!['boxes'] as List;

            final gender = (donationData['gender'] ?? '-').toString();
            final ageGroup = (donationData['ageGroup'] ?? '-').toString();
            final generalSize = (donationData['generalSize'] ?? '').toString();
            final numberOfItems = _parseInt(donationData['numberOfItems']);

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppPadding.screen,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(AppDesign.cardPadding),
                          decoration: AppDesign.primaryCardDecoration,
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,                            children: [
                              Text(
                                'تبرع ($gender - $ageGroup)',
                                textAlign: TextAlign.left,
                                style: AppDesign.h2Style.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppDesign.spaceMD),
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: Wrap(
                                  spacing: AppDesign.spaceSM,
                                  runSpacing: AppDesign.spaceSM,
                                  alignment: WrapAlignment.start,
                                  children: [
                                    _chip(Icons.wc_outlined, gender),
                                    _chip(Icons.cake_outlined, ageGroup),
                                    if (generalSize.trim().isNotEmpty)
                                      _chip(Icons.straighten, generalSize),
                                    _chip(Icons.inventory_2_outlined, '$numberOfItems قطع'),
                                    _chip(Icons.widgets_outlined, '${boxes.length} صناديق'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDesign.spaceXL),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'محتوى التبرع',
                            textAlign: TextAlign.right,
                            style: AppDesign.subtitleStyle.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppDesign.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDesign.spaceMD),
                        if (boxes.isEmpty)
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.all(AppDesign.cardPadding),
                            decoration: AppDesign.primaryCardDecoration,
                            child: Text(
                              'لا توجد صناديق مرتبطة بهذا التبرع حالياً',
                              textAlign: TextAlign.center,
                              style: AppDesign.bodyStyle.copyWith(
                                color: AppDesign.textSecondary,
                              ),
                            ),
                          )
                        else
                          ...boxes.map(
                            (box) => _buildBoxCard(
                              Map<String, dynamic>.from(box),
                            ),
                          ),
                        const SizedBox(height: AppDesign.space2XL),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDesign.screenPadding,
                      0,
                      AppDesign.screenPadding,
                      AppDesign.screenPadding,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: AppDesign.buttonHeightMD,
                      child: ElevatedButton.icon(
                        onPressed: _isAddingToCart
                            ? null
                            : () => _addToCart(donationData),
                        icon: _isAddingToCart
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add_shopping_cart_outlined),
                        label: Text(
                          _isAddingToCart
                              ? 'جاري الإضافة...'
                              : 'إضافة إلى السلة',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

void _showImagePreview(Uint8List imageBytes) {
  final size = MediaQuery.of(context).size.width * 0.75;

  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (_) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.cover,
                ),
              ),

              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
}
