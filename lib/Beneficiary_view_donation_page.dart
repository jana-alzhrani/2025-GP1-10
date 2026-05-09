import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'app_design.dart';

class BeneficiaryViewDonationPage extends StatefulWidget {
  final String boxId;
  final String userId;

  const BeneficiaryViewDonationPage({
    super.key,
    required this.boxId,
    required this.userId,
  });

  @override
  State<BeneficiaryViewDonationPage> createState() =>
      _BeneficiaryViewDonationPageState();
}

class _BeneficiaryViewDonationPageState
    extends State<BeneficiaryViewDonationPage> {
  bool _isAddingToCart = false;
  late Future<Map<String, dynamic>> _donationDetailsFuture;

      @override
    void initState() {
      super.initState();
      _donationDetailsFuture = _loadDonationDetails();
    }
  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
Future<Map<String, dynamic>> _loadDonationDetails() async {
  final boxDoc = await FirebaseFirestore.instance
      .collection('donation_boxes')
      .doc(widget.boxId)
      .get();

  if (!boxDoc.exists) {
    throw Exception('لم يتم العثور على الصندوق');
  }

  final boxData = boxDoc.data()!;

  final items = boxData['items'];
  List<Map<String, dynamic>> parsedItems = [];

  if (items is List) {
    parsedItems = items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  return {
    'box': boxData,
    'items': parsedItems,
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

 Future<void> _addToCart(Map<String, dynamic> boxData) async {
  try {
    setState(() => _isAddingToCart = true);

    final existingCartItem = await FirebaseFirestore.instance
        .collection('cart')
        .where('beneficiaryId', isEqualTo: widget.userId)
        .where('boxId', isEqualTo: widget.boxId)
        .where('status', isEqualTo: 'in_cart')
        .limit(1)
        .get();

    if (existingCartItem.docs.isNotEmpty) {
      if (!mounted) return;

      AppDesign.showErrorSnackBar(
  context,
  'التبرع مضاف للسلة مسبقًا',
);
      return;
    }

    await FirebaseFirestore.instance.collection('cart').add({
      'beneficiaryId': widget.userId,
      'boxId': widget.boxId,
      'donationId': boxData['donationId'] ?? '',
      'status': 'in_cart',

      'gender': boxData['gender'] ?? '',
      'ageGroup': boxData['ageGroup']?['label'] ?? '',
      'generalSize': boxData['generalSize'] ?? '',
      'numberOfItems': (boxData['items'] is List)
          ? (boxData['items'] as List).length
          : 0,

      'createdAt': FieldValue.serverTimestamp(),
    });

    

    if (!mounted) return;

   AppDesign.showSuccessSnackBar(
  context,
    'تمت إضافة التبرع إلى السلة ',
    );

    
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('فشل إضافة الصندوق إلى السلة: $e')),
    );
  } finally {
    if (mounted) {
      setState(() => _isAddingToCart = false);
    }
  }
}
Widget _infoRow(
  IconData icon,
  String title,
  String value,
) {
  return Row(
    textDirection: TextDirection.rtl,
    children: [
      Icon(icon, size: 20, color: AppDesign.primary),
      const SizedBox(width: 8),
      Text(
        title,
        style: AppDesign.captionStyle.copyWith(
          color: AppDesign.textSecondary,
        ),
      ),
      const SizedBox(width: 12),
      Text(
        value,
        style: AppDesign.bodyStyle.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
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
      textDirection: TextDirection.rtl,
      children: [
        Icon(
          icon,
          size: AppDesign.iconSM,
          color: AppDesign.primary,
        ),
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
final imageBase64 = item['imageBase64'];
final imageUrl = item['imageUrl'];
final Uint8List? imageBytes =
    (imageBase64 != null) ? _decodeImage(imageBase64.toString()) : null;
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
                  onTap:
                      imageBytes == null ? null : () => _showImagePreview(imageBytes),
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
          gaplessPlayback: true,
        ),
      )
    : (imageUrl != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(AppDesign.radiusMD),
            child: Image.network(
              imageUrl.toString(),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image,
                color: AppDesign.secondary,
                size: 30,
              ),
            ),
          )
        : const Icon(
            Icons.image_not_supported_outlined,
            color: AppDesign.secondary,
            size: 30,
          )),
                  ),
                ),
                const SizedBox(width: 10),
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
                      if (type == 'حذاء' && size.trim().isNotEmpty)
                        Text(
                          'مقاس الحذاء: $size',
                          textAlign: TextAlign.right,
                          style: AppDesign.bodySecondaryStyle,
                        )
                      else if (size.trim().isNotEmpty)
                        Text(
                          'المقاس: $size',
                          textAlign: TextAlign.right,
                          style: AppDesign.bodySecondaryStyle,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Positioned(
  top: -5,
  right: 24,
  child: Text(
    'القطعة ${itemIndex + 1}',
    style: AppDesign.subtitleStyle.copyWith(
      color: AppDesign.textPrimary,
      fontWeight: FontWeight.w800,
      fontSize: 15,
    ),
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
          future: _donationDetailsFuture,
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
            final boxData =
                   snapshot.data!['box'] as Map<String, dynamic>;

            final items =
                snapshot.data!['items'] as List<Map<String, dynamic>>;

            final gender = (boxData['gender'] ?? '-').toString();
            final ageGroup = (boxData['ageGroup']?['label'] ?? '-').toString();
            final generalSize = (boxData['generalSize'] ?? '').toString();
            final numberOfItems = items.length;

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
  padding: const EdgeInsets.all(AppDesign.cardPadding),
  decoration: AppDesign.primaryCardDecoration,
  child: Directionality(
    textDirection: TextDirection.rtl,
    child: Column(
      children: [
        _infoRow(
          Icons.wc_outlined,
          "الجنس",
          gender,
        ),

        const SizedBox(height: 12),

        if (ageGroup.contains('بالغون'))
          _infoRow(
            Icons.straighten_outlined,
            "المقاس",
            generalSize.trim().isNotEmpty
                ? generalSize
                : "-",
          )
        else
          _infoRow(
            Icons.cake_outlined,
            "الفئة العمرية",
            ageGroup,
          ),

        const SizedBox(height: 12),

        _infoRow(
          Icons.inventory_2_outlined,
          "عدد القطع",
          "$numberOfItems قطع",
        ),
      ],
    ),
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
                        if (items.isEmpty)
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.all(AppDesign.cardPadding),
                            decoration: AppDesign.primaryCardDecoration,
                            child: Text(
                              'لا توجد قطع مرتبطة بهذا التبرع حالياً',
                              textAlign: TextAlign.center,
                              style: AppDesign.bodyStyle.copyWith(
                                color: AppDesign.textSecondary,
                              ),
                            ),
                          )
                        else
                          ...List.generate(
                          items.length,
                          (index) => _buildItemCard(items[index], index),
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
                      child: ElevatedButton(
                                onPressed: _isAddingToCart
                                    ? null
                                    : () => _addToCart(boxData),

                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [

                                    Text(
                                      _isAddingToCart
                                          ? 'جاري الإضافة...'
                                          : 'إضافة إلى السلة',
                                    ),

                                    const SizedBox(width: 8),

                                    _isAddingToCart
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.add_shopping_cart_outlined),
                                  ],
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
                        gaplessPlayback: true,
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