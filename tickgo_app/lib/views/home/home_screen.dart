import 'dart:async';
import 'dart:ui'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/api_service.dart';
import '../auth/login_screen.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';
import '../../widgets/event_card.dart';
import 'search_screen.dart'; 
import '../event/qr_scanner_screen.dart'; // 👉 IMPORT TRANG QUÉT MÃ QR

// ==============================================================
// CÁC HÀM GLOBAL XỬ LÝ NGÀY THÁNG
// ==============================================================
bool isEventExpired(String dateStr) {
  if (dateStr.isEmpty) return false;
  try {
    String endStr = dateStr.contains('-') ? dateStr.split('-').last.trim() : dateStr.trim();
    List<String> parts = endStr.split('/');
    if (parts.length == 3) {
      DateTime endDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]), 23, 59, 59);
      return endDate.isBefore(DateTime.now());
    }
    return false;
  } catch (e) {
    return false;
  }
}

DateTime? parseStartDate(String dateStr) {
  if (dateStr.isEmpty) return null;
  try {
    String startStr = dateStr.contains('-') ? dateStr.split('-').first.trim() : dateStr.trim();
    List<String> parts = startStr.split('/');
    if (parts.length == 3) {
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    }
    return null;
  } catch (e) {
    return null;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final user = FirebaseAuth.instance.currentUser;
  late Future<List<dynamic>> _eventsFuture;

  final ValueNotifier<String> _selectedCityNotifier = ValueNotifier("Tất cả");

  final List<String> _provinces = [
    "Tất cả", "Hồ Chí Minh", "Hà Nội", "Đà Nẵng", "Đà Lạt", 
    "Hải Phòng", "Cần Thơ", "Nha Trang", "Vũng Tàu", "Bình Dương", "Đồng Nai"
  ];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    setState(() { _eventsFuture = _apiService.fetchEvents(); });
  }

  @override
  void dispose() { 
    _selectedCityNotifier.dispose(); 
    super.dispose(); 
  }

  String formatVND(dynamic price) {
    if (price == null) return "0";
    String strPrice = price.toString().replaceAll(RegExp(r'[^0-9]'), '');
    if (strPrice.isEmpty) return "0";
    return strPrice.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  void _showProvincePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 50, height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Chọn Khu Vực", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E1E1E))),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: _provinces.length,
                separatorBuilder: (c, i) => Divider(height: 1, color: Colors.grey.shade200, indent: 20, endIndent: 20),
                itemBuilder: (context, index) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.location_on, color: Colors.orange, size: 20),
                    ),
                    title: Text(_provinces[index], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    onTap: () {
                      _selectedCityNotifier.value = _provinces[index];
                      Navigator.pop(context); 
                    },
                  );
                },
              ),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      floatingActionButton: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String role = userData['role'] ?? 'user';

          if (role != 'organizer' && role != 'admin') return const SizedBox.shrink();

          // 👉 TRẢ VỀ 2 NÚT CHO BAN TỔ CHỨC
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // NÚT 1: QUÉT VÉ QR
              FloatingActionButton.extended(
                heroTag: "scan_qr",
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const QRScannerScreen()));
                },
                backgroundColor: Colors.orange.shade600, 
                elevation: 6,
                icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                label: const Text("Quét Vé", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
              
              const SizedBox(height: 16),
              
              // NÚT 2: TẠO SỰ KIỆN
              FloatingActionButton.extended(
                heroTag: "create_event",
                onPressed: () async {
                  final res = await Navigator.push(context, MaterialPageRoute(builder: (c) => const CreateEventScreen()));
                  if (res == true) _loadEvents();
                },
                backgroundColor: const Color(0xFF1A2980), 
                elevation: 6,
                icon: const Icon(Icons.add_circle, color: Colors.white),
                label: const Text("Tạo sự kiện", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ],
          );
        },
      ),
      
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF0F4F8), 
              Color(0xFFDCE5EE), 
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildPremiumHeader(context), 
            SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                _buildUtilityIcons(),
                
                DynamicEventRow(eventsFuture: _eventsFuture, formatPrice: formatVND),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('categories').orderBy('order').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox();
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

                    var categories = snapshot.data!.docs;
                    List<Widget> categorySections = [];
                    
                    for (int i = 0; i < categories.length; i++) {
                      categorySections.add(
                        DynamicCategorySection(
                          categoryId: categories[i].id, 
                          categoryName: categories[i]['name'],
                          styleIndex: i % 3, 
                          formatPrice: formatVND,
                        )
                      );
                    }

                    return Column(children: categorySections);
                  },
                ),

                ValueListenableBuilder<String>(
                  valueListenable: _selectedCityNotifier,
                  builder: (context, selectedCity, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader("🌟 Khám phá tại ${selectedCity == 'Tất cả' ? 'Việt Nam' : selectedCity}", false),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
                          child: InkWell(
                            onTap: () => _showProvincePicker(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                                border: Border.all(color: Colors.orange.shade200, width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on, color: Colors.orange, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    selectedCity == "Tất cả" ? "Tất cả khu vực" : selectedCity,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.orange),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _buildNodeJsEventsGrid(selectedCity),
                      ],
                    );
                  }
                ),
                
                _buildProfessionalFooter(),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalFooter() {
    return Container(
      margin: const EdgeInsets.only(top: 40), 
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 130), 
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2C5364), Color(0xFF203A43)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.local_activity_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              const Text("TICKGO", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "Nền tảng phân phối vé sự kiện & trải nghiệm giải trí hàng đầu. Dễ dàng khám phá, đặt vé và tận hưởng hàng ngàn sự kiện hấp dẫn mỗi ngày.", 
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6) 
          ),
          const SizedBox(height: 32),
          const Text("THÔNG TIN LIÊN HỆ", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.phone_in_talk_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Text("Hotline: 1900 1234 (8:00 - 22:00)", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.email_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Text("Email: support@tickgo.vn", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 32),
          Divider(color: Colors.white24, thickness: 1), 
          const SizedBox(height: 20),
          Center(
            child: Text("© 2026 TickGo. Tất cả các quyền được bảo lưu.", style: TextStyle(color: Colors.white54, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)], 
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                            builder: (context, snapshot) {
                              String name = "Bạn";
                              if (snapshot.hasData && snapshot.data!.exists) {
                                final data = snapshot.data!.data() as Map<String, dynamic>;
                                name = data['name'] ?? "Bạn"; 
                              }
                              return Text("Chào $name! 👋", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5));
                            },
                          ),
                          const SizedBox(height: 6),
                          Text("Hôm nay bạn muốn xem show gì?", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    // 👉 SỬA ĐOẠN ĐĂNG XUẤT Ở ĐÂY ĐỂ ĐẨY VỀ TRANG LOGIN
                    Container(
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Colors.white), 
                        onPressed: () async {
                          // Hiện loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
                          );

                          // Đăng xuất khỏi Firebase
                          await FirebaseAuth.instance.signOut();
                          
                          // Đẩy người dùng về màn hình Login và xóa hết lịch sử các trang trước đó
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (Route<dynamic> route) => false, 
                            );
                          }
                        }
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16), 
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen())),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0), 
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15), 
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Padding(padding: EdgeInsets.only(left: 16, right: 12), child: Icon(Icons.search_rounded, color: Colors.white, size: 22)),
                          Text("Tìm tên sự kiện, nghệ sĩ, địa điểm...", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24), 
            const AutoScrollBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilityIcons() {
    final items = [
      {"i": Icons.confirmation_number_rounded, "c": const Color(0xFF42A5F5)},
      {"i": Icons.stars_rounded, "c": const Color(0xFFFFCA28)},
      {"i": Icons.account_balance_wallet_rounded, "c": const Color(0xFF66BB6A)},
      {"i": Icons.calendar_month_rounded, "c": const Color(0xFFAB47BC)}
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) => Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Icon(item['i'] as IconData, color: item['c'] as Color, size: 28),
        )).toList(),
      ),
    );
  }

  Widget _buildNodeJsEventsGrid(String selectedCity) {
    return FutureBuilder<List<dynamic>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: Colors.orange)));
        
        final allEvents = snapshot.data ?? [];
        final filteredEvents = allEvents.where((event) {
          if (isEventExpired(event['date'] ?? '')) return false;

          final location = (event['location'] ?? '').toString().toLowerCase();
          if (selectedCity != "Tất cả") {
            String cityLower = selectedCity.toLowerCase();
            if (cityLower == "hồ chí minh") return location.contains("hồ chí minh") || location.contains("hcm") || location.contains("ho chi minh") || location.contains("sài gòn");
            else if (cityLower == "hà nội") return location.contains("hà nội") || location.contains("ha noi") || location.contains("hn");
            else return location.contains(cityLower);
          }
          return true; 
        }).toList();

        if (filteredEvents.isEmpty) return const SizedBox.shrink();

        return GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 16, childAspectRatio: 0.72),
          itemCount: filteredEvents.length, 
          itemBuilder: (c, i) {
            final rawData = filteredEvents[i];
            // 👉 GÁN THÊM ID VÀO DỮ LIỆU ĐỂ TRUYỀN ĐI
            Map<String, dynamic> eventMap = Map<String, dynamic>.from(rawData as Map);
            if (eventMap['id'] == null && eventMap['_id'] != null) {
              eventMap['id'] = eventMap['_id'];
            }
            
            return EventCard(
              title: eventMap['title'], 
              imageUrl: eventMap['imageUrl'], 
              date: eventMap['date'] ?? "", 
              price: formatVND(eventMap['price']), 
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailScreen(eventData: eventMap)))
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String t, bool seeAll) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 25, 16, 12), 
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(t, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E1E1E), letterSpacing: -0.5)), 
      if(seeAll) const Text("Xem thêm", style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w600))
    ])
  );
}

