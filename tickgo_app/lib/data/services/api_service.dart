import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // THAY DÃY SỐ NÀY BẰNG ĐỊA CHỈ IPV4 MÁY NHÉ!
  static const String baseUrl = 'https://patrological-tyron-unambitiously.ngrok-free.dev/api'; 

  // 1. Hàm LẤY danh sách sự kiện từ Node.js
  Future<List<dynamic>> fetchEvents() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/events'));

      if (response.statusCode == 200) {
        // Dịch dữ liệu JSON từ server thành List của Flutter
        return json.decode(response.body); 
      } else {
        throw Exception('Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      print("Lỗi kết nối API: $e");
      return [];
    }
  }

  // 2. Hàm TẠO sự kiện mới đẩy lên Node.js
  Future<bool> createEvent(Map<String, dynamic> eventData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/events'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(eventData),
      );

      if (response.statusCode == 201) {
        return true; // Tạo thành công
      } else {
        print("Lỗi tạo sự kiện: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Lỗi kết nối API: $e");
      return false;
    }
  }
}