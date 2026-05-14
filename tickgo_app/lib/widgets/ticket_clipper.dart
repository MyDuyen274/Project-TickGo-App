import 'package:flutter/material.dart';

class TicketShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const radius = 24.0; // Đồng bộ độ bo tròn 24 với giao diện mới
    const notchRadius = 14.0; // Độ to của lỗ khoét
    const notchY = 40.0; // Vị trí khoét lỗ hạ xuống một chút cho cân với thẻ nổi

    // 1. Bắt đầu từ cạnh trái, ngay dưới góc bo trên
    path.moveTo(0, radius);
    // Bo góc trên trái
    path.quadraticBezierTo(0, 0, radius, 0); 
    
    // 2. Kéo sang mép phải
    path.lineTo(size.width - radius, 0);
    // Bo góc trên phải
    path.quadraticBezierTo(size.width, 0, size.width, radius); 

    // 3. Cạnh phải đi xuống tới vị trí lỗ khoét
    path.lineTo(size.width, notchY);
    // Khoét lỗ bên phải (móc lõm vào trong)
    path.arcToPoint(
      Offset(size.width, notchY + notchRadius * 2),
      radius: const Radius.circular(notchRadius),
      clockwise: false, 
    );

    // 4. Kéo thẳng xuống cạnh dưới phải
    path.lineTo(size.width, size.height - radius);
    // Bo góc dưới phải (NÂNG CẤP: bo thêm góc dưới cho mềm mại)
    path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);

    // 5. Kéo sang cạnh dưới trái
    path.lineTo(radius, size.height);
    // Bo góc dưới trái (NÂNG CẤP)
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);

    // 6. Cạnh trái kéo ngược lên tới vị trí lỗ khoét
    path.lineTo(0, notchY + notchRadius * 2);
    // Khoét lỗ bên trái (móc lõm vào trong)
    path.arcToPoint(
      Offset(0, notchY),
      radius: const Radius.circular(notchRadius),
      clockwise: false, 
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true; // Đổi thành true để nó mượt hơn khi resize
}