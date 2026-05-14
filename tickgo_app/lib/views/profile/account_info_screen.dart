import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({super.key});

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  String _selectedGender = 'Nữ'; 
  String? _avatarUrl; // Link mạng từ Firebase
  File? _localAvatarFile; // 👉 CHIÊU MỚI: File ảnh lấy trực tiếp từ máy
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  final Color primaryGreen = const Color(0xFF2EBD59);
  final Color darkBg = const Color(0xFF252525);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (currentUser == null) return;
    try {
      _emailController.text = currentUser!.email ?? '';
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? data['full_name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _dobController.text = data['dob'] ?? '';
          _selectedGender = data['gender'] ?? 'Nữ';
          _avatarUrl = data['avatarUrl']; 
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải thông tin: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUserData() async {
    if (currentUser == null) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'dob': _dobController.text.trim(),
        'gender': _selectedGender,
        // Nếu có link mạng thì lưu, không thì thôi
        if (_avatarUrl != null) 'avatarUrl': _avatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Đã lưu thông tin!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Lỗi: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // 👉 HÀM XỬ LÝ ẢNH KIỂU MỚI
  Future<void> _pickAndUploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50); 
    if (image == null) return;

    setState(() {
      _localAvatarFile = File(image.path); // 1. HIỆN ẢNH TỪ MÁY LÊN LIỀN NGAY LẬP TỨC
      _isUploadingAvatar = true; // Bật vòng xoay chờ up mạng
    });

    try {
      // 2. Âm thầm đẩy lên Firebase ở phía sau
      File file = File(image.path);
      String fileName = 'avatars/${currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(file);
      String downloadUrl = await ref.getDownloadURL();

      setState(() {
        _avatarUrl = downloadUrl; // Có link thì gắn vô biến
        _isUploadingAvatar = false; // Tắt vòng xoay
      });
      
      // Tự động lưu link vào Database luôn cho chắc cú
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).set({'avatarUrl': downloadUrl}, SetOptions(merge: true));
      
    } catch (e) {
      setState(() => _isUploadingAvatar = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Lỗi up ảnh mạng: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFF2EBD59), onPrimary: Colors.white, surface: Color(0xFF252525), onSurface: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg, 
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
        ),
        title: const Text("Thông tin tài khoản", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.green)) 
        : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =====================================
            // 1. CỤM AVATAR KIỂU MỚI (BẤT TỬ)
            // =====================================
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickAndUploadAvatar,
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade700, width: 2), color: Colors.grey.shade800),
                      child: ClipOval(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // LỚP 1: HIỂN THỊ HÌNH ẢNH
                            if (_localAvatarFile != null)
                              Image.file(_localAvatarFile!, fit: BoxFit.cover) // Vừa chọn là lấy hình từ điện thoại lên liền
                            else if (_avatarUrl != null && _avatarUrl!.trim().isNotEmpty)
                              Image.network(
                                _avatarUrl!, 
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                              )
                            else
                              Image.network("https://i.ibb.co/L51k62c/default-avatar.png", fit: BoxFit.cover),
                            
                            // LỚP 2: VÒNG XOAY CHỜ ĐẨY LÊN MẠNG
                            if (_isUploadingAvatar)
                              Container(
                                color: Colors.black45, // Làm mờ ảnh xíu lúc đang up
                                child: const Center(child: CircularProgressIndicator(color: Colors.green)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: GestureDetector(
                      onTap: _pickAndUploadAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: primaryGreen, shape: BoxShape.circle, border: Border.all(color: darkBg, width: 2)),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            const Center(
              child: Text("Cung cấp thông tin chính xác sẽ hỗ trợ bạn\ntrong quá trình mua vé, hoặc khi cần xác thực\nvé", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
            ),
            const SizedBox(height: 30),

            _buildLabel("Họ và tên"),
            _buildTextField(controller: _nameController, hint: "Nhập họ và tên"),
            const SizedBox(height: 20),

            _buildLabel("Số điện thoại"),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [const Text("+84", style: TextStyle(color: Colors.black87, fontSize: 16)), const SizedBox(width: 8), Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600, size: 20)]),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(controller: _phoneController, hint: "Nhập số điện thoại", isPhone: true)),
              ],
            ),
            const SizedBox(height: 20),

            _buildLabel("Email"),
            _buildTextField(controller: _emailController, hint: "Email", isReadOnly: true, isGray: true),
            const SizedBox(height: 20),

            _buildLabel("Ngày tháng năm sinh *", isRequired: true),
            GestureDetector(onTap: _selectDate, child: AbsorbPointer(child: _buildTextField(controller: _dobController, hint: "dd/mm/yyyy"))),
            const SizedBox(height: 20),

            _buildLabel("Giới tính"),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildGenderRadio("Nam"), const SizedBox(width: 20),
                _buildGenderRadio("Nữ"), const SizedBox(width: 20),
                _buildGenderRadio("Khác"),
              ],
            ),
            
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _isSaving ? null : _saveUserData,
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: _isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Hoàn thành", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(text: TextSpan(text: text.replaceAll(" *", ""), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), children: [if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontSize: 15))])),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, bool isReadOnly = false, bool isGray = false, bool isPhone = false}) {
    return TextFormField(
      controller: controller, readOnly: isReadOnly, keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      style: TextStyle(color: isGray ? Colors.grey.shade400 : Colors.black87, fontSize: 16),
      decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400), filled: true, fillColor: isGray ? Colors.grey.shade800 : Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
    );
  }

  Widget _buildGenderRadio(String value) {
    bool isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: Row(children: [
        Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? primaryGreen : Colors.grey, width: isSelected ? 6 : 2), color: Colors.white)),
        const SizedBox(width: 8), Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ]),
    );
  }
}