class DynamicEventRow extends StatefulWidget {
  final Future<List<dynamic>> eventsFuture;
  final Function(dynamic) formatPrice;

  const DynamicEventRow({super.key, required this.eventsFuture, required this.formatPrice});

  @override
  State<DynamicEventRow> createState() => _DynamicEventRowState();
}

class _DynamicEventRowState extends State<DynamicEventRow> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85); 
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: widget.eventsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

        DateTime now = DateTime.now();
        int currentMonth = now.month;
        int currentYear = now.year;

        var hotEvents = snapshot.data!.where((event) {
          if (isEventExpired(event['date'] ?? '')) return false;
          DateTime? startDate = parseStartDate(event['date'] ?? '');
          if (startDate != null) return startDate.month == currentMonth && startDate.year == currentYear;
          return false;
        }).toList();

        if (hotEvents.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 25, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Text("Nổi bật tháng $currentMonth", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
                ],
              ),
            ),
            SizedBox(
              height: 220, 
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: hotEvents.length,
                itemBuilder: (context, index) {
                  var rawData = hotEvents[index];
                  
                  // 👉 GÁN THÊM ID VÀO DỮ LIỆU ĐỂ TRUYỀN ĐI
                  Map<String, dynamic> eventMap = Map<String, dynamic>.from(rawData as Map);
                  if (eventMap['id'] == null && eventMap['_id'] != null) {
                    eventMap['id'] = eventMap['_id'];
                  }

                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        value = _pageController.page! - index;
                        value = (1 - (value.abs() * 0.15)).clamp(0.0, 1.0); 
                      }
                      return Center(
                        child: Transform.scale(
                          scale: Curves.easeOut.transform(value),
                          child: child,
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailScreen(eventData: eventMap))),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24), 
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                eventMap['imageUrl'] ?? 'https://via.placeholder.com/400',
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(color: Colors.grey[300]),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.center,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 20, left: 20, right: 20,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      eventMap['title'] ?? 'Tên sự kiện', 
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white), 
                                      maxLines: 2, overflow: TextOverflow.ellipsis
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
                                          child: Text('${widget.formatPrice(eventMap['price'])} đ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.calendar_month, color: Colors.white70, size: 14),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(eventMap['date'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1)),
                                      ],
                                    )
                                  ]
                                )
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class AutoScrollBanner extends StatefulWidget {
  const AutoScrollBanner({super.key});
  @override
  State<AutoScrollBanner> createState() => _AutoScrollBannerState();
}

