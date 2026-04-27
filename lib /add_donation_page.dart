import 'dart:convert';

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;


import 'package:image_picker/image_picker.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_design.dart';


class AddDonationPage extends StatefulWidget {

  const AddDonationPage({super.key});



  @override

  State<AddDonationPage> createState() => _AddDonationPageState();

}



class _AddDonationPageState extends State<AddDonationPage> {
bool inputsLocked = false; 
  String? selectedGender;
String? donationId;
  Map<String, dynamic>? selectedAgeGroup;

  final TextEditingController _itemCountController = TextEditingController();

  final String _apiKey = ''; 
  final FirebaseFirestore firestore = FirebaseFirestore.instance;




  int totalItems = 0;

  int totalBoxes = 0;

  int? openedBox;



  Map<int, List<Map<String, dynamic>>> boxes = {};

  Set<int> savedBoxes = {};
  Map<int, String> boxCodes = {}; // ⭐️ جديد


final List<Map<String, dynamic>> ageGroups = [

  {'label': 'رضّع (0-2)', 'min': 0, 'max': 2},

  {'label': 'أطفال صغار (3-5)', 'min': 3, 'max': 5},

  {'label': 'أطفال (6-9)', 'min': 6, 'max': 9},

  {'label': 'أطفال  (10-12)', 'min': 10, 'max': 12},

  {'label': 'مراهقون (13-17)', 'min': 13, 'max': 17},

  {'label': 'بالغون (18+)', 'min': 18, 'max': 120},

];

String? generalSize;

bool ageNeedsSize() {
  if (selectedAgeGroup == null) return false;
  return selectedAgeGroup!['min'] >= 13;
}

  bool needsSize(String? type) {
    return ["قميص", "بنطلون", "فستان", "معطف"].contains(type);
  }

  bool isShoe(String? type) => type == "حذاء";

Map<String, String> typeMap = {
  "shirt": "قميص",
  "pants": "بنطلون",
  "dress": "فستان",
  "coat": "معطف",
  "shoe": "حذاء",
  "bag": "حقيبة",
  "hat": "قبعة",
};

