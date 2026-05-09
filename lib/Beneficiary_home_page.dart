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
class _BeneficiaryHomePageState
    extends State<BeneficiaryHomePage> {

  int _bottomNavIndex = 0;

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

    final snapshot = await FirebaseFirestore.instance
        .collection('donation_boxes')
        .where('status', isEqualTo: 'available')
        .get();

    for (var doc in snapshot.docs) {
      final d = doc.data();

      List<String> imagesList = [];

      final items = d['items'];
      if (items is List) {
        for (var item in items) {
          if (item is Map &&
              item['imageUrl'] != null) {
            imagesList.add(item['imageUrl']);
          }
        }
      }

      allBoxes.add({
        "boxId": doc.id,
        "donationId": d['donationId'] ?? "",
        "gender": d['gender'] ?? 'الكل',
        "age": d['ageGroup']?['label'] ?? 'الكل',
        "images": imagesList,
      });
    }

    setState(() {
      boxes = allBoxes;
      isLoading = false;
    });
  }

  String normalize(String text) {
    return text.replaceAll(" ", "").trim();
  }

  List<Map<String, dynamic>> get filteredBoxes {
    return boxes.where((box) {
      final genderOk =
          selectedGender == "الكل" ||
              normalize(box["gender"]) ==
                  normalize(selectedGender);

      final ageOk =
          selectedAge == "الكل" ||
              normalize(box["age"]) ==
                  normalize(selectedAge);

      return genderOk && ageOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredBoxes;

    return Scaffold(
      backgroundColor: AppDesign.background,

      bottomNavigationBar: Container(
        margin:
            const EdgeInsets.fromLTRB(16, 0, 16, 14),

        decoration: BoxDecoration(
          color: AppDesign.white,
          borderRadius:
              BorderRadius.circular(AppDesign.radiusXL),
          boxShadow: [
            BoxShadow(
              color:
                  AppDesign.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),

        child: Directionality(
          textDirection: TextDirection.rtl,

          child: NavigationBar(
            height: 78,
            selectedIndex: _bottomNavIndex,

            backgroundColor: Colors.transparent,

            indicatorColor:
                AppDesign.secondary.withOpacity(0.16),

            surfaceTintColor: Colors.transparent,

            labelBehavior:
                NavigationDestinationLabelBehavior
                    .alwaysShow,

            onDestinationSelected: (index) {
              setState(() {
                _bottomNavIndex = index;
              });

              if (index == 0) {
                Navigator.pushReplacementNamed(
                  context,
                  '/beneficiaryHome',
                  arguments: widget.userId,
                );
              } else if (index == 1) {
                Navigator.pushReplacementNamed(
                  context,
                  '/orders',
                  arguments: widget.userId,
                );
              } else if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        BeneficiaryMorePage(
                      userId: widget.userId,
                    ),
                  ),
                );
              }
            },

            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon:
                    Icon(Icons.home_rounded),
                label: 'الرئيسية',
              ),

              NavigationDestination(
                icon: Icon(
                  Icons.volunteer_activism_outlined,
                ),
                selectedIcon: Icon(
                  Icons.volunteer_activism_rounded,
                ),
                label: 'طلباتي',
              ),

              NavigationDestination(
                icon: Icon(Icons.more_horiz),
                selectedIcon:
                    Icon(Icons.more_horiz),
                label: 'المزيد',
              ),
            ],
          ),
        ),
      )
      ,
      body: SafeArea(
        child: Column(
          children: [

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
  builder: (context, cartSnapshot) {
    if (!cartSnapshot.hasData) {
      return Icon(
        Icons.shopping_cart_outlined,
        color: Colors.grey.shade700,
      );
    }

    final cartDocs = cartSnapshot.data!.docs;

    return FutureBuilder<int>(
      future: _countAvailableCartItems(cartDocs),
      builder: (context, countSnapshot) {
        final count = countSnapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              color: Colors.grey.shade700,
              size: 28,
            ),

            if (count > 0)
              Positioned(
                top: -6,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: AppDesign.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count.toString(),
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
    );
  },
),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppDesign.primary,
                  child: Text(
                    firstName.isNotEmpty ? firstName[0] : 'م',
                    style: const TextStyle(
                      color: AppDesign.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ),

                AppGap.wMD,

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'مرحبًا',
                      style: AppDesign.bodyStyle.copyWith(
                        color: AppDesign.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$firstName $lastName",
                      style: AppDesign.h1Style.copyWith(
                        color: AppDesign.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
                ],
              ),
            ),

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
                child: const Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "مع مَدَد يمكنك الحصول على التبرعات المناسبة ",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "تصفح القطع واختر ما يناسبك بسهولة وسرعة",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "تصفية التبرعات",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
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

                  return Align(
                    alignment: Alignment.topRight, 
                    child: ClothesBoxCard(
                      images: box["images"],
                      gender: box["gender"],
                      age: box["age"],
                      userId: widget.userId,
                      boxId: box["boxId"],
                    ),
                  );
                },
              ),
            ),
)
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
    "أطفال صغار (3-5)",
    "أطفال (6-9)",
    "أطفال (10-15)",
    "بالغون",
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Row(
      children: [

        Expanded(
          child: _filterCard(
            title: "التصنيف",
            value: selectedGender,
            icon: Icons.person,
            items: genders,
            onSelected: (value) {
              setState(() => selectedGender = value);
            },
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _filterCard(
            title: "الفئة العمرية",
            value: selectedAge,
            icon: Icons.cake,
            items: ages,
            onSelected: (value) {
              setState(() => selectedAge = value);
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
    itemBuilder: (context) =>
        items.map((e) => PopupMenuItem(value: e, child: Text(e))).toList(),

    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 18, color: AppDesign.primary),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
        ],
      ),
    ),
  );
}
Future<int> _countAvailableCartItems(
  List<QueryDocumentSnapshot> cartDocs,
) async {
  int count = 0;

  for (final cartDoc in cartDocs) {
    final cartData = cartDoc.data() as Map<String, dynamic>;
    final boxId = cartData['boxId']?.toString();

    if (boxId == null || boxId.isEmpty) continue;

    final boxDoc = await FirebaseFirestore.instance
        .collection('donation_boxes')
        .doc(boxId)
        .get();

    if (!boxDoc.exists) continue;

    final boxData = boxDoc.data()!;
    final boxStatus = boxData['status']?.toString();

    if (boxStatus == 'available') {
      count++;
    }
  }

  return count;
}
  class ClothesBoxCard extends StatelessWidget {
  final List images;
  final String gender;
  final String age;
  final String userId;
  final String boxId;

  const ClothesBoxCard({
    super.key,
    required this.images,
    required this.gender,
    required this.age,
    required this.userId,
    required this.boxId,
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
                    return Image.network(
  images[i],
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
                              boxId: boxId, 
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