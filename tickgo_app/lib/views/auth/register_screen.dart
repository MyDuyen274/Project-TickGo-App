import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  
  // Trạng thái bật/tắt con mắt mật khẩu
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;

  // Danh sách mã vùng điện thoại
  String _selectedCountryCode = '+84';
  final List<Map<String, String>> _countryCodes = [
    {'code': '+84', 'name': '🇻🇳 +84'},
    {'code': '+1', 'name': '🇺🇸 +1'},
    {'code': '+81', 'name': '🇯🇵 +81'},
    {'code': '+86', 'name': '🇨🇳 +86'},
  ];

  void _register() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String phone = _phoneController.text.trim();
    String password = _passwordController.text;
    String confirm = _confirmController.text;

    // 1. Kiểm tra nhập đủ thông tin chưa
    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      _showError("Vui lòng điền đầy đủ thông tin!");
      return;
    }

    // 2. Kiểm tra định dạng Email (Phải có @ và . )
    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!emailRegex.hasMatch(email)) {
      _showError("Email không hợp lệ (Ví dụ đúng: abc@gmail.com)");
      return;
    }

    // 3. Kiểm tra định dạng số điện thoại (Cơ bản từ 8-11 số)
    if (phone.length < 8 || phone.length > 11 || int.tryParse(phone) == null) {
      _showError("Số điện thoại không hợp lệ!");
      return;
    }

    // 4. Kiểm tra Mật khẩu cực mạnh (>= 6 ký tự, có HOA, có Số, có Ký tự đặc biệt)
    if (password.length < 6) {
      _showError("Mật khẩu phải có ít nhất 6 ký tự.");
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      _showError("Mật khẩu phải chứa ít nhất 1 chữ IN HOA.");
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      _showError("Mật khẩu phải chứa ít nhất 1 chữ số.");
      return;
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
      _showError("Mật khẩu phải chứa ít nhất 1 ký tự đặc biệt (!@#...).");
      return;
    }

    // 5. Kiểm tra Mật khẩu xác nhận
    if (password != confirm) {
      _showError("Mật khẩu xác nhận không khớp!");
      return;
    }

    // ==========================================
    // NẾU VƯỢT QUA HẾT BÀI KIỂM TRA THÌ GỌI FIREBASE
    // ==========================================
    setState(() => _isLoading = true);
    
    // Gộp mã vùng vào số điện thoại
    String fullPhoneNumber = _selectedCountryCode + phone;

    // LƯU Ý: Tui đã thêm tham số fullPhoneNumber vào hàm signUp.
    // Bồ cần sang file auth_service.dart để cập nhật lại hàm này nhé (xem mục 2).
    String? result = await _authService.signUp(email, password, name, fullPhoneNumber);

    setState(() => _isLoading = false);

    if (result == "Success") {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      _showError(result ?? "Lỗi đăng ký từ hệ thống");
    }
  }

  // Hàm phụ để hiện thông báo lỗi cho gọn code
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
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
                    "Tạo tài khoản",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF1976D2), 
                      fontSize: 32, 
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tham gia TickGo ngay hôm nay!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 35),
                  
                  // Ô nhập Họ Tên
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Họ và Tên",
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // Ô nhập Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Khu vực nhập Số điện thoại + Mã vùng
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCountryCode,
                            items: _countryCodes.map((item) {
                              return DropdownMenuItem<String>(
                                value: item['code'],
                                child: Text(item['name']!, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedCountryCode = value!);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: "Số điện thoại",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  // Ô nhập Mật khẩu
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Mật khẩu",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Ô Xác nhận Mật khẩu
                  TextField(
                    controller: _confirmController,
                    obscureText: !_isConfirmVisible,
                    decoration: InputDecoration(
                      labelText: "Xác nhận mật khẩu",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_isConfirmVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                        onPressed: () => setState(() => _isConfirmVisible = !_isConfirmVisible),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Nút Đăng ký
                  _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: const Text("Đăng ký", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                  
                  const SizedBox(height: 20),
                  
                  // Nút quay lại
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Đã có tài khoản?", style: TextStyle(color: Colors.grey, fontSize: 15)),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF1976D2)),
                        child: const Text("Đăng nhập ngay", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}