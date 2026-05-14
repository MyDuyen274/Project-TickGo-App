import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 

// 👉 CÁC FILE IMPORT (Bồ nhớ kiểm tra lại đường dẫn cho khớp với máy bồ nha)
import '../event/event_management_screen.dart'; 
import 'account_info_screen.dart'; 

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = const Color(0xFF1E1E1E); 
    final Color cardColor = const Color(0xFF2C2C2E);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1 & 2. PHẦN HEADER VÀ TÊN KÈM AVATAR
            // ==========================================
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                String userName = "Đang tải..."; 
                String initial = "U"; 
                String? avatarUrl; // 👉 THÊM BIẾN LƯU LINK ẢNH

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  
                  userName = data['name'] ?? data['full_name'] ?? "Người dùng";
                  avatarUrl = data['avatarUrl']; // 👉 LẤY LINK ẢNH TỪ FIREBASE
                  
                  if (userName.isNotEmpty) {
                    initial = userName[0].toUpperCase();
                  }
                }

                return Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Khung nền xanh
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50), 
                          ),
                        ),
                        // Avatar vuông bo góc 
                        Positioned(
                          bottom: -45, 
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD81B60), // Màu nền hồng
                              borderRadius: BorderRadius.circular(24),
                            ),
                            alignment: Alignment.center,
                            // 👉 DÙNG CLIPRRECT ĐỂ BO GÓC BỨC ẢNH VỪA KHÍT VỚI KHUNG
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: (avatarUrl != null && avatarUrl.trim().isNotEmpty)
                                  ? Image.network(
                                      avatarUrl,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                      // Rớt mạng hoặc lỗi thì hiện lại chữ cái
                                      errorBuilder: (context, error, stackTrace) => Text(
                                        initial, 
                                        style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  : Text(
                                      initial, // Không có ảnh thì hiện chữ cái
                                      style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 55), 

                    // Tên User thật
                    Center(
                      child: Text(
                        userName, 
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),

            // 3. Thẻ thành viên & Theo dõi
            _buildInfoSection(Icons.diamond_outlined, Colors.amber, 'Thẻ thành viên của tôi', 'Bạn chưa có thẻ thành viên'),
            const SizedBox(height: 20),
            _buildInfoSection(Icons.star, Colors.amber, 'Đang theo dõi', 'Bạn chưa có danh sách theo dõi'),
            const SizedBox(height: 30),

            // 4. Cài đặt tài khoản
            _buildSectionTitle(Icons.person, 'Cài đặt tài khoản'),
            _buildMenuCard(
              cardColor,
              [
                _buildListTile(
                  'Thông tin tài khoản',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AccountInfoScreen()),
                    );
                  }
                ),
                _buildDivider(),
                _buildListTile('Thiết lập mã PIN'),
                _buildDivider(),
                _buildListTile('Cài đặt thông báo'),
              ],
            ),
            const SizedBox(height: 20),

            // 5. Cài đặt ứng dụng
            _buildSectionTitle(Icons.settings, 'Cài đặt ứng dụng'),
            _buildMenuCard(
              cardColor,
              [
                ListTile(
                  title: const Text('Thay đổi ngôn ngữ', style: TextStyle(color: Colors.white)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.yellow, size: 16),
                        SizedBox(width: 4),
                        Text('Vie', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 6. Dành cho Ban tổ chức
            _buildSectionTitle(Icons.admin_panel_settings, 'Dành cho Ban tổ chức'),
            _buildMenuCard(
              cardColor,
              [
                _buildListTile(
                  'Quản lý sự kiện',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EventManagementScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 7. Phiên bản
            const Center(
              child: Text('Phiên bản 3.1.37(30370)', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            const SizedBox(height: 40), 
          ],
        ),
      ),
    );
  }

  // --- CÁC WIDGET DÙNG CHUNG ---
  Widget _buildInfoSection(IconData icon, Color iconColor, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMenuCard(Color bgColor, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12), 
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildListTile(String title, {VoidCallback? onTap}) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: onTap, 
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: Colors.grey, 
      height: 1, 
      thickness: 0.2, 
      indent: 16, 
      endIndent: 16, 
    );
  }
}