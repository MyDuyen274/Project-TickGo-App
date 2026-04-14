import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/location_picker_field.dart'; // Nút địa điểm tách riêng
import 'map_picker_screen.dart'; // Màn hình Bản đồ (OpenStreetMap)

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  // Các controller cho TextFields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateRangeController = TextEditingController();
  final TextEditingController _timeFrameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // Biến lưu Địa điểm sau khi chọn từ Bản đồ
  String? _selectedLocationName;
  String? _selectedLocationAddress;

  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // ==========================================
  // 1. MỞ MÀN HÌNH BẢN ĐỒ
  // ==========================================
  Future<void> _selectLocation(BuildContext context) async {
    final selectedLoc = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );

    if (selectedLoc != null) {
      setState(() {
        _selectedLocationName = selectedLoc["name"];
        _selectedLocationAddress = selectedLoc["address"];
      });
    }
  }

  // ==========================================
  // 2. CHỌN KHOẢNG NGÀY (LỊCH NỔI POPUP)
  // ==========================================
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      helpText: 'CHỌN THỜI GIAN DIỄN RA',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
      saveText: 'XONG',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976D2), // Màu Xanh chủ đạo
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
              child: child,
            ),
          ),
        );
      },
    );

    if (pickedRange != null) {
      String start = "${pickedRange.start.day}/${pickedRange.start.month}/${pickedRange.start.year}";
      String end = "${pickedRange.end.day}/${pickedRange.end.month}/${pickedRange.end.year}";
      setState(() => _dateRangeController.text = start == end ? start : "$start - $end");
    }
  }

  // ==========================================
  // 3. CHỌN KHUNG GIỜ (TỪ GIỜ -> ĐẾN GIỜ)
  // ==========================================
  Future<void> _selectTimeFrame(BuildContext context) async {
    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: 'CHỌN GIỜ BẮT ĐẦU',
    );

    if (startTime != null && context.mounted) {
      final TimeOfDay? endTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 22, minute: 0),
        helpText: 'CHỌN GIỜ KẾT THÚC',
      );

      if (endTime != null) {
        String sTime = "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}";
        String eTime = "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";
        setState(() => _timeFrameController.text = "$sTime - $eTime");
      }
    }
  }

  // ==========================================
  // 4. GỬI DỮ LIỆU LÊN SERVER NODE.JS
  // ==========================================
  void _submitEvent() async {
    String title = _titleController.text.trim();
    String dateRange = _dateRangeController.text.trim();
    String timeFrame = _timeFrameController.text.trim();
    String price = _priceController.text.trim();

    // Validate (Kiểm tra nhập đủ)
    if (title.isEmpty || _selectedLocationName == null || dateRange.isEmpty || timeFrame.isEmpty || price.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng điền đủ thông tin bắt buộc (*)"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    String fullLocation = "$_selectedLocationName - $_selectedLocationAddress";

    Map<String, dynamic> newEvent = {
      "title": title,
      "location": fullLocation,
      "date": dateRange,
      "timeFrame": timeFrame,
      "price": price,
      "imageUrl": _imageController.text.trim().isNotEmpty
          ? _imageController.text.trim()
          : "https://images.unsplash.com/photo-1540039155733-5bb30b53aa14",
      "description": _descController.text.trim(),
    };

    bool success = await _apiService.createEvent(newEvent);
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tạo sự kiện thành công! 🎉"), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); // Đóng trang và trả về `true` cho Home Reload
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi tạo sự kiện. Vui lòng thử lại!"), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1976D2);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Tạo Sự Kiện", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600), // Không bị dãn trên web
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  
                  // ==============================
                  // KHU VỰC 1: THÔNG TIN CƠ BẢN
                  // ==============================
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: primaryBlue),
                            SizedBox(width: 8),
                            Text("Thông tin cơ bản", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        CustomTextField(
                          controller: _titleController,
                          label: "Tên sự kiện (*)",
                          icon: Icons.event_note,
                          hint: "VD: Lễ Hội Mùa Hè 2026",
                        ),
                        const SizedBox(height: 16),

                        // Gọi Widget Địa điểm vừa tách ra
                        LocationPickerField(
                          locationName: _selectedLocationName,
                          locationAddress: _selectedLocationAddress,
                          onTap: () => _selectLocation(context),
                        ),
                        const SizedBox(height: 16),

                        CustomTextField(
                          controller: _dateRangeController,
                          label: "Khoảng ngày (*)",
                          icon: Icons.date_range,
                          readOnly: true,
                          onTap: () => _selectDateRange(context),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: CustomTextField(
                                controller: _timeFrameController,
                                label: "Khung giờ (*)",
                                icon: Icons.access_time,
                                readOnly: true,
                                onTap: () => _selectTimeFrame(context),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: CustomTextField(
                                controller: _priceController,
                                label: "Giá vé (VNĐ)",
                                icon: Icons.payments_outlined,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ==============================
                  // KHU VỰC 2: CHI TIẾT & HÌNH ẢNH
                  // ==============================
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.image_outlined, color: primaryBlue),
                            SizedBox(width: 8),
                            Text("Chi tiết & Hình ảnh", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        CustomTextField(
                          controller: _imageController,
                          label: "Link ảnh bìa (URL)",
                          icon: Icons.link,
                        ),
                        const SizedBox(height: 16),

                        CustomTextField(
                          controller: _descController,
                          label: "Mô tả sự kiện",
                          icon: Icons.description_outlined,
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ==============================
                  // NÚT XUẤT BẢN
                  // ==============================
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          onPressed: _submitEvent,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text("XUẤT BẢN SỰ KIỆN", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}