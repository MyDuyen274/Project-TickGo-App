import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // 👉 THÊM THƯ VIỆN FIREBASE STORAGE
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart'; 

import '../../data/services/api_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/location_picker_field.dart'; 
import 'map_picker_screen.dart'; 

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateRangeController = TextEditingController();
  final TextEditingController _timeFrameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String? _selectedLocationName;
  String? _selectedLocationAddress;
  String? _selectedCategoryId;
  int _selectedCategoryMaxTickets = 0; 
  String _selectedAgeRestriction = 'Mọi độ tuổi';
  final List<String> _ageOptions = ['Mọi độ tuổi', '12+', '16+', '18+', '21+'];

  List<Map<String, dynamic>> _ticketTypes = [
    {"name": "Vé Tiêu Chuẩn", "price": "0", "limit": "50"}
  ];

  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // 👉 BIẾN QUẢN LÝ ẢNH
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];

  void _addTicketType() {
    setState(() {
      _ticketTypes.add({"name": "", "price": "0", "limit": "10"});
    });
  }

  void _removeTicketType(int index) {
    if (_ticketTypes.length > 1) {
      setState(() { _ticketTypes.removeAt(index); });
    }
  }

  // 👉 HÀM CHỌN ẢNH TỪ THƯ VIỆN
  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((xfile) => File(xfile.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi chọn ảnh: $e")));
    }
  }

  // 👉 HÀM XÓA ẢNH ĐÃ CHỌN
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // 👉 HÀM UPLOAD ẢNH LÊN FIREBASE STORAGE (THAY THẾ CHO IMGBB)
  Future<List<String>> _uploadImagesToFirebase() async {
    List<String> downloadUrls = [];
    try {
      for (var file in _selectedImages) {
        // Tạo tên file ngẫu nhiên để không bị trùng lặp trên Storage
        String fileName = 'events/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        
        // Trỏ tới vị trí lưu trên Firebase
        Reference ref = FirebaseStorage.instance.ref().child(fileName);
        
        // Bắt đầu đẩy file
        UploadTask uploadTask = ref.putFile(file);
        TaskSnapshot snapshot = await uploadTask;
        
        // Lấy link URL trả về
        String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }
    } catch (e) {
      debugPrint("Lỗi upload Firebase Storage: $e");
      throw "Không thể tải ảnh lên hệ thống. Hãy kiểm tra lại kết nối mạng hoặc quyền Storage.";
    }
    return downloadUrls;
  }

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

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      helpText: 'CHỌN NGÀY (CHẠM 2 LẦN NẾU CHỈ 1 NGÀY)',
    );
    if (pickedRange != null) {
      String start = "${pickedRange.start.day}/${pickedRange.start.month}/${pickedRange.start.year}";
      String end = "${pickedRange.end.day}/${pickedRange.end.month}/${pickedRange.end.year}";
      setState(() => _dateRangeController.text = start == end ? start : "$start - $end");
    }
  }

  Future<void> _selectTimeFrame(BuildContext context) async {
    final TimeOfDay? startTime = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0), helpText: 'GIỜ BẮT ĐẦU');
    if (startTime != null && mounted) {
      final TimeOfDay? endTime = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 22, minute: 0), helpText: 'GIỜ KẾT THÚC');
      if (endTime != null) {
        String sTime = "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}";
        String eTime = "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";
        setState(() => _timeFrameController.text = "$sTime - $eTime");
      }
    }
  }

  void _submitEvent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bạn cần đăng nhập để tạo sự kiện.")));
      return;
    }

    String title = _titleController.text.trim();
    String dateRange = _dateRangeController.text.trim();
    String timeFrame = _timeFrameController.text.trim();
    
    int totalTickets = 0;
    for (var t in _ticketTypes) {
      totalTickets += int.tryParse(t['limit'].toString()) ?? 0;
    }

    if (title.isEmpty || _selectedLocationName == null || dateRange.isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng điền đủ thông tin (*)")));
      return;
    }

    if (totalTickets > _selectedCategoryMaxTickets) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Tổng số vé ($totalTickets) vượt quá giới hạn danh mục ($_selectedCategoryMaxTickets)!")));
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn ít nhất 1 hình ảnh sự kiện!"), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload mảng ảnh lên Firebase Storage
      List<String> uploadedUrls = await _uploadImagesToFirebase();
      
      // Ảnh đầu tiên sẽ làm ảnh bìa chính, các ảnh sau đưa vào thư viện ảnh
      String mainImageUrl = uploadedUrls.isNotEmpty ? uploadedUrls.first : "https://via.placeholder.com/800";

      // 2. Tạo Map dữ liệu để gửi lên server/Firestore
      Map<String, dynamic> newEvent = {
        "title": title,
        "location": "$_selectedLocationName - $_selectedLocationAddress",
        "date": dateRange,
        "timeFrame": timeFrame,
        "price": _ticketTypes[0]['price'], 
        "ticketLimit": totalTickets, 
        "availableTickets": totalTickets, 
        "soldCount": 0,
        "categoryId": _selectedCategoryId, 
        "ageRestriction": _selectedAgeRestriction,
        "organizerId": user.uid, 
        "imageUrl": mainImageUrl, // Ảnh bìa chính
        "galleryUrls": uploadedUrls, // Toàn bộ mảng ảnh
        "description": _descController.text.trim(),
        "ticketTypes": _ticketTypes, 
      };

      // 3. Gọi API lưu sự kiện
      bool success = await _apiService.createEvent(newEvent);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🎉 Tạo sự kiện thành công!"), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      } else {
        throw "Lỗi server khi lưu sự kiện.";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateRangeController.dispose();
    _timeFrameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1976D2);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text("Tạo Sự Kiện", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // KHU VỰC 1: THÔNG TIN CHUNG
            _buildSectionCard("Thông kết cơ bản", Icons.info_outline, [
              CustomTextField(controller: _titleController, label: "Tên sự kiện (*)", icon: Icons.event_note),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              _buildAgeDropdown(),
              LocationPickerField(locationName: _selectedLocationName, locationAddress: _selectedLocationAddress, onTap: () => _selectLocation(context)),
              const SizedBox(height: 16),
              CustomTextField(controller: _dateRangeController, label: "Khoảng ngày (*)", icon: Icons.date_range, readOnly: true, onTap: () => _selectDateRange(context)),
              const SizedBox(height: 16),
              CustomTextField(controller: _timeFrameController, label: "Khung giờ (*)", icon: Icons.access_time, readOnly: true, onTap: () => _selectTimeFrame(context)),
            ]),

            const SizedBox(height: 24),

            // KHU VỰC 2: CẤU HÌNH NHIỀU LOẠI VÉ
            _buildSectionCard("Cấu hình loại vé", Icons.confirmation_number_outlined, [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ticketTypes.length,
                itemBuilder: (context, index) {
                  return _buildTicketTypeItem(index);
                },
              ),
              TextButton.icon(
                onPressed: _addTicketType, 
                icon: const Icon(Icons.add), 
                label: const Text("Thêm loại vé khác"),
              )
            ]),

            const SizedBox(height: 24),

            // KHU VỰC 3: CHI TIẾT & HÌNH ẢNH
            _buildSectionCard("Chi tiết & Hình ảnh", Icons.image_outlined, [
              const Text("Hình ảnh sự kiện (*)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ..._selectedImages.asMap().entries.map((entry) {
                    int idx = entry.key;
                    File file = entry.value;
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(file, width: 100, height: 100, fit: BoxFit.cover),
                        ),
                        Positioned(
                          right: -5, top: -5,
                          child: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 16)
                            ),
                            onPressed: () => _removeImage(idx),
                          )
                        )
                      ],
                    );
                  }).toList(),
                  
                  InkWell(
                    onTap: _pickImages,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200, style: BorderStyle.solid),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, color: Colors.blue),
                          SizedBox(height: 4),
                          Text("Thêm ảnh", style: TextStyle(color: Colors.blue, fontSize: 12))
                        ],
                      ),
                    ),
                  )
                ],
              ),
              
              const SizedBox(height: 20),
              CustomTextField(controller: _descController, label: "Mô tả chi tiết sự kiện", icon: Icons.description_outlined, maxLines: 4),
            ]),

            const SizedBox(height: 32),
            _isLoading 
              ? const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text("Đang tải ảnh và lưu sự kiện...", style: TextStyle(color: Colors.grey))
                  ],
                ) 
              : ElevatedButton(
                  onPressed: _submitEvent, 
                  style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, minimumSize: const Size(double.infinity, 56)),
                  child: const Text("XUẤT BẢN SỰ KIỆN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: const Color(0xFF1976D2)), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 20),
          ...children
        ],
      ),
    );
  }

  Widget _buildTicketTypeItem(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: TextField(
                decoration: const InputDecoration(hintText: "Tên vé (VD: VIP, Thường)", border: UnderlineInputBorder()),
                onChanged: (v) => _ticketTypes[index]['name'] = v,
              )),
              IconButton(onPressed: () => _removeTicketType(index), icon: const Icon(Icons.delete_outline, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: "Giá tiền", suffixText: "đ", border: OutlineInputBorder()),
                onChanged: (v) => _ticketTypes[index]['price'] = v,
              )),
              const SizedBox(width: 10),
              Expanded(child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: "SL vé", suffixIcon: Icon(Icons.people, size: 16), border: OutlineInputBorder()),
                onChanged: (v) => _ticketTypes[index]['limit'] = v,
              )),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').orderBy('order').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(); 
        var categories = snapshot.data!.docs;
        return DropdownButtonFormField<String>(
          value: _selectedCategoryId,
          decoration: InputDecoration(
            labelText: 'Danh mục sự kiện (*)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: categories.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat['name']))).toList(),
          onChanged: (val) {
            var selectedDoc = categories.firstWhere((doc) => doc.id == val);
            setState(() {
              _selectedCategoryId = val;
              _selectedCategoryMaxTickets = (selectedDoc.data() as Map<String, dynamic>)['maxTickets'] ?? 1000;
            });
          },
        );
      },
    );
  }

  Widget _buildAgeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedAgeRestriction,
      decoration: InputDecoration(
        labelText: 'Độ tuổi cho phép (*)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _ageOptions.map((age) => DropdownMenuItem(value: age, child: Text(age))).toList(),
      onChanged: (val) => setState(() => _selectedAgeRestriction = val!),
    );
  }
}