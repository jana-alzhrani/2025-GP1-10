import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_design.dart';
import 'Beneficiary_more_page.dart';

/// ─────────────── إعدادات قاعدة البيانات ───────────────
const String kBoxesCollection = 'donation_boxes';

/// الحقل الذي يربط الصندوق بالمستفيد
const String kBeneficiaryIdField = 'beneficiaryId';

/// حالات الصناديق التي تظهر في تبويب "الطلبات النشطة"
const List<String> kActiveStatuses = [
  'reserved',
  'delivered',
];

/// حالات الصناديق التي تظهر في تبويب "الطلبات السابقة"
const List<String> kPreviousStatuses = [
  'complete',
];

const Map<String, String> kStatusLabels = {
  'reserved': 'تم الطلب',
  'delivered': 'جاري التوصيل',
  'complete': 'تم التوصيل',
};

String _statusLabel(String s) => kStatusLabels[s] ?? 'مؤكد';

DateTime? _toDate(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is String) return DateTime.tryParse(v);
  return null;
}

class _BoxData {
  final String id;
  final Map<String, dynamic> data;

  const _BoxData(this.id, this.data);
}

/// ═══════════════════════════ الصفحة ═══════════════════════════
class BeneficiaryOrdersPage extends StatefulWidget {
  final String userId;

  const BeneficiaryOrdersPage({
    super.key,
    required this.userId,
  });

  @override
  State<BeneficiaryOrdersPage> createState() =>
      _BeneficiaryOrdersPageState();
}

class _BeneficiaryOrdersPageState extends State<BeneficiaryOrdersPage> {
  int _bottomNavIndex = 1;

