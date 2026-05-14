import 'package:flutter/material.dart';

class EventBottomBar extends StatelessWidget {
  final String price;

  const EventBottomBar({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1976D2); // Xanh dương cho nút bấm
    const Color primaryGreen = Color(0xFF00B14F); // Xanh lá cho giá tiền

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white, // Nền trắng tinh khôi tệp với màu nền app
        boxShadow: [
          // Đổ bóng mờ hắt lên trên để phân tách với phần nội dung cuộn
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, -4), 
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 1. Phần hiển thị Giá vé
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Giá vé từ", style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  "$price đ", 
                  style: const TextStyle(color: primaryGreen, fontSize: 20, fontWeight: FontWeight.w900)
                ),
              ],
            ),
            const SizedBox(width: 24),
            
            // 2. Nút Mua Vé bo tròn
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Tính năng thanh toán đang được xây dựng 🚧"))
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  // Bo tròn nút thành hình viên thuốc cho hợp với ảnh và ô thông tin
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  elevation: 0, // Bỏ bóng của nút đi cho giao diện phẳng hiện đại
                ),
                child: const Text("Mua Vé Ngay", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}