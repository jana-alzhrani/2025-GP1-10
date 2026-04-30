import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_design.dart';
import 'Beneficiary_more_page.dart';
import 'Beneficiary_view_donation_page.dart';

class BeneficiaryHomePage extends StatefulWidget {
final String userId;


const BeneficiaryHomePage({
  super.key,
  required this.userId,
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
  final doc = await FirebaseFirestore.instance
      .collection('Users')
      .doc(widget.userId)
      .get();

  if (doc.exists) {
    final data = doc.data()!;
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
        .where('status', isEqualTo: 'available')
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
  "donationId": donationId,
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
  onTap: (index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BeneficiaryMorePage(userId: widget.userId),
        ),
      );
    }

    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BeneficiaryHomePage(userId: widget.userId),
        ),
      );
    }
  },
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

StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('cart')
      .where('beneficiaryId', isEqualTo: widget.userId)
      .where('status', isEqualTo: 'in_cart')
      .snapshots(),
  builder: (context, snapshot) {
    final count = snapshot.data?.docs.length ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.shopping_cart, color: Colors.grey.shade700),
        if (count > 0)
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppDesign.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  },
),
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
                                donationId: box["donationId"],
                                userId: widget.userId,
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

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Row(
      children: [

        /// 🔹 التصنيف (الجنس)
        Expanded(
          child: _filterCard(
            title: "التصنيف",
            value: selectedGender,
            icon: Icons.person,
            items: genders,
            onSelected: (value) {
              setState(() {
                selectedGender = value;
              });
            },
          ),
        ),

        const SizedBox(width: 10),

        /// 🔹 الفئة العمرية
        Expanded(
          child: _filterCard(
            title: "الفئة العمرية",
            value: selectedAge,
            icon: Icons.cake,
            items: ages,
            onSelected: (value) {
              setState(() {
                selectedAge = value;
              });
            },
          ),
        ),
      ],
    ),
  );
}
}
Widget _filterCard({
  required String title,
  required String value,
  required IconData icon,
  required List<String> items,
  required Function(String) onSelected,
}) {
  return PopupMenuButton<String>(
    onSelected: onSelected,
    itemBuilder: (context) => items.map((e) {
      return PopupMenuItem(
        value: e,
        child: Text(e),
      );
    }).toList(),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
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

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ),

          const Icon(Icons.arrow_drop_down),
        ],
      ),
    ),
  );
}

class ClothesBoxCard extends StatelessWidget {
  final List images;
  final String gender;
  final String age;
  final String donationId;
  final String userId;

  const ClothesBoxCard({
    super.key,
    required this.images,
    required this.gender,
    required this.age,
    required this.donationId,
    required this.userId,
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
                        backgroundColor: const Color.fromARGB(255, 40, 78, 86),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BeneficiaryViewDonationPage(
                              donationId: donationId,
                              userId: userId,
                            ),
                          ),
                        );
                      },
                      child: const Text("عرض التفاصيل "),
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
