import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';
import 'event_detail_screen.dart';
import '../../widgets/event_card.dart'; // Đảm bảo import đúng đường dẫn Widget của bạn

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _eventsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    // Khởi tạo việc tải dữ liệu ngay khi mở màn hình tìm kiếm
    _eventsFuture = _apiService.fetchEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: TextField(
          controller: _searchController,
          autofocus: true, // Tự động bật bàn phím
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
          decoration: InputDecoration(
            hintText: "Tìm sự kiện, địa điểm...",
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = "");
                    },
                  )
                : null,
          ),
        ),
      ),
      body: _buildSearchResults(),
    );
  }

  Widget _buildSearchResults() {
    // Nếu chưa gõ gì thì hiện gợi ý hoặc thông báo trống
    if (_searchQuery.isEmpty) {
      return const Center(
        child: Text("Hãy nhập từ khóa để tìm kiếm sự kiện", style: TextStyle(color: Colors.grey)),
      );
    }

    return FutureBuilder<List<dynamic>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allEvents = snapshot.data ?? [];

        // Lọc sự kiện dựa trên từ khóa
        final filteredEvents = allEvents.where((event) {
          final title = (event['title'] ?? '').toString().toLowerCase();
          final location = (event['location'] ?? '').toString().toLowerCase();
          final desc = (event['description'] ?? '').toString().toLowerCase();

          return title.contains(_searchQuery) ||
                 location.contains(_searchQuery) ||
                 desc.contains(_searchQuery);
        }).toList();

        // Hiển thị thông báo nếu không tìm thấy
        if (filteredEvents.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "Không có sự kiện nào phù hợp với '$_searchQuery'.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        // Hiển thị danh sách kết quả (dùng GridView giống ở trang chủ)
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, 
            crossAxisSpacing: 15, 
            mainAxisSpacing: 15, 
            childAspectRatio: 0.75
          ),
          itemCount: filteredEvents.length,
          itemBuilder: (context, index) {
            final eventData = filteredEvents[index];
            return EventCard(
              title: eventData['title'],
              imageUrl: eventData['imageUrl'],
              date: eventData['date'] ?? "",
              price: eventData['price'].toString(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EventDetailScreen(eventData: eventData))
                );
              }
            );
          },
        );
      },
    );
  }
}