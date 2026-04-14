import 'package:flutter/material.dart';

class EventCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String date;
  final String price;
  final VoidCallback? onTap; // Thêm sự kiện bấm vào thẻ

  const EventCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.date,
    required this.price,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // Bấm vào thẻ để xem chi tiết
      borderRadius: BorderRadius.circular(12),
      hoverColor: Colors.grey[100], // Hiệu ứng khi rê chuột trên web
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hình ảnh sự kiện (Tỷ lệ chuẩn 16:9)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // 2. Tên sự kiện (Tối đa 2 dòng)
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          
          // 3. Giá vé (Màu xanh lá đặc trưng Ticketbox)
          Text(
            "Từ $price đ",
            style: const TextStyle(
              color: Color(0xFF00B14F), // Màu xanh lá
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          
          // 4. Thời gian
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  date,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}