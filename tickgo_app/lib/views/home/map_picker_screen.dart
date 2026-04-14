import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  // Tọa độ mặc định (TP.HCM)
  LatLng _centerPosition = const LatLng(10.762622, 106.660172);
  final MapController _mapController = MapController();
  bool _isLoadingAddress = false;

  // ==========================================
  // BIẾN CHO THANH TÌM KIẾM
  // ==========================================
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  // ==========================================
  // HÀM TÌM KIẾM ĐỊA ĐIỂM (API MIỄN PHÍ)
  // ==========================================
  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    // API của Nominatim (Giới hạn countrycodes=vn để chỉ tìm ở Việt Nam cho chuẩn)
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5&countrycodes=vn');

    try {
      final response = await http.get(url, headers: {'User-Agent': 'TickGoApp/1.0'});
      if (response.statusCode == 200) {
        setState(() {
          _searchResults = json.decode(response.body);
        });
      }
    } catch (e) {
      print("Lỗi tìm kiếm: $e");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  // ==========================================
  // HÀM BAY ĐẾN VỊ TRÍ ĐÃ TÌM THẤY
  // ==========================================
  void _moveToLocation(double lat, double lon) {
    final newPosition = LatLng(lat, lon);
    _mapController.move(newPosition, 16.0); // Zoom lại gần (mức 16)
    
    setState(() {
      _centerPosition = newPosition;
      _searchResults = []; // Chọn xong thì giấu danh sách đi
      _searchController.clear(); // Xóa chữ trong ô search
    });
    
    // Đóng bàn phím ảo
    FocusScope.of(context).unfocus();
  }

  // ==========================================
  // HÀM DỊCH TỌA ĐỘ THÀNH ĐỊA CHỈ ĐỂ LƯU
  // ==========================================
  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() => _isLoadingAddress = true);

    final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1');

    try {
      final response = await http.get(url, headers: {'Accept-Language': 'vi', 'User-Agent': 'TickGoApp/1.0'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['display_name'] ?? "Không tìm thấy địa chỉ chi tiết";
        
        final name = data['name']?.toString().isNotEmpty == true 
            ? data['name'] 
            : "Vị trí đã ghim trên bản đồ";

        if (!mounted) return;
        Navigator.pop(context, {"name": name, "address": address});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi mạng, không thể lấy địa chỉ!")));
    } finally {
      setState(() => _isLoadingAddress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chọn vị trí sự kiện", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Stack(
        children: [
          // 1. LỚP BẢN ĐỒ
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centerPosition,
              initialZoom: 15.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && position.center != null) {
                  setState(() => _centerPosition = position.center!);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.tickgo_app',
              ),
            ],
          ),

          // 2. CÁI GHIM TÂM BẢN ĐỒ
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40.0),
              child: Icon(Icons.location_on, size: 50, color: Colors.redAccent),
            ),
          ),

          // 3. NÚT XÁC NHẬN BÊN DƯỚI
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _isLoadingAddress
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () => _getAddressFromLatLng(_centerPosition),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                    ),
                    child: const Text("📍 CHỌN VỊ TRÍ NÀY", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
          ),

          // 4. THANH TÌM KIẾM NỔI Ở TRÊN CÙNG
          Positioned(
            top: 15,
            left: 15,
            right: 15,
            child: Column(
              children: [
                // Ô Nhập liệu
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                  ),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search, // Hiển thị nút Kính lúp trên bàn phím
                    onSubmitted: _searchLocation, // Bấm Enter để tìm
                    decoration: InputDecoration(
                      hintText: "Tìm đường, tòa nhà, quận...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _isSearching
                          ? const Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2))
                          : IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),

                // Danh sách kết quả thả xuống
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 250), // Giới hạn chiều cao danh sách
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final place = _searchResults[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on, color: Color(0xFF1976D2)),
                          title: Text(
                            place['display_name'] ?? "", 
                            maxLines: 2, 
                            overflow: TextOverflow.ellipsis, 
                            style: const TextStyle(fontSize: 14)
                          ),
                          onTap: () {
                            // Khi bấm vào 1 kết quả -> Di chuyển bản đồ tới đó
                            final lat = double.parse(place['lat']);
                            final lon = double.parse(place['lon']);
                            _moveToLocation(lat, lon);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}