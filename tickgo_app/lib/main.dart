import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Đảm bảo bồ import đúng đường dẫn 2 file này nhé
import 'views/auth/login_screen.dart'; 
import 'views/home/home_screen.dart';

void main() async {
  // 1. Phải có dòng này đầu tiên
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Dùng try-catch để bắt lỗi nếu Firebase "đình công"
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ FIREBASE KẾT NỐI THÀNH CÔNG!");
  } catch (e) {
    print("❌ LỖI KHỞI TẠO FIREBASE: $e");
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TickGo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthGate(), // Tách ra một class riêng cho sạch
    );
  }
}

// Lính gác cổng: Phân luồng người dùng
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // TRÁNH TRANG TRẮNG: Hiện vòng xoay lúc đang chờ dữ liệu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: Colors.blue)),
          );
        }
        
        // CÓ DỮ LIỆU -> Vào thẳng trang chủ
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        
        // KHÔNG CÓ DỮ LIỆU -> Bắt ra ngoài Đăng nhập
        return const LoginScreen();
      },
    );
  }
}