  void _updateItemCount(String value) {

    if (value.isEmpty) {

      setState(() {

        totalItems = 0;

        totalBoxes = 0;

        boxes = {};

      });

      return;

    }

    int? parsed = int.tryParse(value);

    if (parsed == null || parsed <= 0) return;



    totalItems = parsed;

    totalBoxes = (totalItems / 5).ceil();

    boxes = {};

    int remainingItems = totalItems;



    for (int i = 1; i <= totalBoxes; i++) {

      int itemsInThisBox = remainingItems >= 5 ? 5 : remainingItems;

      boxes[i] = List.generate(

        itemsInThisBox,

        (index) => {

          'image': null,

          'type': null,

          'size': null,

          'isValid': false,

          'error': null,

        },

      );

      remainingItems -= itemsInThisBox;

    }

    setState(() {});

  }
  
String generateBoxCode(String boxId, int boxNumber) {
  final shortId = boxId.length >= 5
      ? boxId.substring(0, 5)
      : boxId;

  return "BX-${boxNumber.toString().padLeft(2, '0')}-${shortId.toUpperCase()}";
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
  

bool canOpenBox() {
    if (selectedGender == null) return false;
    if (selectedAgeGroup == null) return false;

    if (ageNeedsSize() && generalSize == null) {
      return false;
    }

    return true;
  }

  Future<void> _verifyImageWithGemini(int box, int index, Uint8List imageBytes) async {

    setState(() {

      boxes[box]![index]['error'] = "جاري الفحص...";

    });



    final String url =

        'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$_apiKey';



    try {

      String base64Image = base64Encode(imageBytes);

      final response = await http.post(

        Uri.parse(url),

        headers: {'Content-Type': 'application/json'},

        body: jsonEncode({

          "contents": [

            {

              "parts": [

                {

            "text": """
Check the image.

If it is a valid clothing item or bag, answer in this format:
Yes - [Type]

Types must be one of:
Shirt, Pants, Dress, Coat, Shoe, Bag, Hat

If invalid, answer:
No

Reject if:
- completely black
- blurry
- not clothing or bag
"""

                },

                {"inline_data": {"mime_type": "image/jpeg", "data": base64Image}}

              ]

            }

          ]

        }),

      );



      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        String result = data['candidates'][0]['content']['parts'][0]['text'];



      setState(() {
  String cleaned = result.trim().toLowerCase();

  if (cleaned.startsWith("yes")) {

    String? detectedType;

    // استخراج النوع
    if (cleaned.contains("-")) {
      String typeEng = cleaned.split("-")[1].trim();
      detectedType = typeMap[typeEng];
    }

    boxes[box]![index]['isValid'] = true;
    boxes[box]![index]['error'] = null;

    // تعيين النوع تلقائي
    if (detectedType != null && boxes[box]![index]['type'] == null) {
      boxes[box]![index]['type'] = detectedType;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("الصورة صالحة"),
        backgroundColor: Colors.green,
      ),
    );

  } else {

    boxes[box]![index]['image'] = null;
    boxes[box]![index]['type'] = null;
    boxes[box]![index]['isValid'] = false;
    boxes[box]![index]['size'] = null;
    boxes[box]![index]['error'] = null;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("الصورة غير صالحة!"),
        backgroundColor: Colors.red,
      ),
    );
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


Future<void> createDonationIfNeeded() async {
  if (donationId != null) return;

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final doc = await firestore.collection('donations').add({
    'donorID': user.uid,
    'gender': selectedGender ?? "",
    'ageGroup': selectedAgeGroup != null
        ? selectedAgeGroup!['label']
        : "",
    'numberOfItems': totalItems,
    'status': 'draft',
    'createdAt': FieldValue.serverTimestamp(),
  });

  donationId = doc.id;
  print("NEW donationId => $donationId");
}

bool validateBoxBeforeSave(int box) {
  final items = boxes[box]!;

  for (var item in items) {
    if (item['image'] == null) return false;
    if (item['type'] == null) return false;
    if (item['isValid'] != true) return false;

    if (item['type'] == "حذاء" && item['size'] == null) {
      return false;
    }
  }

  return true;
}
  Future<void> _submitBox(int box) async {
    if (!validateBoxBeforeSave(box)) {
  ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إكمال جميع الحقول')),
      );
  return;
}
  final items = boxes[box]!;

  bool incomplete = items.any(
  (item) =>
      item['image'] == null ||
      item['type'] == null ||
      !item['isValid'] ||
      (item['type'] == "حذاء" && item['size'] == null)
);

  // عرض نافذة التأكيد
  bool confirm = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("تأكيد الحفظ"),
      content: const Text("هل أنت متأكد من حفظ هذا الصندوق؟"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("إلغاء"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("نعم"),
        ),
      ],
    ),
  );

  if (!confirm) return; // إذا ضغط إلغاء ما نسوي شي

  try {
    // حفظ الصندوق في Firestore
    final user = FirebaseAuth.instance.currentUser;


if (user == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("يجب تسجيل الدخول أولاً")),
  );
  return;
}


    await createDonationIfNeeded();


    await firestore.collection('donation_boxes').add({
  'donationId': donationId,
  'userId': user.uid,
  'boxNumber': box,
  'gender': selectedGender,
  'ageGroup': {
    'label': selectedAgeGroup!['label'],
    'min': selectedAgeGroup!['min'],
    'max': selectedAgeGroup!['max'],
  },

  //  المقاس العام للملابس
  'generalSize': generalSize,

  'items': items.map((e) {
    return {
      'type': e['type'],
      'size': e['type'] == "حذاء" ? e['size'] : null,
      'imageBase64': base64Encode(e['image']),
    };
  }).toList(),

  'timestamp': FieldValue.serverTimestamp(),
});