class _AutoScrollBannerState extends State<AutoScrollBanner> {
  late PageController _pageController;
  int _currentPage = 1000; 
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage, viewportFraction: 1.0);
    _timer = Timer.periodic(const Duration(seconds: 4), (t) {
      if (_pageController.hasClients) {
        _currentPage++;
        _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 1200), curve: Curves.easeOutCubic);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220, 
      child: PageView.builder(
        controller: _pageController, 
        onPageChanged: (index) => _currentPage = index,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double pageOffset = 0.0;
              if (_pageController.position.haveDimensions) pageOffset = _pageController.page! - index;
              else pageOffset = (index == _currentPage) ? 0.0 : 1.0;

              return ClipRect(
                child: Container(
                  color: Colors.black,
                  child: Transform.translate(
                    offset: Offset(pageOffset * MediaQuery.of(context).size.width * 0.5, 0),
                    child: Opacity(
                      opacity: (1 - pageOffset.abs()).clamp(0.4, 1.0),
                      child: Image.network(
                        'https://picsum.photos/id/${(index % 5) + 40}/800/400',
                        fit: BoxFit.cover,
                        width: double.infinity, height: double.infinity,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }
      )
    );
  }
}

// ==============================================================
// WIDGET MỚI: QUẢN LÝ 3 STYLE CHO CÁC DANH MỤC
// ==============================================================
class DynamicCategorySection extends StatelessWidget {
  final String categoryId;
  final String categoryName;
  final int styleIndex; // Biến quyết định hiển thị theo style nào (0, 1 hoặc 2)
  final Function(dynamic) formatPrice;

  const DynamicCategorySection({
    super.key, 
    required this.categoryId, 
    required this.categoryName, 
    required this.styleIndex,
    required this.formatPrice
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('events').where('categoryId', isEqualTo: categoryId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox();
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        var events = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return !isEventExpired(data['date'] ?? '');
        }).toList();

        if (events.isEmpty) return const SizedBox.shrink();

        // 1. Dựng Tiêu đề danh mục
        Widget header = Padding(
          padding: const EdgeInsets.fromLTRB(16, 25, 16, 12), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    styleIndex == 0 ? Icons.bookmark : (styleIndex == 1 ? Icons.explore : Icons.trending_up), 
                    color: Colors.orange
                  ), 
                  const SizedBox(width: 8),
                  Text(categoryName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
                ],
              ),
              const Text("Xem thêm", style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        );

        // 2. Chọn giao diện dựa vào styleIndex
        Widget content;
        if (styleIndex == 0) {
          content = _buildStyle0ClassicCard(context, events);
        } else if (styleIndex == 1) {
          content = _buildStyle1CinematicWide(context, events);
        } else {
          content = _buildStyle2ModernVertical(context, events);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [header, content],
        );
      },
    );
  }

  // 👉 STYLE 0: Thẻ vuốt ngang chuẩn (Classic)
  Widget _buildStyle0ClassicCard(BuildContext context, List<QueryDocumentSnapshot> events) {
    return SizedBox(
      height: 230, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 8), 
        clipBehavior: Clip.none, 
        itemCount: events.length,
        itemBuilder: (context, index) {
          var doc = events[index];
          // 👉 GÁN THÊM ID DOCUMENT VÀO DỮ LIỆU ĐỂ TRUYỀN ĐI
          var data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
          data['id'] = doc.id; 

          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailScreen(eventData: data))),
            child: Container(
              width: 170, 
              margin: const EdgeInsets.only(right: 14, bottom: 15),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(16), 
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(data['imageUrl'] ?? 'https://via.placeholder.com/150', height: 110, width: double.infinity, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => Container(height: 110, color: Colors.grey[300]))
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['title'] ?? 'Tên sự kiện', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E1E1E)), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Text(data['date'] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Text('${formatPrice(data['price'])} đ', style: const TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.w900, fontSize: 14))
                      ]
                    )
                  )
                ]
              )
            ),
          );
        },
      ),
    );
  }

  // 👉 STYLE 1: Thẻ rộng nằm ngang, text đè lên ảnh (Cinematic)
  Widget _buildStyle1CinematicWide(BuildContext context, List<QueryDocumentSnapshot> events) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 8),
        clipBehavior: Clip.none,
        itemCount: events.length,
        itemBuilder: (context, index) {
          var doc = events[index];
          // 👉 GÁN THÊM ID DOCUMENT VÀO DỮ LIỆU ĐỂ TRUYỀN ĐI
          var data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
          data['id'] = doc.id; 

          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailScreen(eventData: data))),
            child: Container(
              width: 280, // Thẻ rất rộng
              margin: const EdgeInsets.only(right: 14, bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      data['imageUrl'] ?? 'https://via.placeholder.com/400',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(color: Colors.grey[300]),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12, left: 16, right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(data['date'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              Text('${formatPrice(data['price'])} đ', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 👉 STYLE 2: Danh sách top dọc tối giản (Modern Vertical)
  Widget _buildStyle2ModernVertical(BuildContext context, List<QueryDocumentSnapshot> events) {
    var topEvents = events.take(3).toList();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: topEvents.map((eventDoc) {
          // 👉 GÁN THÊM ID DOCUMENT VÀO DỮ LIỆU ĐỂ TRUYỀN ĐI
          var data = Map<String, dynamic>.from(eventDoc.data() as Map<String, dynamic>);
          data['id'] = eventDoc.id; 

          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailScreen(eventData: data))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      data['imageUrl'] ?? 'https://via.placeholder.com/150',
                      width: 80, height: 80, fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(width: 80, height: 80, color: Colors.grey[200]),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['title'] ?? 'Tên sự kiện', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E1E1E)), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(data['date'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('${formatPrice(data['price'])} đ', style: const TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.w900, fontSize: 14)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}