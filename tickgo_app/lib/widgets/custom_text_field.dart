import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👉 THÊM IMPORT NÀY ĐỂ XÀI FORMATTER

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData icon;
  final TextEditingController controller;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final int maxLines;
  
  // 👉 1. KHAI BÁO THÊM BIẾN NÀY ĐỂ NHẬN LIST FORMATTER
  final List<TextInputFormatter>? inputFormatters; 

  const CustomTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.hint,
    this.readOnly = false,
    this.onTap,
    this.keyboardType,
    this.maxLines = 1,
    this.inputFormatters, // 👉 2. THÊM VÀO HÀM KHỞI TẠO (CONSTRUCTOR)
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters, // 👉 3. GẮN VÀO THUỘC TÍNH CỦA TEXTFIELD
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
        ),
      ),
    );
  }
}