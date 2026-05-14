import 'package:flutter/material.dart';
import '../../widgets/ticket_clipper.dart'; 
import '../event/ticket_purchase_screen.dart'; 

// ==============================================================
// HÀM KIỂM TRA SỰ KIỆN ĐÃ QUÁ HẠN CHƯA
// ==============================================================
bool isEventExpired(String dateStr, String timeStr) {
  if (dateStr.isEmpty) return false;
  try {
    String endStr = dateStr.contains('-') ? dateStr.split('-').last.trim() : dateStr.trim();
    List<String> dateParts = endStr.split('/');
    if (dateParts.length == 3) {
      int year = int.parse(dateParts[2]);
      int month = int.parse(dateParts[1]);
      int day = int.parse(dateParts[0]);
      int hour = 23;
      int minute = 59;

      if (timeStr.isNotEmpty && timeStr.contains('-')) {
        String endTimeStr = timeStr.split('-').last.trim(); 
        List<String> timeParts = endTimeStr.split(':');
        if (timeParts.length >= 2) {
          hour = int.parse(timeParts[0]);
          minute = int.parse(timeParts[1]);
        }
      }
      DateTime exactEndDate = DateTime(year, month, day, hour, minute, 59);
      return exactEndDate.isBefore(DateTime.now());
    }
    return false;
  } catch (e) {
    return false;
  }
}

class EventDetailScreen extends StatefulWidget {
  final dynamic eventData;

  const EventDetailScreen({super.key, required this.eventData});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  int _currentImageIndex = 0; // 👉 Biến theo dõi vị trí ảnh đang vuốt

  // 👉 Hàm định dạng giá tiền
  String formatVND(dynamic price) {
    if (price == null) return "0";
    String strPrice = price.toString().replaceAll(RegExp(r'[^0-9]'), '');
    if (strPrice.isEmpty) return "0";
    return strPrice.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  // 👉 Hàm lấy giá thấp nhất để hiển thị
  String getMinPrice() {
    List<dynamic>? tickets = widget.eventData['ticketTypes'];
    if (tickets == null || tickets.isEmpty) {
      return formatVND(widget.eventData['price']);
    }
    
    int min = int.parse(tickets[0]['price'].toString().replaceAll(RegExp(r'[^0-9]'), ''));
    for (var t in tickets) {
      int p = int.parse(t['price'].toString().replaceAll(RegExp(r'[^0-9]'), ''));
      if (p < min) min = p;
    }
    return formatVND(min);
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1976D2);
    const Color primaryGreen = Color(0xFF00B14F);
    const Color pastelBg = Color(0xFFF0F6FF); 
    const Color textDark = Color(0xFF1A1A1A);

    bool isExpired = isEventExpired(widget.eventData['date'] ?? '', widget.eventData['timeFrame'] ?? '');
    String ageRestriction = widget.eventData['ageRestriction'] ?? 'Mọi độ tuổi';
    List<dynamic> ticketTypes = widget.eventData['ticketTypes'] ?? [];

    // 👉 LẤY MẢNG ẢNH (GALLERY) ĐỂ ĐƯA VÀO SLIDER
    List<dynamic> galleryUrls = widget.eventData['galleryUrls'] ?? [];
    if (galleryUrls.isEmpty && widget.eventData['imageUrl'] != null) {
      galleryUrls.add(widget.eventData['imageUrl']); // Nếu sự kiện cũ ko có gallery thì dùng ảnh chính
    }
    if (galleryUrls.isEmpty) {
      galleryUrls.add('https://via.placeholder.com/800x400');
    }

    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 👉 1. KHU VỰC ẢNH SỰ KIỆN (VUỐT ĐƯỢC - PAGEVIEW)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      // Trượt ảnh
                      PageView.builder(
                        itemCount: galleryUrls.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Image.network(
                            galleryUrls[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (ctx, err, stack) => Container(color: Colors.grey[200]),
                          );
                        },
                      ),
                      
                      // 👉 Các chấm tròn báo hiệu bên dưới ảnh
                      if (galleryUrls.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: galleryUrls.asMap().entries.map((entry) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: _currentImageIndex == entry.key ? 20 : 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: _currentImageIndex == entry.key ? Colors.white : Colors.white.withOpacity(0.5),
                                ),
                              );
                            }).toList(),
                          ),
                        )
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. KHUNG CUỐNG VÉ 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipPath(
                clipper: TicketShapeClipper(), 
                child: Container(
                  color: pastelBg, 
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTag(isExpired ? "⛔ Đã kết thúc" : "🔥 Đang mở bán", 
                                    isExpired ? Colors.grey : primaryGreen),
                          const SizedBox(width: 8), 
                          _buildTag(ageRestriction, Colors.orange, icon: Icons.family_restroom_rounded),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.eventData['title'] ?? 'Tên sự kiện',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.4, color: textDark),
                      ),
                      const SizedBox(height: 24),
                      Divider(color: Colors.blueGrey.withOpacity(0.1), thickness: 1),
                      const SizedBox(height: 20),
                      _buildInfoRow(Icons.calendar_month_rounded, "Thời gian", "${widget.eventData['timeFrame'] ?? ''}, ${widget.eventData['date'] ?? ''}"),
                      const SizedBox(height: 20),
                      _buildInfoRow(Icons.location_on_rounded, "Địa điểm", widget.eventData['location'] ?? "Chưa rõ địa điểm"),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 3. DANH SÁCH CÁC LOẠI VÉ 
            if (ticketTypes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Các loại vé", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...ticketTypes.map((ticket) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("• ${ticket['name']}", style: const TextStyle(color: textDark)),
                            Text("${formatVND(ticket['price'])} đ", style: const TextStyle(fontWeight: FontWeight.bold, color: primaryGreen)),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // 4. KHỐI GIỚI THIỆU SỰ KIỆN 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: pastelBg, 
                  borderRadius: BorderRadius.circular(24), 
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Giới thiệu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                    const SizedBox(height: 12),
                    Text(
                      widget.eventData['description'] ?? "Chưa có thông tin giới thiệu.",
                      style: const TextStyle(fontSize: 14, color: Color(0xFF4A4A4A), height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100), 
          ],
        ),
      ),
      
      bottomNavigationBar: isExpired 
          ? null 
          : Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Giá từ", style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text("${getMinPrice()} đ", style: const TextStyle(color: primaryGreen, fontSize: 22, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TicketPurchaseScreen(eventData: widget.eventData),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Mua Vé Ngay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTag(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, color: color, size: 14),
          if (icon != null) const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFF1976D2), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A1A))),
            ],
          ),
        )
      ],
    );
  }
}