import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TicketPurchaseScreen extends StatefulWidget {
  final Map<String, dynamic> eventData;

  const TicketPurchaseScreen({super.key, required this.eventData});

  @override
  State<TicketPurchaseScreen> createState() => _TicketPurchaseScreenState();
}

class _TicketPurchaseScreenState extends State<TicketPurchaseScreen> {
  Map<String, int> _selectedQuantities = {};
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  late String _eventId;

  @override
  void initState() {
    super.initState();
    _eventId = widget.eventData['id']?.toString() ?? widget.eventData['docId']?.toString() ?? "";
    _loadUserData();
    _initializeQuantities();
  }

  void _initializeQuantities() {
    List<dynamic>? tickets = widget.eventData['ticketTypes'] as List<dynamic>?;
    if (tickets != null && tickets.isNotEmpty) {
      for (var t in tickets) {
        String tName = t['name']?.toString() ?? "Vé";
        _selectedQuantities[tName] = 0;
      }
      String firstTicketName = tickets[0]['name']?.toString() ?? "Vé";
      _selectedQuantities[firstTicketName] = 1;
    } else {
      _selectedQuantities["Vé Tiêu Chuẩn"] = 1;
    }
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            setState(() {
              _nameController.text = data['name']?.toString() ?? '';
              _phoneController.text = data['phone']?.toString() ?? '';
            });
          }
        }
      } catch (e) {
        debugPrint("Lỗi: $e");
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String formatVND(dynamic price) {
    if (price == null) return "0";
    String strPrice = price.toString().replaceAll(RegExp(r'[^0-9]'), '');
    if (strPrice.isEmpty) return "0";
    return strPrice.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  int _calculateTotal(Map<String, dynamic> realTimeData) {
    int total = 0;
    List<dynamic>? tickets = realTimeData['ticketTypes'] as List<dynamic>?;

    if (tickets != null && tickets.isNotEmpty) {
      for (var t in tickets) {
        String tName = t['name']?.toString() ?? "Vé";
        int qty = _selectedQuantities[tName] ?? 0;
        int price = int.tryParse(t['price']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ?? 0;
        total += qty * price;
      }
    } else {
      int qty = _selectedQuantities["Vé Tiêu Chuẩn"] ?? 0;
      int price = int.tryParse(realTimeData['price']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ?? 0;
      total += qty * price;
    }
    return total;
  }

  int _calculateTotalQuantity() {
    int count = 0;
    _selectedQuantities.forEach((key, value) => count += value);
    return count;
  }

  void _processPayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_calculateTotalQuantity() == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn vé!")));
      return;
    }
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Điền đủ thông tin!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        if (_eventId.isEmpty) throw "Không tìm thấy ID!";
        DocumentReference eventRef = FirebaseFirestore.instance.collection('events').doc(_eventId);
        DocumentSnapshot eventSnap = await transaction.get(eventRef);
        if (!eventSnap.exists) throw "Sự kiện không tồn tại!";

        Map<String, dynamic> dbData = eventSnap.data() as Map<String, dynamic>;
        Map<String, dynamic> updateData = {};
        
        if (dbData.containsKey('ticketTypes') && dbData['ticketTypes'] != null) {
          List<dynamic> currentTickets = List.from(dbData['ticketTypes']);
          for (var i = 0; i < currentTickets.length; i++) {
            String tName = currentTickets[i]['name']?.toString() ?? "Vé";
            int requestedQty = _selectedQuantities[tName] ?? 0;
            int available = int.tryParse(currentTickets[i]['limit']?.toString() ?? '0') ?? 0;
            if (requestedQty > available) throw "Loại vé $tName hết!";
            currentTickets[i]['limit'] = (available - requestedQty).toString();
          }
          updateData['ticketTypes'] = currentTickets;
        } else {
          int available = int.tryParse(dbData['availableTickets']?.toString() ?? '100') ?? 100;
          if (_calculateTotalQuantity() > available) throw "Sự kiện hết vé!";
          updateData['availableTickets'] = available - _calculateTotalQuantity();
        }

        updateData['soldCount'] = (int.tryParse(dbData['soldCount']?.toString() ?? '0') ?? 0) + _calculateTotalQuantity();
        transaction.update(eventRef, updateData);

        DocumentReference purchaseRef = FirebaseFirestore.instance.collection('purchases').doc();
        transaction.set(purchaseRef, {
          'userId': user.uid,
          'eventId': _eventId,
          'eventTitle': widget.eventData['title']?.toString() ?? "Sự kiện",
          'eventImageUrl': widget.eventData['imageUrl']?.toString() ?? "",
          'buyerName': _nameController.text.trim(),
          'buyerPhone': _phoneController.text.trim(),
          'tickets': _selectedQuantities.entries.where((e) => e.value > 0).map((e) => {'name': e.key, 'qty': e.value}).toList(),
          'totalPrice': _calculateTotal(dbData), // Truyền data realtime vào để tính tiền
          'purchaseDate': FieldValue.serverTimestamp(),
          'status': 'success',
          'qrCode': purchaseRef.id,
        });
      });

      setState(() => _isLoading = false);
      _showSuccessDialog();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
              ),
              const SizedBox(height: 20),
              const Text("Thanh toán thành công!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Vé điện tử đã được lưu vào ví của bạn.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.5)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("VỀ TRANG CHỦ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1976D2);

    // 👉 DÙNG STREAM BUILDER ĐỂ CẬP NHẬT GIAO DIỆN REAL-TIME
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('events').doc(_eventId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text("Dữ liệu sự kiện không tồn tại.")));
        }

        var realTimeData = snapshot.data!.data() as Map<String, dynamic>;
        List<dynamic>? tickets = realTimeData['ticketTypes'] as List<dynamic>?;

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(title: const Text("Xác nhận thông tin", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800)), backgroundColor: Colors.white, elevation: 0, centerTitle: true, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87), onPressed: () => Navigator.pop(context))),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TÓM TẮT
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Row(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(realTimeData['imageUrl']?.toString() ?? 'https://via.placeholder.com/150', width: 90, height: 90, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => Container(width: 90, height: 90, color: Colors.grey[300]))),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(realTimeData['title']?.toString() ?? 'Tên sự kiện', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1E1E)), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Row(children: [const Icon(Icons.calendar_month_rounded, size: 14, color: Colors.grey), const SizedBox(width: 6), Expanded(child: Text(realTimeData['date']?.toString() ?? '', style: TextStyle(color: Colors.grey.shade700, fontSize: 13), maxLines: 1))]),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. DANH SÁCH CHỌN VÉ (CẬP NHẬT REAL-TIME)
                const Text("SỐ LƯỢNG VÉ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
                const SizedBox(height: 12),
                
                if (tickets != null && tickets.isNotEmpty)
                  ...tickets.map((t) => _buildTicketItem(t['name']?.toString() ?? "Vé", t['price'], t['limit']?.toString() ?? "0"))
                else
                  _buildTicketItem("Vé Tiêu Chuẩn", realTimeData['price'], (realTimeData['availableTickets'] ?? realTimeData['ticketLimit'] ?? '100').toString()),

                const SizedBox(height: 24),
                const Text("THÔNG TIN LIÊN HỆ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    children: [
                      _buildTextField("Họ và Tên", Icons.person_outline, _nameController),
                      const Divider(),
                      _buildTextField("Số điện thoại", Icons.phone_outlined, _phoneController, isPhone: true),
                      const Divider(),
                      _buildTextField("Email", Icons.email_outlined, _emailController, enabled: false),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(primaryBlue, realTimeData),
        );
      }
    );
  }

  Widget _buildTicketItem(String name, dynamic price, String limit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text("${formatVND(price)} đ", style: const TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Còn lại: $limit", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              _buildCountButton(Icons.remove, () {
                if ((_selectedQuantities[name] ?? 0) > 0) setState(() => _selectedQuantities[name] = (_selectedQuantities[name] ?? 0) - 1);
              }),
              SizedBox(width: 30, child: Center(child: Text("${_selectedQuantities[name] ?? 0}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
              _buildCountButton(Icons.add, () {
                int limitInt = int.tryParse(limit) ?? 0;
                if ((_selectedQuantities[name] ?? 0) < limitInt && (_selectedQuantities[name] ?? 0) < 10) {
                  setState(() => _selectedQuantities[name] = (_selectedQuantities[name] ?? 0) + 1);
                } else if ((_selectedQuantities[name] ?? 0) >= 10) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tối đa 10 vé mỗi loại!")));
                }
              }),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBottomBar(Color primaryBlue, Map<String, dynamic> realTimeData) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))], borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tổng cộng", style: TextStyle(color: Colors.grey, fontSize: 13)),
                Text("${formatVND(_calculateTotal(realTimeData))} đ", style: TextStyle(color: primaryBlue, fontSize: 22, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          SizedBox(
            width: 160, height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _processPayment,
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("THANH TOÁN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCountButton(IconData icon, VoidCallback onTap) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 20, color: const Color(0xFF1976D2))));
  }

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, {bool isPhone = false, bool enabled = true}) {
    return TextField(controller: controller, enabled: enabled, keyboardType: isPhone ? TextInputType.phone : TextInputType.text, style: TextStyle(color: enabled ? Colors.black87 : Colors.grey.shade600, fontWeight: FontWeight.w500), decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: enabled ? Colors.orange : Colors.grey), border: InputBorder.none));
  }
}