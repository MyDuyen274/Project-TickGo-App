import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final user = FirebaseAuth.instance.currentUser;

  String formatVND(dynamic price) {
    if (price == null) return "0";
    String strPrice = price.toString().replaceAll(RegExp(r'[^0-9]'), '');
    if (strPrice.isEmpty) return "0";
    return strPrice.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  void _showQRDialog(BuildContext context, Map<String, dynamic> ticketData) {
    bool isUsed = ticketData['status'] == 'checked_in';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Text("MÃ CHECK-IN SỰ KIỆN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E1E1E), letterSpacing: 0.5)),
              const SizedBox(height: 12),
              Text(ticketData['eventTitle'] ?? 'Tên sự kiện', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
              const SizedBox(height: 24),
              Opacity(
                opacity: isUsed ? 0.3 : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isUsed ? Colors.red.shade200 : Colors.blue.shade200, width: 2)),
                  child: QrImageView(
                    data: ticketData['qrCode'] ?? '',
                    version: QrVersions.auto,
                    size: 200.0,
                    errorStateBuilder: (cxt, err) => const Center(child: Text("Lỗi tạo mã QR")),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: isUsed ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isUsed ? Icons.cancel : Icons.check_circle, color: isUsed ? Colors.red : Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(isUsed ? "VÉ ĐÃ SỬ DỤNG" : "VÉ HỢP LỆ - CHƯA SỬ DỤNG", style: TextStyle(fontWeight: FontWeight.bold, color: isUsed ? Colors.red : Colors.green)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text("Vui lòng đưa mã này cho nhân viên soát vé tại cổng sự kiện. Không chia sẻ mã này cho người khác.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5)),
              const SizedBox(height: 20),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập!")));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(title: const Text("Ví Vé Của Tôi", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900)), backgroundColor: Colors.white, elevation: 0),
      body: StreamBuilder<QuerySnapshot>(
        // 👉 Đã gỡ orderBy để tránh lỗi Index Firebase
        stream: FirebaseFirestore.instance.collection('purchases').where('userId', isEqualTo: user!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("Bạn chưa mua vé nào cả.", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                ],
              )
            );
          }

          // 👉 Lấy danh sách và tự sắp xếp mới nhất lên đầu bằng code Dart
          var purchases = snapshot.data!.docs;
          purchases.sort((a, b) {
            Timestamp t1 = (a.data() as Map<String, dynamic>)['purchaseDate'] ?? Timestamp.now();
            Timestamp t2 = (b.data() as Map<String, dynamic>)['purchaseDate'] ?? Timestamp.now();
            return t2.compareTo(t1);
          });

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: purchases.length,
            itemBuilder: (context, index) {
              var data = purchases[index].data() as Map<String, dynamic>;
              bool isUsed = data['status'] == 'checked_in';

              return GestureDetector(
                onTap: () => _showQRDialog(context, data),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Row(
                    children: [
                      Container(
                        width: 100, height: 120,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                          image: DecorationImage(image: NetworkImage(data['eventImageUrl'] ?? 'https://via.placeholder.com/150'), fit: BoxFit.cover),
                        ),
                        child: isUsed ? Container(
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: const BorderRadius.horizontal(left: Radius.circular(20))),
                          child: const Center(child: Icon(Icons.check_circle, color: Colors.white, size: 30)),
                        ) : null,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['eventTitle'] ?? 'Tên sự kiện', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              if (data['tickets'] != null)
                                ...((data['tickets'] as List<dynamic>).map((t) => Text("• ${t['name']}: ${t['qty']} vé", style: TextStyle(color: Colors.grey.shade600, fontSize: 13))))
                              else if (data['ticketTypeName'] != null)
                                Text("• ${data['ticketTypeName']}: ${data['quantity']} vé", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("${formatVND(data['totalPrice'])} đ", style: const TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.w900, fontSize: 14)),
                                  Icon(Icons.qr_code_scanner_rounded, color: isUsed ? Colors.grey : Colors.orange),
                                ],
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}