import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'app_design.dart';

class EditDonationPage extends StatefulWidget {
  final String donationId;
  final String? initialGender;
  final String? initialAgeGroupLabel;
  final int initialItemCount;
  final Map<int, List<Map<String, dynamic>>>? initialBoxes;

  const EditDonationPage({
    super.key,
    required this.donationId,
    this.initialGender,
    this.initialAgeGroupLabel,
    required this.initialItemCount,
    this.initialBoxes,
  });

  @override
  State<EditDonationPage> createState() => _EditDonationPageState();
}

class _EditDonationPageState extends State<EditDonationPage> {
  bool inputsLocked = false;
  bool isLoadingBoxes = true;

  String? selectedGender;
  Map<String, dynamic>? selectedAgeGroup;

  final TextEditingController _itemCountController = TextEditingController();

  final String _apiKey = 'AIzaSyAW2Lf2LnCgUyrMoBQ6fK9qwmrveCUf6CE';
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  int totalItems = 0;
  int totalBoxes = 0;
  int? openedBox;

  Map<int, List<Map<String, dynamic>>> boxes = {};
  Set<int> savedBoxes = {};

  final List<Map<String, dynamic>> ageGroups = [
    {'label': 'رضّع (0-2)', 'min': 0, 'max': 2},
    {'label': 'أطفال صغار (3-5)', 'min': 3, 'max': 5},
    {'label': 'أطفال (6-9)', 'min': 6, 'max': 9},
    {'label': 'أطفال (10-12)', 'min': 10, 'max': 12},
    {'label': 'مراهقون (13-17)', 'min': 13, 'max': 17},
    {'label': 'بالغون (18+)', 'min': 18, 'max': 120},
  ];