  /// 0 = الطلبات النشطة
  /// 1 = الطلبات السابقة
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppDesign.background,
        bottomNavigationBar: _buildBottomNav(),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabs(),
              Expanded(
                child: _buildBoxesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── الهيدر ─────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          Text(
            "طلباتي",
            style: TextStyle(
              color: AppDesign.primary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "تابع حالة طلباتك النشطة والسابقة",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── التبويبات ─────────────────────────
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            _tabItem("الطلبات النشطة", 0),
            _tabItem("الطلبات السابقة", 1),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(String label, int index) {
    final selected = _tabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tabIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppDesign.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: selected
                  ? Colors.white
                  : AppDesign.primary,
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── قائمة الطلبات ─────────────────────────
  Widget _buildBoxesList() {
    final isActiveTab = _tabIndex == 0;

    /// جلب الصناديق المرتبطة بالمستفيد الحالي
    /// عن طريق beneficiaryId
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance
            .collection(kBoxesCollection)
            .where(
              kBeneficiaryIdField,
              isEqualTo: widget.userId,
            );

    /// النشطة:
    /// reserved + delivered
    ///
    /// السابقة:
    /// complete فقط
    query = isActiveTab
        ? query.where(
            'status',
            whereIn: kActiveStatuses,
          )
        : query.where(
            'status',
            whereIn: kPreviousStatuses,
          );

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "حدث خطأ أثناء تحميل الطلبات",
            ),
          );
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final docs = [
          ...?snapshot.data?.docs,
        ];

        // ─────────────────────────
        // ترتيب الأحدث حجزاً أولاً
        // ─────────────────────────
        docs.sort((a, b) {
          final da = _toDate(
            a.data()['reservedAt'],
          );

          final db = _toDate(
            b.data()['reservedAt'],
          );

          if (da != null && db != null) {
            return db.compareTo(da);
          }

          return 0;
        });

        // ─────────────────────────
        // لا توجد طلبات
        // ─────────────────────────
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.volunteer_activism_outlined,
                  size: 56,
                  color:
                      AppDesign.primary.withOpacity(0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  isActiveTab
                      ? "لا توجد طلبات نشطة حالياً"
                      : "لا توجد طلبات سابقة",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppDesign.primary,
                  ),
                ),
              ],
            ),
          );
        }

        // ─────────────────────────
        // تجميع الصناديق حسب orderId
        // كارد واحد لكل طلب
        // ─────────────────────────
        final groups =
            <String, List<_BoxData>>{};

        for (final d in docs) {
          final data = d.data();

          final orderId =
              (data['orderId'] ?? d.id).toString();

          groups
              .putIfAbsent(
                orderId,
                () => [],
              )
              .add(
                _BoxData(
                  d.id,
                  data,
                ),
              );
        }

        final orders = groups.entries.toList();

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            16,
            4,
            16,
            16,
          ),
          itemCount: orders.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final e = orders[index];

            final status =
                (e.value.first.data['status'] ??
                        kActiveStatuses.first)
                    .toString();

            return OrderCard(
              key: ValueKey(
                '${_tabIndex}_${e.key}',
              ),
              status: status,
              boxes: e.value,
            );
          },
        );
      },
    );
  }

  // ───────────────────────── البوتوم ناف ─────────────────────────
  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        14,
      ),
      decoration: BoxDecoration(
        color: AppDesign.white,
        borderRadius: BorderRadius.circular(
          AppDesign.radiusXL,
        ),
        boxShadow: [
          BoxShadow(
            color: AppDesign.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: NavigationBar(
        height: 78,
        selectedIndex: _bottomNavIndex,
        backgroundColor: Colors.transparent,
        indicatorColor:
            AppDesign.secondary.withOpacity(0.16),
        surfaceTintColor: Colors.transparent,
        labelBehavior:
            NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          if (index == 1) return;

          setState(() {
            _bottomNavIndex = index;
          });

          if (index == 0) {
            Navigator.pushReplacementNamed(
              context,
              '/beneficiaryHome',
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
    );
  }
}

/// ═══════════════════════════ كارد الطلب ═══════════════════════════
class OrderCard extends StatelessWidget {
  final String status;
  final List<_BoxData> boxes;

  const OrderCard({
    super.key,
    required this.status,
    required this.boxes,
  });

  @override
  Widget build(BuildContext context) {
    // الجنس والفئة العمرية من أول بوكس
    // + مجموع القطع
    String gender = '';
    String age = '';
    int totalItems = 0;
    String boxDeliveryMethod = '';

    for (final b in boxes) {
      final d = b.data;

      if (gender.isEmpty) {
        gender = (d['gender'] ?? '').toString();
      }

      if (age.isEmpty) {
        final ag = d['ageGroup'];

        age = ag is Map
            ? (ag['label'] ?? '').toString()
            : '';
      }

      if (boxDeliveryMethod.isEmpty) {
        boxDeliveryMethod =
            (d['deliveryMethod'] ?? '').toString();
      }

      final items = d['items'];

      if (items is List) {
        totalItems += items.length;
      }
    }

    final title = [
      gender,
      age,
    ].where((s) => s.isNotEmpty).join(' - ');

    final deliveryText =
        boxDeliveryMethod.isNotEmpty
            ? boxDeliveryMethod
            : 'استلام من موقعي';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ─── العنوان + الحالة + الأيقونة ───
          Row(
            children: [
              Expanded(
                child: Text(
                  title.isEmpty
                      ? 'تبرع'
                      : 'تبرع ($title)',
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppDesign.primary,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              _StatusChip(
                label: _statusLabel(status),
              ),

              const SizedBox(width: 8),

              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppDesign.secondary
                      .withOpacity(0.16),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons
                      .volunteer_activism_rounded,
                  size: 20,
                  color: AppDesign.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ─── معلومات التبرع ───
          _InfoBox(
            children: [
              if (gender.isNotEmpty)
                _InfoRow(
                  icon: Icons.wc_rounded,
                  label: 'الجنس',
                  value: gender,
                ),

              if (age.isNotEmpty)
                _InfoRow(
                  icon: Icons.cake_outlined,
                  label: 'الفئة العمرية',
                  value: age,
                ),

              _InfoRow(
                icon:
                    Icons.inventory_2_outlined,
                label: 'عدد القطع',
                value: '$totalItems قطع',
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ─── طريقة التوصيل ───
          _InfoBox(
            children: [
              _InfoRow(
                icon:
                    Icons.local_shipping_outlined,
                label: 'طريقة التوصيل',
                value: deliveryText,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ─── الصناديق ───
          Text(
            'الصناديق',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppDesign.primary,
            ),
          ),

          const SizedBox(height: 8),

          for (final b in boxes)
            _BoxTile(
              boxId: b.id,
              data: b.data,
              statusLabel: _statusLabel(
                (b.data['status'] ?? status)
                    .toString(),
              ),
            ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════ صندوق (قابل للفتح) ═══════════════════════════
class _BoxTile extends StatelessWidget {
  final String boxId;
  final Map<String, dynamic> data;
  final String statusLabel;

  const _BoxTile({
    required this.boxId,
    required this.data,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final code =
        (data['boxCode'] ??
                data['code'] ??
                data['boxNumber'] ??
                boxId)
            .toString();

    // BOX1-SK8A9
    // BOX1- = غامق
    // SK8A9 = رمادي
    final dash = code.indexOf('-');

    final head = dash == -1
        ? code
        : code.substring(0, dash + 1);

    final tail = dash == -1
        ? ''
        : code.substring(dash + 1);

    final items =
        data['items'] is List
            ? data['items'] as List
            : const [];

    return Container(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding:
              const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          childrenPadding:
              const EdgeInsets.fromLTRB(
            10,
            0,
            10,
            10,
          ),
          shape: const Border(),
          collapsedShape: const Border(),

          title: Row(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: head,
                      style: TextStyle(
                        color:
                            AppDesign.primary,
                        fontWeight:
                            FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    TextSpan(
                      text: tail,
                      style: TextStyle(
                        color:
                            Colors.grey.shade500,
                        fontWeight:
                            FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                textDirection:
                    TextDirection.ltr,
              ),

              const Spacer(),

           

           
            ],
          ),

          children: [
            for (
              int i = 0;
              i < items.length;
              i++
            )
              _ItemTile(
                index: i,
                item: items[i],
              ),
          ],
        ),
      ),
    );
  }
}

/// ═══════════════════════════ قطعة داخل الصندوق ═══════════════════════════
class _ItemTile extends StatelessWidget {
  final int index;
  final dynamic item;

  const _ItemTile({
    required this.index,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final map =
        item is Map
            ? item as Map
            : const {};

    final imageUrl =
        map['imageUrl']?.toString();

    final type =
        (map['type'] ??
                map['category'] ??
                map['name'] ??
                map['title'] ??
                '')
            .toString();

    return Container(
      margin:
          const EdgeInsets.only(top: 8),
      padding:
          const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child:
                  (imageUrl == null ||
                          imageUrl.isEmpty)
                      ? Container(
                          color:
                              Colors.grey.shade200,
                          child: Icon(
                            Icons
                                .checkroom_outlined,
                            color:
                                Colors.grey.shade500,
                          ),
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                                _,
                                __,
                                ___,
                              ) =>
                                  Container(
                            color:
                                Colors.grey.shade200,
                            child:
                                const Icon(
                              Icons
                                  .broken_image,
                              color:
                                  Colors.grey,
                            ),
                          ),
                        ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'القطعة ${index + 1}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Colors.grey.shade900,
                  ),
                ),

                if (type.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    type,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════ صندوق معلومات ═══════════════════════════
class _InfoBox extends StatelessWidget {
  final List<Widget> children;

  const _InfoBox({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppDesign.primary,
          ),

          const SizedBox(width: 8),

          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color:
                  Colors.grey.shade500,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w800,
                color:
                    Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════ شارة الحالة ═══════════════════════════
class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppDesign.secondary
            .withOpacity(0.16),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight:
              FontWeight.w700,
          color: AppDesign.primary,
        ),
      ),
    );
  }
}
