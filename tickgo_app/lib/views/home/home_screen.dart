import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/api_service.dart';
import '../auth/login_screen.dart';
import 'create_event_screen.dart';
import '../../widgets/event_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _loadEvents(); // Tải dữ liệu ngay khi mở trang
  }

  // Hàm gọi API lấy sự kiện từ Node.js
  void _loadEvents() {
    setState(() {
      _eventsFuture = _apiService.fetchEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1976D2);

    return Scaffold(
      backgroundColor: Colors.white, // Nền trắng tinh khôi
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // Bỏ bóng đổ cho phẳng
        title: const Text(
          "TickGo", 
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: -0.5)
        ),
        actions: [
          // Nút Làm mới danh sách
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87), 
            onPressed: _loadEvents
          ),
          // Nút Đăng xuất
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context, 
                  MaterialPageRoute(builder: (context) => const LoginScreen())
                );
              }
            },
          ),
        ],
      ),
      
      // FutureBuilder tự động quản lý trạng thái Tải/Lỗi/Thành công
      body: FutureBuilder<List<dynamic>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          // 1. Trạng thái Đang tải
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // 2. Trạng thái Lỗi kết nối
          if (snapshot.hasError) {
            return const Center(
              child: Text("Không thể kết nối đến máy chủ Node.js!")
            );
          }
          
          // 3. Trạng thái Không có dữ liệu
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Chưa có sự kiện nào sắp diễn ra", style: TextStyle(color: Colors.grey, fontSize: 16))
            );
          }

          // 4. Có dữ liệu -> Hiển thị danh sách Lưới
          var events = snapshot.data!;

          // Căn giữa toàn bộ trang web và giới hạn chiều rộng
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200), // Chiều rộng tối đa chuẩn Web
              child: CustomScrollView(
                slivers: [
                  // Banner hoặc Tiêu đề mục "Sự kiện nổi bật"
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Sự kiện nổi bật",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text("Xem tất cả >", style: TextStyle(color: Colors.grey)),
                          )
                        ],
                      ),
                    ),
                  ),

                  // Lưới hiển thị sự kiện (Tự động chia cột theo kích thước màn hình)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300, // Chiều rộng tối đa của 1 thẻ
                        mainAxisSpacing: 30, // Khoảng cách dọc giữa các thẻ
                        crossAxisSpacing: 20, // Khoảng cách ngang giữa các thẻ
                        childAspectRatio: 0.75, // Tỷ lệ Chiều rộng / Chiều cao để chữ không bị cắt
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          var eventData = events[index];
                          return EventCard(
                            title: eventData['title'] ?? 'Chưa có tên',
                            imageUrl: eventData['imageUrl'] ?? 'https://via.placeholder.com/400',
                            date: eventData['date'] ?? 'Đang cập nhật',
                            price: eventData['price'].toString(),
                            onTap: () {
                              // Tạm thời báo thông báo, sau này sẽ mở trang Chi tiết
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Mở sự kiện: ${eventData['title']}"))
                              );
                            },
                          );
                        },
                        childCount: events.length, // Số lượng sự kiện
                      ),
                    ),
                  ),
                  
                  // Chừa một khoảng trống dưới cùng để cuộn không bị vướng nút FAB
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
          );
        },
      ),

      // NÚT TẠO SỰ KIỆN NẰM NỔI BÊN DƯỚI GÓC PHẢI
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tạo sự kiện", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () async {
          // Chuyển sang trang Tạo sự kiện và chờ đợi kết quả trả về
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateEventScreen()),
          );
          
          // Nếu trang Tạo sự kiện trả về "true" (tức là tạo thành công), thì load lại danh sách
          if (result == true) {
            _loadEvents(); 
          }
        },
      ),
    );
  }
}