  Map<String, dynamic>? _findAgeGroupByLabel(String? label) {
    if (label == null || label.trim().isEmpty) return null;

    try {
      return ageGroups.firstWhere(
        (age) => age['label'].toString().trim() == label.trim(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();

    selectedGender = widget.initialGender;
    selectedAgeGroup = _findAgeGroupByLabel(widget.initialAgeGroupLabel);

    totalItems = widget.initialItemCount;
    _itemCountController.text =
        widget.initialItemCount == 0 ? '' : widget.initialItemCount.toString();

    if (widget.initialBoxes != null && widget.initialBoxes!.isNotEmpty) {
      boxes = Map<int, List<Map<String, dynamic>>>.from(
        widget.initialBoxes!.map(
          (key, value) => MapEntry(
            key,
            value.map((item) => Map<String, dynamic>.from(item)).toList(),
          ),
        ),
      );
      totalBoxes = boxes.length;
      savedBoxes = boxes.keys.toSet();
      isLoadingBoxes = false;
    } else {
      if (widget.initialItemCount > 0) {
        _updateItemCount(widget.initialItemCount.toString());
      }
      _loadDonationBoxes();
    }
  }

  @override
  void dispose() {
    _itemCountController.dispose();
    super.dispose();
  }

  Future<void> _loadDonationBoxes() async {
    try {
      final snapshot = await firestore
          .collection('donation_boxes')
          .where('donationId', isEqualTo: widget.donationId)
          .get();

      final Map<int, List<Map<String, dynamic>>> loadedBoxes = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final int boxNumber = (data['boxNumber'] ?? 0) as int;
        final List<dynamic> items = data['items'] ?? [];

        loadedBoxes[boxNumber] = items.map((item) {
          final map = Map<String, dynamic>.from(item);

          Uint8List? imageBytes;
          if (map['imageBase64'] != null &&
              map['imageBase64'].toString().isNotEmpty) {
            try {
              imageBytes = base64Decode(map['imageBase64']);
            } catch (_) {
              imageBytes = null;
            }
          }

          return {
            'image': imageBytes,
            'type': map['type'],
            'isValid': imageBytes != null,
            'error': null,
          };
        }).toList();
      }

      if (!mounted) return;

      setState(() {
        if (loadedBoxes.isNotEmpty) {
          boxes = loadedBoxes;
          totalBoxes = loadedBoxes.length;
          savedBoxes = loadedBoxes.keys.toSet();
        }
        isLoadingBoxes = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingBoxes = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحميل محتوى التبرع: $e')),
      );
    }
  }

  void _updateItemCount(String value) {
    if (value.isEmpty) {
      setState(() {
        totalItems = 0;
        totalBoxes = 0;
        boxes = {};
        savedBoxes.clear();
        openedBox = null;
      });
      return;
    }

    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) return;

    totalItems = parsed;
    totalBoxes = (totalItems / 5).ceil();

    final Map<int, List<Map<String, dynamic>>> newBoxes = {};
    int remainingItems = totalItems;

    for (int i = 1; i <= totalBoxes; i++) {
      final itemsInThisBox = remainingItems >= 5 ? 5 : remainingItems;

      if (boxes.containsKey(i)) {
        final existing = boxes[i]!;
        if (existing.length == itemsInThisBox) {
          newBoxes[i] = existing;
        } else if (existing.length > itemsInThisBox) {
          newBoxes[i] = existing.take(itemsInThisBox).toList();
        } else {
          final extra = List.generate(
            itemsInThisBox - existing.length,
            (_) => {
              'image': null,
              'type': null,
              'isValid': false,
              'error': null,
            },
          );
          newBoxes[i] = [...existing, ...extra];
        }
      } else {
        newBoxes[i] = List.generate(
          itemsInThisBox,
          (_) => {
            'image': null,
            'type': null,
            'isValid': false,
            'error': null,
          },
        );
      }

      remainingItems -= itemsInThisBox;
    }

    setState(() {
      boxes = newBoxes;
      savedBoxes.removeWhere((boxNumber) => boxNumber > totalBoxes);
    });
  }

  Future<void> _pickItemImage(int box, int index) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        boxes[box]![index]['image'] = bytes;
      });
      _verifyImageWithGemini(box, index, bytes);
    }
  }

  Future<void> _verifyImageWithGemini(
    int box,
    int index,
    Uint8List imageBytes,
  ) async {
    setState(() {
      boxes[box]![index]['error'] = "جاري الفحص...";
    });

    if (_apiKey.trim().isEmpty) {
      setState(() {
        boxes[box]![index]['isValid'] = true;
        boxes[box]![index]['error'] = null;
      });
      return;
    }

    final String url =
        'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$_apiKey';

    try {
      final String base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "Check if this is a valid photo of a clothing item or a bag. Answer 'Yes' or 'No' only."
                },
                {
                  "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": base64Image
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String result =
            data['candidates'][0]['content']['parts'][0]['text'];

        setState(() {
          if (result.trim().toLowerCase().contains("yes")) {
            boxes[box]![index]['isValid'] = true;
            boxes[box]![index]['error'] = null;
          } else {
            boxes[box]![index]['image'] = null;
            boxes[box]![index]['type'] = null;
            boxes[box]![index]['isValid'] = false;
            boxes[box]![index]['error'] = null;
          }
        });
      } else {
        setState(() {
          boxes[box]![index]['error'] = "فشل الفحص: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        boxes[box]![index]['error'] = "فشل الفحص: $e";
      });
    }
  }

  bool _isAllDataComplete() {
    if (selectedGender == null || selectedAgeGroup == null) return false;
    if (boxes.isEmpty) return false;

    for (final boxItems in boxes.values) {
      for (final item in boxItems) {
        if (item['image'] == null ||
            item['type'] == null ||
            item['isValid'] != true) {
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _saveChanges() async {
    if (!_isAllDataComplete()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إكمال جميع الحقول والقطع أولاً')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حفظ التغييرات'),
        content: const Text('هل أنت متأكد من حفظ جميع التغييرات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await firestore.collection('donations').doc(widget.donationId).update({
        'gender': selectedGender,
        'ageGroup': selectedAgeGroup!['label'],
        'numberOfItems': totalItems,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final oldBoxes = await firestore
          .collection('donation_boxes')
          .where('donationId', isEqualTo: widget.donationId)
          .get();

      for (final doc in oldBoxes.docs) {
        await doc.reference.delete();
      }

      for (final entry in boxes.entries) {
        final int boxNumber = entry.key;
        final List<Map<String, dynamic>> items = entry.value;

        await firestore.collection('donation_boxes').add({
          'donationId': widget.donationId,
          'boxNumber': boxNumber,
          'gender': selectedGender,
          'ageGroup': {
            'label': selectedAgeGroup!['label'],
            'min': selectedAgeGroup!['min'],
            'max': selectedAgeGroup!['max'],
          },
          'items': items.map((e) {
            return {
              'type': e['type'],
              'imageBase64': e['image'] != null
                  ? base64Encode(e['image'] as Uint8List)
                  : '',
            };
          }).toList(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التغييرات بنجاح')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حفظ التغييرات: $e')),
      );
    }
  }

  Widget _buildTopInfoCard() {
    return Container(
      width: double.infinity,
      padding: AppPadding.card,
      decoration: AppDesign.primaryCardDecoration,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppDesign.surfaceAlt,
              shape: BoxShape.circle,
              border: Border.all(color: AppDesign.border),
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: AppDesign.primary,
              size: AppDesign.iconMD,
            ),
          ),
          AppGap.wMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'تعديل التبرع',
                  textAlign: TextAlign.right,
                  style: AppDesign.h2Style.copyWith(
                    color: AppDesign.primary,
                  ),
                ),
                AppGap.xs,
                Text(
                  'يمكنك تعديل بيانات التبرع والصناديق ثم حفظ التغييرات.',
                  textAlign: TextAlign.right,
                  style: AppDesign.bodySecondaryStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoxTile(int boxNum) {
    return GestureDetector(
      onTap: () {
        setState(() {
          openedBox = boxNum;
          inputsLocked = true;
        });
      },
      child: Container(
        decoration: AppDesign.primaryCardDecoration.copyWith(
          color: AppDesign.surface,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                color: AppDesign.primary,
                size: AppDesign.iconLG,
              ),
              AppGap.sm,
              Text(
                "صندوق $boxNum",
                style: AppDesign.bodyStyle.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              AppGap.xs,
              Text(
                "${boxes[boxNum]?.length ?? 0} قطع",
                style: AppDesign.captionStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(int idx, Map<String, dynamic> item) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.radiusMD),
        side: BorderSide(
          color: item['error'] != null ? AppDesign.error : AppDesign.border,
          width: 1.2,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: AppDesign.spaceSM),
      child: Padding(
        padding: AppPadding.card,
        child: Column(
          children: [
            Text(
              "القطعة رقم ${idx + 1}",
              style: AppDesign.subtitleStyle.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            AppGap.sm,
            Row(
              children: [
                GestureDetector(
                  onTap: () => _pickItemImage(openedBox!, idx),
                  child: Container(
                    height: 104,
                    width: 104,
                    decoration: BoxDecoration(
                      color: AppDesign.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppDesign.radiusSM),
                      border: Border.all(color: AppDesign.border),
                    ),
                    child: item['image'] == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.upload_file_rounded,
                                color: AppDesign.primary,
                                size: AppDesign.iconLG,
                              ),
                              AppGap.xs,
                              Text(
                                "انقر لرفع الصورة",
                                textAlign: TextAlign.center,
                                style: AppDesign.captionStyle.copyWith(
                                  color: AppDesign.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppDesign.radiusSM),
                            child: Image.memory(
                              item['image'] as Uint8List,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
                AppGap.wMD,
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: item['type'] as String?,
                    decoration: const InputDecoration(
                      labelText: "نوع القطعة",
                    ),
                    items: const [
                      "قميص",
                      "بنطلون",
                      "فستان",
                      "معطف",
                      "حذاء",
                      "حقيبة",
                      "قبعة"
                    ]
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(e),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() {
                      boxes[openedBox]![idx]['type'] = v;
                    }),
                  ),
                ),
              ],
            ),
            if (item['error'] != null) ...[
              AppGap.sm,
              Text(
                item['error'] ?? '',
                style: AppDesign.captionStyle.copyWith(
                  color: AppDesign.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'تعديل التبرع',
            style: AppDesign.h2Style.copyWith(
              color: AppDesign.textPrimary,
            ),
          ),
          centerTitle: true,
          backgroundColor: AppDesign.background,
          foregroundColor: AppDesign.textPrimary,
        ),
        backgroundColor: AppDesign.background,
        body: isLoadingBoxes
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: AppPadding.screen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopInfoCard(),
                    AppGap.section,

                    DropdownButtonFormField<String>(
                      value: selectedGender,
                      decoration: InputDecoration(
                        labelText: "الجنس",
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: AppDesign.primary,
                        ),
                        fillColor: openedBox == null
                            ? AppDesign.surface
                            : AppDesign.surfaceAlt,
                      ),
                      items: ["ذكر", "أنثى"]
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e),
                            ),
                          )
                          .toList(),
                      onChanged: openedBox != null
                          ? null
                          : (v) => setState(() => selectedGender = v),
                    ),
                    AppGap.lg,

                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: selectedAgeGroup,
                      decoration: InputDecoration(
                        labelText: "الفئة العمرية",
                        prefixIcon: const Icon(
                          Icons.cake_outlined,
                          color: AppDesign.primary,
                        ),
                        fillColor: openedBox == null
                            ? AppDesign.surface
                            : AppDesign.surfaceAlt,
                      ),
                      items: ageGroups.map((age) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: age,
                          child: Text(age['label']),
                        );
                      }).toList(),
                      onChanged: openedBox != null
                          ? null
                          : (v) => setState(() => selectedAgeGroup = v),
                    ),
                    AppGap.lg,

                    TextField(
                      controller: _itemCountController,
                      keyboardType: TextInputType.number,
                      onChanged: inputsLocked ? null : _updateItemCount,
                      enabled: !inputsLocked,
                      decoration: InputDecoration(
                        labelText: "إجمالي عدد القطع",
                        prefixIcon: const Icon(
                          Icons.format_list_numbered_rounded,
                          color: AppDesign.primary,
                        ),
                        fillColor: openedBox == null
                            ? AppDesign.surface
                            : AppDesign.surfaceAlt,
                      ),
                    ),
                    AppGap.section,

                    if (totalBoxes > 0 && openedBox == null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "اختر صندوقًا لتعديل محتواه:",
                            style: AppDesign.subtitleStyle.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          AppGap.md,
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: totalBoxes,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: AppDesign.spaceMD,
                              crossAxisSpacing: AppDesign.spaceMD,
                              childAspectRatio: 1,
                            ),
                            itemBuilder: (context, idx) {
                              final boxNum = idx + 1;
                              return _buildBoxTile(boxNum);
                            },
                          ),
                        ],
                      ),

                    if (openedBox != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    openedBox = null;
                                    inputsLocked = false;
                                  });
                                },
                                icon: const Icon(Icons.arrow_back),
                                label: const Text("رجوع"),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    "الصندوق رقم $openedBox",
                                    style: AppDesign.h2Style.copyWith(
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 70),
                            ],
                          ),
                          AppGap.sm,
                          ...boxes[openedBox]!
                              .asMap()
                              .entries
                              .map((entry) => _buildItemCard(entry.key, entry.value)),
                        ],
                      ),

                    AppGap.section,
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        child: const Text("حفظ التغييرات"),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