    final boxId = docRef.id;

// توليد الكود من boxId
final boxCode = generateBoxCode(boxId, box);

// تحديث نفس الدوكيومنت
await docRef.update({
  'boxCode': boxCode,
});

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("تم حفظ الصندوق $box ✅")));

    setState(() {
      boxes[box] = List.generate(
        boxes[box]!.length,
        (index) => {'image': null, 'type': null,  'size': null, 'isValid': false, 'error': null},
      );
      savedBoxes.add(box);
      openedBox = null;
    });
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("فشل الحفظ: $e")));
  }
}

  bool allBoxesSaved() {

    return savedBoxes.length == totalBoxes;

  }


  /** */
void _showExitDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text("تأكيد الخروج"),
      content: const Text(
        "هل أنتِ متأكدة من الخروج؟ لن يتم حفظ التبرعات الحالية.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("إلغاء"),
        ),

        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);

            final user = FirebaseAuth.instance.currentUser;

            if (donationId != null) {
              await FirebaseFirestore.instance
                  .collection('donations')
                  .doc(donationId)
                  .delete();
            }

            Navigator.pushNamedAndRemoveUntil(
              context,
              '/donorHome',
              (route) => false,
              arguments: user?.email ?? '',
            );
          },
          child: const Text("خروج"),
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
        title: const Text("إضافة تبرع"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _showExitDialog,
        ),
      ),

      body: SingleChildScrollView(
        padding: AppPadding.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// الجنس
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "الجنس",
                prefixIcon: Icon(Icons.person),
              ),
              items: ["ذكر", "أنثى"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: inputsLocked
                  ? null
                  : (v) => setState(() => selectedGender = v),
              value: selectedGender,
            ),

            AppGap.md,

            /// العمر
            DropdownButtonFormField<Map<String, dynamic>>(
              
              decoration: const InputDecoration(
                labelText: "الفئة العمرية",
                prefixIcon: Icon(Icons.cake),
              ),
              items: ageGroups.map((age) {
                return DropdownMenuItem(
                  value: age,
                  child: Text(age['label']),
                );
              }).toList(),
              onChanged: inputsLocked
                  ? null
                  : (v) => setState(() => selectedAgeGroup = v),
              value: selectedAgeGroup,
            ),
