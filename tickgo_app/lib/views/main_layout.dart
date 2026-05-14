import 'package:flutter/material.dart';
import 'home/home_screen.dart'; 
import 'home/my_tickets_screen.dart'; 
import 'profile/profile_screen.dart'; 

class MainLayout extends StatefulWidget {
  final int initialIndex; // 👉 Thêm biến này để nhận lệnh nhảy tab
  const MainLayout({super.key, this.initialIndex = 0});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _selectedIndex; 

  final List<Widget> _screens = [
    const HomeScreen(), 
    const MyTicketsScreen(), 
    const ProfileScreen(), 
  ];

  @override
  void initState() {
    super.initState();
    // 👉 Gán tab mặc định bằng tab được truyền vào
    _selectedIndex = widget.initialIndex; 
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF203A43), 
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          elevation: 0, 
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.white, 
          unselectedItemColor: Colors.white60, 
          type: BottomNavigationBarType.fixed, 
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home)),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.confirmation_number_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.confirmation_number)),
              label: 'Vé của tôi',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_outline)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person)),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}