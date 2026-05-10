import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_design.dart';

class DeliveryMethodPage extends StatefulWidget {
  final String donationId;

  const DeliveryMethodPage({super.key, required this.donationId});

  @override
  State<DeliveryMethodPage> createState() => _DeliveryMethodPageState();
}

class _DeliveryMethodPageState extends State<DeliveryMethodPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _shortAddressController = TextEditingController();

  String? selectedMethod;
  String? selectedCity;
  String? selectedDistrict;

  bool saving = false;

  final double warehouseLat = 24.7554;
  final double warehouseLng = 46.7262;

  final String warehouseName = 'مستودع مدد - واجهة الرياض';
  final String warehouseHours =
      'الأحد - الخميس: 9:00 ص - 5:00 م\nالجمعة والسبت: مغلق';

  final List<String> cities = const [
    'الرياض',
    'جدة',
    'مكة',
    'الدمام',
    'الخبر',
    'المدينة',
  ];

  final List<String> riyadhDistricts = const [
    'الملقا',
    'النرجس',
    'الياسمين',
    'العارض',
    'القيروان',
    'حطين',
    'الصحافة',
    'النخيل',
    'العقيق',
    'الربيع',
    'النفل',
    'الوادي',
    'الغدير',
    'الندى',
    'بنبان',
    'العليا',
    'السليمانية',
    'الورود',
    'الملك فهد',
    'المروج',
    'المصيف',
    'التعاون',
    'النزهة',
    'المغرزات',
    'الازدهار',
    'الواحة',
    'صلاح الدين',
    'المرسلات',
    'الرحمانية',
    'المربع',
    'الديرة',
    'البطحاء',
    'الملز',
    'الفوطة',
    'الشميسي',
    'الصالحية',
    'الوزارات',
    'الضباط',
    'الفاروق',
    'جرير',
    'الرمال',
    'اليرموك',
    'المونسية',
    'النهضة',
    'إشبيلية',
    'الخليج',
    'الملك فيصل',
    'النظيم',
    'قرطبة',
    'السعادة',
    'الجنادرية',
    'النسيم الغربي',
    'النسيم الشرقي',
    'الشهداء',
    'القادسية',
    'المعيزلة',
    'الروضة',
    'السلام',
    'الفيحاء',
    'القدس',
    'غرناطة',
    'الروابي',
    'الأندلس',
    'المنار',
    'الحمراء',
    'الريان',
    'الجزيرة',
    'الندوة',
    'السلي',
    'المشاعل',
    'الزهور',
    'الربوة',
    'العريجاء',
    'العريجاء الغربية',
    'العريجاء الوسطى',
    'ظهرة البديعة',
    'البديعة',
    'السويدي',
    'السويدي الغربي',
    'سلطانة',
    'شبرا',
    'لبن',
    'نمار',
    'طويق',
    'ديراب',
    'الشفا',
    'بدر',
    'المروة',
    'الفواز',
    'الحزم',
    'العزيزية',
    'الدار البيضاء',
    'المصفاة',
    'المنصورة',
    'غبيراء',
    'منفوحة',
    'منفوحة الجديدة',
    'اليمامة',
  ];

  @override
  void dispose() {
    _shortAddressController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateShortAddress(String? value) {
    final text = value?.trim().toUpperCase() ?? '';

    if (text.isEmpty) {
      return 'يرجى إدخال العنوان الوطني المختصر';
    }

    if (!RegExp(r'^[A-Z]{4}[0-9]{4}$').hasMatch(text)) {
      return 'العنوان الوطني المختصر يجب أن يكون 4 حروف إنجليزية ثم 4 أرقام مثل RGHA7923';
    }

    return null;
  }

  Future<void> _openWarehouseMap() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$warehouseLat,$warehouseLng',
    );

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened) {
      _showMessage('تعذر فتح خرائط Google');
    }
  }

  Future<void> _openCitySelector() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppDesign.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDesign.radiusXL),
        ),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: AppPadding.screen,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppDesign.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                AppGap.lg,
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'اختيار المدينة',
                    style: AppDesign.subtitleStyle.copyWith(
                      color: AppDesign.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                AppGap.md,
                ...cities.map((city) {
                  final bool isAvailable = city == 'الرياض';

                  return ListTile(
                    enabled: isAvailable,
                    leading: Icon(
                      isAvailable
                          ? Icons.location_city_outlined
                          : Icons.lock_outline,
                      color: isAvailable
                          ? AppDesign.primary
                          : AppDesign.textSecondary,
                    ),
                    title: Row(
                      children: [
                        Text(
                          city,
                          style: AppDesign.bodyStyle.copyWith(
                            color: isAvailable
                                ? AppDesign.textPrimary
                                : AppDesign.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!isAvailable) ...[
                          AppGap.wSM,
                          Text(
                            'قريبًا',
                            style: AppDesign.captionStyle.copyWith(
                              color: AppDesign.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: selectedCity == city
                        ? const Icon(
                            Icons.check_circle,
                            color: AppDesign.primary,
                          )
                        : null,
                    onTap: isAvailable
                        ? () => Navigator.pop(context, city)
                        : null,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedCity = result;
      });
    }
  }

  Future<void> _openDistrictSearch() async {
    final TextEditingController searchController = TextEditingController();
    List<String> filteredDistricts = List.from(riyadhDistricts);

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppDesign.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDesign.radiusXL),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.78,
                minChildSize: 0.55,
                maxChildSize: 0.95,
                builder: (context, scrollController) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: AppDesign.screenPadding,
                      right: AppDesign.screenPadding,
                      top: AppDesign.screenPadding,
                      bottom:
                          MediaQuery.of(context).viewInsets.bottom +
                          AppDesign.screenPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppDesign.border,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        AppGap.lg,

                        Text(
                          'اختيار الحي',
                          style: AppDesign.subtitleStyle.copyWith(
                            color: AppDesign.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        AppGap.md,

                        TextField(
                          controller: searchController,
                          autofocus: false,
                          decoration: const InputDecoration(
                            labelText: 'ابحث باسم الحي',
                            hintText: 'مثال: المل',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            setModalState(() {
                              final query = value.trim();

                              filteredDistricts = query.isEmpty
                                  ? List.from(riyadhDistricts)
                                  : riyadhDistricts
                                        .where(
                                          (district) =>
                                              district.contains(query),
                                        )
                                        .toList();
                            });
                          },
                        ),

                        AppGap.md,

                        Expanded(
                          child: filteredDistricts.isEmpty
                              ? Center(
                                  child: Text(
                                    'لا توجد نتائج مطابقة',
                                    style: AppDesign.bodySecondaryStyle,
                                  ),
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  itemCount: filteredDistricts.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final district = filteredDistricts[index];

                                    return ListTile(
                                      title: Text(
                                        district,
                                        textAlign: TextAlign.right,
                                        style: AppDesign.bodyStyle.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      trailing: selectedDistrict == district
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: AppDesign.primary,
                                            )
                                          : null,
                                      onTap: () {
                                        FocusScope.of(context).unfocus();

                                        Future.delayed(
                                          const Duration(milliseconds: 100),
                                          () {
                                            if (!mounted) return;

                                            Navigator.pop(context, district);
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );

    searchController.dispose();

    if (result != null) {
      setState(() {
        selectedDistrict = result;
      });
    }
  }

  Future<void> _saveMethod() async {
    if (selectedMethod == null) {
      _showMessage('اختر طريقة التوصيل أولاً');
      return;
    }

    if (selectedMethod == 'pickup') {
      if (selectedCity == null) {
        _showMessage('يرجى اختيار المدينة');
        return;
      }

      if (selectedDistrict == null) {
        _showMessage('يرجى اختيار الحي');
        return;
      }

      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    try {
      setState(() => saving = true);

      final donationRef = FirebaseFirestore.instance
          .collection('donations')
          .doc(widget.donationId);

      await donationRef.update({
        'status': 'published',
        'deliveryMethod': selectedMethod,
        'city': selectedMethod == 'pickup' ? selectedCity : null,
        'district': selectedMethod == 'pickup' ? selectedDistrict : null,
        'shortNationalAddress': selectedMethod == 'pickup'
            ? _shortAddressController.text.trim().toUpperCase()
            : null,
        'warehouseName': selectedMethod == 'self_delivery'
            ? warehouseName
            : null,
        'warehouseLat': selectedMethod == 'self_delivery' ? warehouseLat : null,
        'warehouseLng': selectedMethod == 'self_delivery' ? warehouseLng : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final boxesSnapshot = await FirebaseFirestore.instance
          .collection('donation_boxes')
          .where('donationId', isEqualTo: widget.donationId)
          .get();

      for (final boxDoc in boxesSnapshot.docs) {
        final data = boxDoc.data();
        final boxNumber = data['boxNumber'] ?? 0;

        final shortId = boxDoc.id.substring(0, 5).toUpperCase();
        final boxCode = "BOX$boxNumber-$shortId";

        await boxDoc.reference.update({
          'status': 'published',
          'boxCode': boxCode,
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تأكيد التبرع بنجاح'),
          backgroundColor: AppDesign.success,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 800));

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/viewDonation',
        (route) => false,
        arguments: FirebaseAuth.instance.currentUser?.uid ?? '',
      );
    } catch (e) {
      _showMessage('فشل الحفظ: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _methodCard({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = selectedMethod == value;

    return InkWell(
      onTap: () => setState(() => selectedMethod = value),
      borderRadius: BorderRadius.circular(AppDesign.radiusLG),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppDesign.cardPadding),
        decoration: BoxDecoration(
          color: selected
              ? AppDesign.primary.withOpacity(0.08)
              : AppDesign.white,
          borderRadius: BorderRadius.circular(AppDesign.radiusLG),
          border: Border.all(
            color: selected ? AppDesign.primary : AppDesign.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: selectedMethod,
              activeColor: AppDesign.primary,
              onChanged: (newValue) {
                setState(() => selectedMethod = newValue);
              },
            ),
            Icon(icon, color: AppDesign.primary),
            AppGap.wMD,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppDesign.subtitleStyle.copyWith(
                      color: AppDesign.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppGap.xs,
                  Text(
                    subtitle,
                    style: AppDesign.captionStyle.copyWith(
                      color: AppDesign.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectorBox({
    required String title,
    required String placeholder,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDesign.radiusLG),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesign.spaceMD,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: AppDesign.white,
          borderRadius: BorderRadius.circular(AppDesign.radiusLG),
          border: Border.all(color: AppDesign.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppDesign.primary),
            AppGap.wMD,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppDesign.captionStyle.copyWith(
                      color: AppDesign.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppGap.xs,
                  Text(
                    value ?? placeholder,
                    style: AppDesign.bodyStyle.copyWith(
                      color: value == null
                          ? AppDesign.textSecondary
                          : AppDesign.textPrimary,
                      fontWeight: value == null
                          ? FontWeight.w400
                          : FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppDesign.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickupSection() {
    return Form(
      key: _formKey,
      child: Container(
        margin: const EdgeInsets.only(top: AppDesign.spaceMD),
        padding: const EdgeInsets.all(AppDesign.cardPadding),
        decoration: AppDesign.primaryCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'بيانات الاستلام',
              style: AppDesign.subtitleStyle.copyWith(
                color: AppDesign.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            AppGap.sm,
            Text(
              'سيتم التواصل معك خلال 3 - 4 أيام عمل لتنسيق موعد الاستلام.',
              style: AppDesign.bodySecondaryStyle,
            ),
            AppGap.lg,
            _selectorBox(
              title: 'المدينة',
              placeholder: 'اختاري المدينة',
              value: selectedCity,
              icon: Icons.location_city_outlined,
              onTap: _openCitySelector,
            ),
            AppGap.md,
            _selectorBox(
              title: 'الحي',
              placeholder: 'اختاري الحي',
              value: selectedDistrict,
              icon: Icons.map_outlined,
              onTap: _openDistrictSearch,
            ),
            AppGap.md,
            TextFormField(
              controller: _shortAddressController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
              validator: _validateShortAddress,
              decoration: const InputDecoration(
                labelText: 'العنوان الوطني المختصر',
                hintText: 'مثال: RGHA7923',
                prefixIcon: Icon(Icons.badge_outlined),
                counterText: '',
              ),
              onChanged: (value) {
                final upper = value.toUpperCase();
                if (value != upper) {
                  _shortAddressController.value = _shortAddressController.value
                      .copyWith(
                        text: upper,
                        selection: TextSelection.collapsed(
                          offset: upper.length,
                        ),
                      );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _selfDeliverySection() {
    return Container(
      margin: const EdgeInsets.only(top: AppDesign.spaceMD),
      padding: const EdgeInsets.all(AppDesign.cardPadding),
      decoration: AppDesign.primaryCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'موقع المستودع',
            style: AppDesign.subtitleStyle.copyWith(
              color: AppDesign.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          AppGap.sm,
          Text(
            warehouseName,
            style: AppDesign.bodyStyle.copyWith(fontWeight: FontWeight.w700),
          ),
          AppGap.md,
          Text(
            'ساعات العمل الرسمية',
            style: AppDesign.subtitleStyle.copyWith(
              color: AppDesign.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          AppGap.xs,
          Text(warehouseHours, style: AppDesign.bodySecondaryStyle),
          AppGap.lg,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openWarehouseMap,
              icon: const Icon(Icons.map_outlined),
              label: const Text('فتح موقع المستودع في Google Maps'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDesign.cardPadding),
      decoration: AppDesign.softCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'طريقة تسليم التبرع',
            style: AppDesign.h1Style.copyWith(
              color: AppDesign.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          AppGap.xs,
          Text(
            'اختار الطريقة المناسبة لإيصال التبرع إلى مستودع مدد.',
            style: AppDesign.bodySecondaryStyle,
          ),
        ],
      ),
    );
  }

  void _goBackToDrafts() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: WillPopScope(
        onWillPop: () async {
          _goBackToDrafts();
          return false;
        },
        child: Scaffold(
          backgroundColor: AppDesign.background,
          appBar: AppBar(
            title: const Text('طريقة التوصيل'),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goBackToDrafts,
            ),
          ),
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
            child: SingleChildScrollView(
              padding: AppPadding.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  AppGap.xl,
                  _methodCard(
                    value: 'pickup',
                    title: 'استلام من موقعي',
                    subtitle: '',
                    icon: Icons.local_shipping_outlined,
                  ),
                  if (selectedMethod == 'pickup') _pickupSection(),
                  AppGap.md,
                  _methodCard(
                    value: 'self_delivery',
                    title: 'توصيل ذاتي للمستودع',
                    subtitle:
                        'يمكنك إيصال التبرع بنفسك إلى المستودع خلال ساعات العمل.',
                    icon: Icons.storefront_outlined,
                  ),
                  if (selectedMethod == 'self_delivery') _selfDeliverySection(),
                  AppGap.xl,
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving ? null : _saveMethod,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          saving ? 'جاري الحفظ...' : 'تأكيد طريقة التوصيل',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
