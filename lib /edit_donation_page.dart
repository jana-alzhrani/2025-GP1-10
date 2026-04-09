import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class EditDonationPage extends StatefulWidget {
  final String donationId;
  final String? initialGender;
  final Map<String, dynamic>? initialAgeGroup;
  final int initialItemCount;
  final Map<int, List<Map<String, dynamic>>>? initialBoxes;

  const EditDonationPage({
    super.key,
    required this.donationId,
    this.initialGender,
    this.initialAgeGroup,
    required this.initialItemCount,
    this.initialBoxes,
  });

  @override
  State<EditDonationPage> createState() => _EditDonationPageState();
}

class _EditDonationPageState extends State<EditDonationPage> {
  bool inputsLocked = false;

  String? selectedGender;
  Map<String, dynamic>? selectedAgeGroup;

  final TextEditingController _itemCountController = TextEditingController();

  final String _apiKey = '';
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

  @override
  void initState() {
    super.initState();

    selectedGender = widget.initialGender;
    selectedAgeGroup = widget.initialAgeGroup;
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
    } else if (widget.initialItemCount > 0) {
      _updateItemCount(widget.initialItemCount.toString());
    }

    savedBoxes = boxes.keys.toSet();
  }

  @override
  void dispose() {
    _itemCountController.dispose();
    super.dispose();
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
      int box, int index, Uint8List imageBytes) async {
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
        'ageGroup': {
          'label': selectedAgeGroup!['label'],
          'min': selectedAgeGroup!['min'],
          'max': selectedAgeGroup!['max'],
        },
        'numberOfItems': totalItems,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التغييرات بنجاح')),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حفظ التغييرات: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF123A66);
    const secondaryColor = Color(0xFF8ED0F8);
    const lightBlue = Color(0xFFDFF4FF);
    const pageBackground = Color(0xFFF6FBFF);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBackground,
        appBar: AppBar(
          title: const Text("تعديل التبرع"),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: primaryColor,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "الجنس",
                  prefixIcon: const Icon(Icons.person, color: primaryColor),
                  filled: true,
                  fillColor: openedBox == null ? Colors.white : Colors.grey[200],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide:
                        const BorderSide(color: lightBlue, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide:
                        const BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                items: ["ذكر", "أنثى"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => selectedGender = v),
                value: selectedGender,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<Map<String, dynamic>>(
                decoration: InputDecoration(
                  labelText: "الفئة العمرية",
                  prefixIcon: const Icon(Icons.cake, color: primaryColor),
                  filled: true,
                  fillColor: openedBox == null ? Colors.white : Colors.grey[200],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide:
                        const BorderSide(color: lightBlue, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide:
                        const BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                items: ageGroups.map((age) {
                  return DropdownMenuItem(
                    value: age,
                    child: Text(age['label']),
                  );
                }).toList(),
                onChanged: (v) => setState(() => selectedAgeGroup = v),
                value: selectedAgeGroup,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _itemCountController,
                keyboardType: TextInputType.number,
                onChanged: inputsLocked ? null : _updateItemCount,
                enabled: !inputsLocked,
                decoration: InputDecoration(
                  labelText: "إجمالي عدد القطع",
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  filled: true,
                  fillColor: openedBox == null ? Colors.white : Colors.grey[200],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: openedBox == null ? lightBlue : Colors.grey,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (totalBoxes > 0 && openedBox == null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "اختر صندوقًا لتعديل محتواه:",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: totalBoxes,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, idx) {
                        final boxNum = idx + 1;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              openedBox = boxNum;
                              inputsLocked = true;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [lightBlue, secondaryColor],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: primaryColor,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.inventory_2,
                                    color: primaryColor,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "صندوق $boxNum",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    "${boxes[boxNum]?.length ?? 0} قطع",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              if (openedBox != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              openedBox = null;
                            });
                          },
                          icon: const Icon(Icons.arrow_back,
                              color: primaryColor),
                          label: const Text(
                            "رجوع",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              "الصندوق رقم $openedBox",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 70),
                      ],
                    ),
                    ...boxes[openedBox]!.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;

                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: item['error'] != null
                                ? Colors.red
                                : primaryColor,
                            width: 1.5,
                          ),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              Text("القطعة رقم ${idx + 1}"),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _pickItemImage(openedBox!, idx),
                                    child: Container(
                                      height: 100,
                                      width: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                      child: item['image'] == null
                                          ? Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Icon(
                                                  Icons.upload_file,
                                                  color: primaryColor,
                                                  size: 36,
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  "انقر لرفع الصورة",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: primaryColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.memory(
                                                item['image'],
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: DropdownButton<String>(
                                      hint: const Text("نوع القطعة"),
                                      value: item['type'],
                                      items: [
                                        "قميص",
                                        "بنطلون",
                                        "فستان",
                                        "معطف",
                                        "حذاء",
                                        "حقيبة",
                                        "قبعة"
                                      ]
                                          .map(
                                            (e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(e),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) => setState(() {
                                        boxes[openedBox]![idx]['type'] = v;
                                      }),
                                      isExpanded: true,
                                    ),
                                  ),
                                ],
                              ),
                              if (item['error'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    item['error'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _saveChanges,
                  child: const Text(
                    "حفظ التغييرات",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
  
}