if (ageNeedsSize()) ...[
  AppGap.md,
  DropdownButtonFormField<String>(
    decoration: const InputDecoration(
      labelText: "المقاس",
      prefixIcon: Icon(Icons.straighten),
    ),
    value: generalSize,
    items: ["XXXS","XXS","XS","S","M","L","XL","XXL","XXXL"]
        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
        .toList(),
    onChanged: inputsLocked
        ? null
        : (v) => setState(() => generalSize = v),
  ),
],
            AppGap.md,

            /// عدد القطع
            TextField(
              controller: _itemCountController,
              keyboardType: TextInputType.number,
              enabled: !inputsLocked,
              onChanged: inputsLocked ? null : _updateItemCount,
              decoration: const InputDecoration(
                labelText: "إجمالي عدد القطع",
              ),
            ),

            AppGap.lg,

            /// الصناديق
            if (totalBoxes > 0 && openedBox == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "اختر صندوق للعمل عليه:",
                    style: AppDesign.subtitleStyle,
                  ),

                  AppGap.sm,

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: totalBoxes,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemBuilder: (context, idx) {
                      int boxNum = idx + 1;
                      bool isSaved = savedBoxes.contains(boxNum);

                      return GestureDetector(
                       onTap: () {
  if (!canOpenBox()) {
     ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إكمال جميع الحقول ')),
      );
    return;
  }

  if (!isSaved) {
    setState(() {
      openedBox = boxNum;
      inputsLocked = true;
    });
  }
},

                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppDesign.radiusLG),
                            gradient: LinearGradient(
                              colors: isSaved
                                  ? [AppDesign.success, AppDesign.primary]
                                  : [
                                      AppDesign.softGreen.withOpacity(0.2),
                                      AppDesign.softGreen
                                    ],
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [

                                Icon(
                                  isSaved
                                      ? Icons.check_circle
                                      : Icons.inventory_2,
                                  color: Colors.white,
                                  size: 30,
                                ),

                                AppGap.xs,

                                Text(
                                  "صندوق $boxNum",
                                  style: AppDesign.subtitleStyle
                                      .copyWith(color: Colors.white),
                                ),

                                Text(
                                  "${boxes[boxNum]?.length ?? 0} قطع",
                                  style: AppDesign.captionStyle
                                      .copyWith(color: Colors.white70),
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

            /// داخل الصندوق
            if (openedBox != null)
              Column(
                children: [

                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() => openedBox = null);
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text("رجوع"),
                      ),
                    ],
                  ),

                  AppGap.sm,

                  ...boxes[openedBox]!.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var item = entry.value;

                    return Card(
                      child: Padding(
                        padding: AppPadding.card,
                        child: Column(
                          children: [

                            Text(
                              "القطعة رقم ${idx + 1}",
                              style: AppDesign.bodyStyle,
                            ),

                            AppGap.sm,

                            Row(
                              children: [

                                GestureDetector(
                                  onTap: () =>
                                      _pickItemImage(openedBox!, idx),
                                  child: Container(
                                    height: 90,
                                    width: 90,
                                    decoration: BoxDecoration(
                                      color: AppDesign.surfaceAlt,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppDesign.border),
                                    ),
                                    child: item['image'] == null
                                        ? const Icon(Icons.upload)
                                        : ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.memory(item['image']),
                                          ),
                                  ),
                                ),

                                AppGap.wMD,

                                Expanded(
                                  child: Column(
                                    children: [

                                      /// نوع القطعة
                                      DropdownButton<String>(
                                        hint: const Text("نوع القطعة"),
                                        value: item['type'],
                                        isExpanded: true,
                                        items: [
                                          "قميص",
                                          "بنطلون",
                                          "فستان",
                                          "معطف",
                                          "حذاء",
                                          "حقيبة",
                                          "قبعة"
                                        ]
                                            .map((e) => DropdownMenuItem(
                                                value: e, child: Text(e)))
                                            .toList(),
                                        onChanged: (v) {
                                          setState(() {
                                            boxes[openedBox]![idx]['type'] = v;
                                            boxes[openedBox]![idx]['size'] = null;
                                          });
                                        },
                                      ),

                                  
                                      ///  مقاس الحذاء
                                      if (item['type'] == "حذاء")
                                        DropdownButton<String>(
                                          hint: const Text("مقاس الحذاء"),
                                          value: item['size'],
                                          isExpanded: true,
                                          items: List.generate(
                                            28,
                                            (i) => (20 + i).toString(),
                                          )
                                              .map((e) => DropdownMenuItem(
                                                  value: e, child: Text(e)))
                                              .toList(),
                                          onChanged: (v) {
                                            setState(() {
                                              boxes[openedBox]![idx]['size'] = v;
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            if (item['error'] != null)
                              Text(
                                item['error'],
                                style: AppDesign.captionStyle
                                    .copyWith(color: AppDesign.error),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),

                  AppGap.lg,

                  ElevatedButton(
                    onPressed: () async {
                      await _submitBox(openedBox!);
                    },
                    child: const Text("حفظ الصندوق"),
                  ),
                ],
              ),

            AppGap.lg,

           
ElevatedButton(
  onPressed: (totalBoxes > 0 && allBoxesSaved())
      ? () async {
          final user = FirebaseAuth.instance.currentUser;

          await FirebaseFirestore.instance
              .collection('donations')
              .doc(donationId ?? user!.uid)
              .set({
            'donorID': user!.uid,
            'gender': selectedGender ?? "",
            'ageGroup': selectedAgeGroup?['label'] ?? "",
            'numberOfItems': totalItems,
            'status': 'draft',
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("تم حفظ التبرع بالكامل بنجاح"),
              backgroundColor: AppDesign.success,
              duration: Duration(seconds: 2),
            ),
          );

          await Future.delayed(const Duration(seconds: 1));

          Navigator.pushNamedAndRemoveUntil(
            context,
            '/donorHome',
            (route) => false,
            arguments: user?.email ?? '',
          );
        }
      : null,
  child: const Text("تم"),
),
          ],
        ),
      ),
    ),
  );
}
}
