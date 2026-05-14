import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../home/create_event_screen.dart'; 
import '../home/event_detail_screen.dart'; 

class EventManagementScreen extends StatelessWidget {
  const EventManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = const Color(0xFF1E1E1E); 
    final Color cardColor = const Color(0xFF2C2C2E);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        title: const Text('Quản lý sự kiện', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white), 
        centerTitle: true,
        actions: [
          // 👉 ĐÃ SỬA: Bấm vào đây sẽ mở trang Quản lý Danh Mục
          IconButton(
            icon: const Icon(Icons.category, color: Colors.orange),
            tooltip: 'Quản lý danh mục',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryManagementScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateEventScreen()));
        },
        backgroundColor: const Color(0xFF4CAF50),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tạo sự kiện", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.green));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Chưa có sự kiện nào", style: TextStyle(color: Colors.white70, fontSize: 16)));
          }

          var events = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              var eventDoc = events[index];
              var data = eventDoc.data() as Map<String, dynamic>; 
              return _buildEventItem(context, eventDoc.id, data, cardColor);
            },
          );
        },
      ),
    );
  }

  Widget _buildEventItem(BuildContext context, String eventId, Map<String, dynamic> data, Color cardColor) {
    String title = data['title'] ?? 'Sự kiện chưa có tên';
    String date = data['date'] ?? 'Đang cập nhật';
    String price = data['price']?.toString() ?? '0'; 
    String imageUrl = data['imageUrl'] ?? ''; 

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailScreen(eventData: data))),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 60, height: 60, color: Colors.grey.shade800, 
            child: imageUrl.isNotEmpty 
                ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white54))
                : const Icon(Icons.image, color: Colors.white54), 
          ), 
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text("📅 $date  |  🎟️ $price đ", style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_document, color: Colors.orange),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditEventScreen(eventId: eventId, eventData: data))),
        ),
      ),
    );
  }
}

// ==========================================
// MÀN HÌNH QUẢN LÝ DANH MỤC (THÊM, SỬA, XÓA)
// ==========================================
class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  void _showCategoryDialog(BuildContext context, {String? docId, String? currentName}) {
    TextEditingController controller = TextEditingController(text: currentName ?? '');
    bool isEditing = docId != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: Text(isEditing ? "Sửa danh mục" : "Tạo danh mục mới", style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Tên danh mục...", hintStyle: const TextStyle(color: Colors.grey),
            filled: true, fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                if (isEditing) {
                  await FirebaseFirestore.instance.collection('categories').doc(docId).update({'name': controller.text});
                } else {
                  await FirebaseFirestore.instance.collection('categories').add({
                    'name': controller.text, 'order': DateTime.now().millisecondsSinceEpoch, 
                  });
                }
                Navigator.pop(context);
              }
            },
            child: const Text("Lưu", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _deleteCategory(BuildContext context, String docId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text("Xóa danh mục?", style: TextStyle(color: Colors.red)),
        content: const Text("Xóa danh mục này sẽ không xóa sự kiện, nhưng sự kiện sẽ bị mất phân loại. Tiếp tục?", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text("Xóa")),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('categories').doc(docId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text("Quản lý danh mục", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').orderBy('order').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.orange));
          var categories = snapshot.data!.docs;
          if (categories.isEmpty) return const Center(child: Text("Chưa có danh mục", style: TextStyle(color: Colors.grey)));

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              var cat = categories[index];
              return Card(
                color: const Color(0xFF2C2C2E),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(cat['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showCategoryDialog(context, docId: cat.id, currentName: cat['name'])),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteCategory(context, cat.id)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// MÀN HÌNH CHỈNH SỬA VÀ XÓA SỰ KIỆN THẬT (GIỮ NGUYÊN CODE CŨ CỦA ÔNG)
// ==========================================
class EditEventScreen extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;
  const EditEventScreen({super.key, required this.eventId, required this.eventData});
  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  late TextEditingController _titleController;
  late TextEditingController _dateController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;
  late TextEditingController _descController;
  String? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.eventData['title'] ?? '');
    _dateController = TextEditingController(text: widget.eventData['date'] ?? '');
    _priceController = TextEditingController(text: widget.eventData['price']?.toString() ?? '');
    _imageController = TextEditingController(text: widget.eventData['imageUrl'] ?? '');
    _descController = TextEditingController(text: widget.eventData['description'] ?? '');
    _selectedCategoryId = widget.eventData['categoryId'];
  }

  @override
  void dispose() {
    _titleController.dispose(); _dateController.dispose(); _priceController.dispose();
    _imageController.dispose(); _descController.dispose();
    super.dispose();
  }

  Future<void> _updateEvent() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('events').doc(widget.eventId).update({
        'title': _titleController.text, 'date': _dateController.text, 'price': double.tryParse(_priceController.text) ?? 0,
        'imageUrl': _imageController.text, 'description': _descController.text, 'categoryId': _selectedCategoryId,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Đã cập nhật thành công!')));
      Navigator.pop(context);
    } finally { setState(() => _isLoading = false); }
  }

  Future<void> _deleteEvent() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text("Xóa sự kiện?", style: TextStyle(color: Colors.red)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text("Xóa luôn", style: TextStyle(color: Colors.white)))
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('events').doc(widget.eventId).delete();
      Navigator.pop(context); 
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {int lines = 1, TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller, style: const TextStyle(color: Colors.white), maxLines: lines, keyboardType: type,
        decoration: InputDecoration(
          labelText: label, labelStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: const Color(0xFF2C2C2E),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2E), title: const Text("Chỉnh sửa sự kiện", style: TextStyle(color: Colors.white, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _deleteEvent)],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.orange))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField("Tên sự kiện", _titleController), _buildTextField("Thời gian", _dateController),
                _buildTextField("Giá vé (VNĐ)", _priceController, type: TextInputType.number), _buildTextField("Link ảnh bìa", _imageController),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('categories').orderBy('order').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    var categories = snapshot.data!.docs;
                    if (!categories.any((doc) => doc.id == _selectedCategoryId)) _selectedCategoryId = null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: 'Danh mục', labelStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: const Color(0xFF2C2C2E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                        dropdownColor: const Color(0xFF2C2C2E), style: const TextStyle(color: Colors.white), value: _selectedCategoryId,
                        items: categories.map((cat) => DropdownMenuItem<String>(value: cat.id, child: Text(cat['name']))).toList(),
                        onChanged: (val) => setState(() => _selectedCategoryId = val),
                      ),
                    );
                  },
                ),
                _buildTextField("Giới thiệu chi tiết", _descController, lines: 5),
                const SizedBox(height: 20),
                ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: _updateEvent, child: const Text("LƯU CẬP NHẬT", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))
              ],
            ),
          ),
    );
  }
}