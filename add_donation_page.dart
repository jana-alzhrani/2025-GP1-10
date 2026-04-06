import 'dart:convert';

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

import 'package:image_picker/image_picker.dart';

import 'package:cloud_firestore/cloud_firestore.dart';



class AddDonationPage extends StatefulWidget {

  const AddDonationPage({super.key});



  @override

  State<AddDonationPage> createState() => _AddDonationPageState();

}



class _AddDonationPageState extends State<AddDonationPage> {
bool inputsLocked = false; 

  String? selectedGender;

  Map<String, dynamic>? selectedAgeGroup;

  final TextEditingController _itemCountController = TextEditingController();

  final String _apiKey = 'AIzaSyB-XXCzTt2YMJbgcK3-RafbqZPo5l6jyOE'; 
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

  {'label': 'أطفال  (10-12)', 'min': 10, 'max': 12},

  {'label': 'مراهقون (13-17)', 'min': 13, 'max': 17},

  {'label': 'بالغون (18+)', 'min': 18, 'max': 120},

];


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

          'isValid': false,

          'error': null,

        },

      );

      remainingItems -= itemsInThisBox;

    }

    setState(() {});

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

                  "text":

"Check if this is a valid photo of a clothing item or a bag. Answer 'Yes' or 'No' only. Accept clothes or bags of any color, including black. Reject only if it is completely black, blurry, or not clothes/bags."
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
  if (result.trim().toLowerCase().contains("yes")) {
    boxes[box]![index]['isValid'] = true;
    boxes[box]![index]['error'] = null;

    // رسالة SnackBar باللون الأخضر
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "الصورة صالحة ✅",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green, // خلفية خضراء
        duration: Duration(seconds: 2),
      ),
    );
  } else {
    boxes[box]![index]['image'] = null;
    boxes[box]![index]['type'] = null;
    boxes[box]![index]['isValid'] = false;
    boxes[box]![index]['error'] = null;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "الصورة غير صالحة!",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
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



  Future<void> _submitBox(int box) async {

    final items = boxes[box]!;



    bool incomplete = items.any(

        (item) => item['image'] == null || item['type'] == null || !item['isValid']);

    if (selectedGender == null || selectedAgeGroup == null || incomplete) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

            content: Text("يرجى إكمال جميع الحقول ")),

      );

      return;

    }



    try {

      await firestore.collection('donation_boxes').add({

        'boxNumber': box,

        'gender': selectedGender,

        'ageGroup': {

          'label': selectedAgeGroup!['label'],

          'min': selectedAgeGroup!['min'],

          'max': selectedAgeGroup!['max'],

        },

        'items': items.map((e) {

          return {

            'type': e['type'],

            'imageBase64': base64Encode(e['image']),

          };

        }).toList(),

        'timestamp': FieldValue.serverTimestamp(),

      });



      ScaffoldMessenger.of(context)

          .showSnackBar(SnackBar(content: Text("تم حفظ الصندوق $box ✅")));



      setState(() {

        boxes[box] = List.generate(

          boxes[box]!.length,

          (index) => {'image': null, 'type': null, 'isValid': false, 'error': null},

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



 @override
Widget build(BuildContext context) {
   

const primaryGreen = Color(0xFF3F5F2A);
const lightGreen = Color(0xFFC8E6C9);
const pageBackground = Color(0xFFF5E6CC);

return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(

  backgroundColor: pageBackground,

  appBar: AppBar(
    title: const Text("إضافة تبرع"),
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.white,
    foregroundColor: primaryGreen,
  ),

  body: SingleChildScrollView(
    padding: const EdgeInsets.all(16),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: "الجنس",
            prefixIcon: const Icon(Icons.person, color: primaryGreen),
            filled: true,
            fillColor: openedBox == null ? Colors.white : Colors.grey[300],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: lightGreen, width: 1.5),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: primaryGreen, width: 2),
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
            prefixIcon: const Icon(Icons.cake, color: primaryGreen),
            filled: true,
            fillColor: openedBox == null ? Colors.white : Colors.grey[300],   
                     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: lightGreen, width: 1.5),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: primaryGreen, width: 2),
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
            fillColor: openedBox == null ? Colors.white : Colors.grey[300],

            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: openedBox == null ? lightGreen : Colors.grey,
                width: 1.5,
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: primaryGreen,
                width: 2,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        if (totalBoxes > 0 && openedBox == null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "اختر صندوق للعمل عليه:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalBoxes,

                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1,
                ),

                itemBuilder: (context, idx) {

                  int boxNum = idx + 1;
                  bool isSaved = savedBoxes.contains(boxNum);

                  return GestureDetector(
                  onTap: () {
  if (!isSaved) {
    setState(() {
      openedBox = boxNum;
      inputsLocked = true; // قفل الحقول الثلاثة
    });
  } else {

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("هذا الصندوق تم حفظه مسبقاً"),
                          ),
                        );
                      }
                    },

                    child: Container(
                      decoration: BoxDecoration(

                        gradient: LinearGradient(
                          colors: isSaved
                              ? [Color(0xFFA5D6A7), Color(0xFF4CAF50)]
                              : [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                        ),

                        borderRadius: BorderRadius.circular(20),

                        border: Border.all(
                          color: primaryGreen,
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

                            Icon(
                              isSaved ? Icons.check_circle : Icons.inventory_2,
                              color: isSaved ? Colors.white : primaryGreen,
                              size: 32,
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "صندوق $boxNum",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isSaved ? Colors.white : Colors.black87,
                              ),
                            ),

                            Text(
                              "${boxes[boxNum]?.length ?? 0} قطع",
                              style: TextStyle(
                                fontSize: 12,
                                color: isSaved ? Colors.white70 : Colors.black54,
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
// زر الرجوع
     
      // زر الرجوع + عنوان الصندوق
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          // زر الرجوع على اليسار
          TextButton.icon(
            onPressed: () {
              setState(() {
                openedBox = null; // يرجع لقائمة الصناديق
              });
            },
            icon: const Icon(Icons.arrow_back, color: primaryGreen),
            label: const Text(
              "رجوع",
              style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
            ),
          ),

          // عنوان الصندوق في الوسط
          Expanded(
            child: Center(
              child: Text(
                "الصندوق رقم  $openedBox",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // إضافة SizedBox صغير على اليمين لتوازن Row
          const SizedBox(width: 70),
        ],
      ),

              ...boxes[openedBox]!.asMap().entries.map((entry) {

                int idx = entry.key;
                var item = entry.value;

                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                        color: item['error'] != null ? const Color.fromARGB(255, 1, 230, 69) : primaryGreen,
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
        color: const Color.fromARGB(255, 101, 133, 79),
        width: 2,
      ),
    ),
    child: item['image'] == null
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.upload_file,
                color: Color.fromARGB(255, 109, 176, 113),
                size: 36,
              ),
              SizedBox(height: 4),
              Text(
                "انقر لرفع الصورة",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color.fromARGB(255, 109, 176, 113),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(12),
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
    items: ["قميص", "بنطلون", "فستان", "معطف", "حذاء", "حقيبة", "قبعة"]
        .map(
          (e) => DropdownMenuItem(
            value: e,
            child: Directionality(
              textDirection: TextDirection.rtl, // اجعل النص داخل العنصر يمين
              child: Text(e),
            ),
          ),
        )
        .toList(),
    onChanged: (v) => setState(() {
      boxes[openedBox]![idx]['type'] = v;
    }),
    isExpanded: true, // يظل يملأ المساحة المتاحة بشكل طبيعي
  ),
),
                          ],
                        ),

                        if (item['error'] != null)
                          Text(
                            item['error'] ?? '',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  onPressed: () async {
                    await _submitBox(openedBox!);
                  },

                  child: const Text(
                    "حفظ الصندوق",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold , color: Colors.white,),
                  ),
                ),
              ),
            ],
          ),

        const SizedBox(height: 16),






     // if (allBoxesSaved() && totalBoxes > 0)

//   SizedBox(

//     width: double.infinity,

//     child: ElevatedButton(

//       onPressed: () {

//         // ينقل للصفحة المستقلة بعد حفظ كل الصناديق

//         Navigator.push(

//           context,

//           MaterialPageRoute(builder: (_) => const mai()),

//         );

//       },

//       child: const Text("تم"),

//     ),

//   ),

//  

          ],

        ),

      ),

    )
);
  }

}
