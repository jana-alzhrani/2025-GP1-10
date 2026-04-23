import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_design.dart';

class BeneficiaryHomePage extends StatefulWidget {
  final String userEmail;

  const BeneficiaryHomePage({
    super.key,
    required this.userEmail,
  });

  @override
  State<BeneficiaryHomePage> createState() => _BeneficiaryHomePageState();
}

class _BeneficiaryHomePageState extends State<BeneficiaryHomePage> {
  String selectedGender = "الكل";
  String selectedAge = "الكل";

  List<Map<String, dynamic>> boxes = [];
  bool isLoading = true;

  String firstName = "";
  String lastName = "";

  @override
  void initState() {
    super.initState();
    loadUserData();
    loadBoxes();
  }

  Future<void> loadUserData() async {
    final query = await FirebaseFirestore.instance
        .collection('Users')
        .where('email', isEqualTo: widget.userEmail)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      setState(() {
        firstName = data['firstName'] ?? "";
        lastName = data['lastName'] ?? "";
      });
    }
  }

  Future<void> loadBoxes() async {
    List<Map<String, dynamic>> allBoxes = [];

    final donationsSnapshot = await FirebaseFirestore.instance
        .collection('donations')
        .where('status', isEqualTo: 'In warehouse')
        .get();

    for (var donationDoc in donationsSnapshot.docs) {
      final donationData = donationDoc.data();
      final donationId = donationDoc.id;

      final boxesSnapshot = await FirebaseFirestore.instance
          .collection('donation_boxes')
          .where('donationId', isEqualTo: donationId)
          .get();

      for (var boxDoc in boxesSnapshot.docs) {
        final d = boxDoc.data();

        List<String> imagesList = [];
        final items = d['items'];

        if (items is List) {
          for (var item in items) {
            if (item is Map && item['imageBase64'] != null) {
              imagesList.add(item['imageBase64']);
            }
          }
        }

        allBoxes.add({
          "gender": donationData['gender'] ?? 'الكل',
          "age": donationData['ageGroup'] ?? 'الكل',
          "images": imagesList,
        });
      }
    }

    setState(() {
      boxes = allBoxes;
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> get filteredBoxes {
    return boxes.where((box) {
      final genderOk =
          selectedGender == "الكل" || box["gender"] == selectedGender;

      final ageOk =
          selectedAge == "الكل" || box["age"] == selectedAge;

      return genderOk && ageOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredBoxes;

    return Scaffold(
      backgroundColor: AppDesign.background,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "مزيد"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "طلباتي"),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "الرئيسية"),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [

            /// HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  Icon(Icons.shopping_cart, color: Colors.grey.shade700),

                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "$firstName $lastName",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
                            ),
                          ),
                          const Text(
                            "مرحباً 👋",
                            style: TextStyle(fontSize: 15, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),

                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppDesign.primary,
                        child: Text(
                          firstName.isNotEmpty ? firstName[0] : "?",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// HERO
           Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: LinearGradient(
        colors: [
          AppDesign.primary,
          AppDesign.primary.withOpacity(0.8),
        ],
      ),
    ),
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "مع مَدَد يمكنك الحصول على التبرعات المناسبة لك✨",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
          SizedBox(height: 8),
          Text(
            "تصفح القطع واختر ما يناسبك بسهولة وسرعة",
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    ),
  ),
),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _statCard(
                    icon: Icons.inventory_2,
                    title: " الصناديق الجاهزة",
                    value: "${boxes.length}",
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    icon: Icons.checkroom,
                    title: " القطع المتوفرة",
                    value: "${boxes.fold(0, (s, b) => s + (b["images"] as List).length)}",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// FILTER TITLE
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  child: Align(
    alignment: Alignment.centerRight,
    child: Text(
      "تصفية التبرعات",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade700,
        fontSize: 14,
      ),
    ),
  ),
),

            const SizedBox(height: 8),

            _buildFilters(),

            const SizedBox(height: 10),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? const Center(child: Text("لا توجد تبرعات"))
                      : Directionality(
                          textDirection: TextDirection.rtl,
                          child: GridView.builder(
                            padding: const EdgeInsets.all(10),
                            itemCount: filtered.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                            ),
                            itemBuilder: (context, index) {
                              final box = filtered[index];

                              return ClothesBoxCard(
                                images: box["images"],
                                gender: box["gender"],
                                age: box["age"],
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
  required IconData icon,
  required String title,
  required String value,
}) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppDesign.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppDesign.primary),
          ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [

              /// العنوان (غامق شوي)
              Text(
                title,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade800, // 👈 غمّقنا هنا
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              /// الرقم (أوضح وأغمق)
              Text(
                value,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey.shade900, // 👈 غامق جدًا
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildFilters() {
    List<String> genders = ["الكل", "ذكر", "أنثى"];
    List<String> ages = [
      "الكل",
      "رضّع (0-2)",
      "أطفال (3-5)",
      "أطفال (6-9)",
      "أطفال (10-12)",
      "مراهقون (13-17)",
      "بالغون (18+)",
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                children: genders.map((g) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(g),
                      selected: selectedGender == g,
                      onSelected: (_) => setState(() => selectedGender = g),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 10),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                children: ages.map((a) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(a),
                      selected: selectedAge == a,
                      onSelected: (_) => setState(() => selectedAge = a),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClothesBoxCard extends StatelessWidget {
  final List images;
  final String gender;
  final String age;

  const ClothesBoxCard({
    super.key,
    required this.images,
    required this.gender,
    required this.age,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [

              Expanded(
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, i) {
                    return Image.memory(
                      base64Decode(images[i]),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [

                    Text(age),

                    const SizedBox(height: 6),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppDesign.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {},
                      child: const Text("عرض"),
                    )
                  ],
                ),
              )
            ],
          ),
        ),

       Positioned(
  top: 10,
  right: 10,
  child: Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 4,
        )
      ],
    ),
    child: Icon(
      gender == "أنثى"
          ? Icons.woman_2   
          : Icons.man,      
      size: 22,
      color: Colors.grey,
    ),
  ),
),
      ],
    );
  }
}
