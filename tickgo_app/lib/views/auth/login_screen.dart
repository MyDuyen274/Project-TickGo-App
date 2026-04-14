import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../home/home_screen.dart';
import 'register_screen.dart'; // Import thêm trang đăng ký

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false; // Trạng thái của con mắt hiển thị mật khẩu

  void _login() async {
    // Kiểm tra rỗng
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ Email và Mật khẩu")),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    String? result = await _authService.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result == "Success") {
      if (!mounted) return;
      // Đăng nhập thành công -> Bay vào trang Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // Hiện thông báo lỗi
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result ?? "Lỗi đăng nhập")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Màu nền xám nhạt giúp form trắng nổi bật hơn
      body: SafeArea(
        child: Center( // Căn giữa toàn bộ nội dung
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              // BÍ QUYẾT: Giới hạn chiều rộng tối đa là 400px để không bị dãn trên Web
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "TickGo",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF1976D2), 
                      fontSize: 42, 
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Chào mừng trở lại!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  
                  // Ô nhập Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      hintText: "Nhập địa chỉ email",
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Ô nhập Mật khẩu
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible, // Tắt/mở che mật khẩu dựa vào biến
                    decoration: InputDecoration(
                      labelText: "Mật khẩu",
                      hintText: "Nhập mật khẩu",
                      prefixIcon: const Icon(Icons.lock_outline),
                      // Nút con mắt
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          // Bấm vào thì đảo ngược trạng thái
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Nút Đăng nhập
                  _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text("Đăng nhập", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                  const SizedBox(height: 25),
                  
                  // Nút chuyển sang Đăng ký
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Chưa có tài khoản?", 
                        style: TextStyle(color: Colors.grey, fontSize: 15)
                      ),
                      TextButton(
                        onPressed: () {
                          // Chuyển sang trang Đăng ký
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1976D2),
                        ),
                        child: const Text(
                          "Đăng ký ngay", 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}