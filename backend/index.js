const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');

// 1. Khởi tạo App Express
const app = express();
app.use(cors());
app.use(express.json()); // Để server hiểu được data dạng JSON gửi lên

// 2. Nạp "chìa khóa vạn năng" (Đảm bảo file serviceAccountKey.json nằm cùng thư mục)
const serviceAccount = require('./serviceAccountKey.json');

// 3. Khởi tạo Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Kết nối với Firestore Database
const db = admin.firestore();

// ==========================================
// KHU VỰC TẠO CÁC API (CỔNG GIAO TIẾP)
// ==========================================

// API Test: Bắn thử một câu chào để xem server có chạy không
app.get('/api/test', (req, res) => {
  res.json({ message: "Server Node.js cho TickGo đang hoạt động cực mượt! 🚀" });
});

// API Thử nghiệm: Lấy danh sách toàn bộ người dùng (Bỏ qua luật bảo mật của Flutter)
app.get('/api/users', async (req, res) => {
  try {
    const snapshot = await db.collection('users').get();
    const users = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ error: "Lỗi khi lấy dữ liệu: " + error.message });
  }
});

// ==========================================
// KHỞI ĐỘNG SERVER
// ==========================================
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`✅ Server Backend đang chạy tại: http://localhost:${PORT}`);
  console.log(`✅ Firebase Admin kết nối thành công!`);
});
// ==========================================
// API SỰ KIỆN (EVENTS)
// ==========================================

// 1. API Tạo sự kiện mới (Thường dành cho Admin)
app.post('/api/events', async (req, res) => {
  try {
    // Nhận dữ liệu từ điện thoại/web gửi lên
    const { title, date, price, imageUrl, description } = req.body;

    // Kiểm tra xem có gửi thiếu thông tin không
    if (!title || !date || !price) {
      return res.status(400).json({ error: "Vui lòng nhập đủ Tên, Ngày và Giá vé!" });
    }

    // Đóng gói dữ liệu
    const newEvent = {
      title: title,
      date: date,
      price: Number(price), // Đảm bảo giá là số
      imageUrl: imageUrl || "https://via.placeholder.com/400", // Ảnh mặc định nếu thiếu
      description: description || "Sự kiện siêu hấp dẫn tại TickGo!",
      createdAt: admin.firestore.FieldValue.serverTimestamp(), // Giờ hệ thống chuẩn
    };

    // Đẩy lên Firestore
    const docRef = await db.collection('events').add(newEvent);
    
    // Báo cáo thành công
    res.status(201).json({ 
      message: "Tạo sự kiện thành công!", 
      eventId: docRef.id 
    });

  } catch (error) {
    res.status(500).json({ error: "Lỗi khi tạo sự kiện: " + error.message });
  }
});


// 2. API Lấy danh sách sự kiện (Để hiển thị ở trang chủ Flutter)
app.get('/api/events', async (req, res) => {
  try {
    // Kéo dữ liệu từ collection 'events', sắp xếp mới nhất lên đầu
    const snapshot = await db.collection('events').orderBy('createdAt', 'desc').get();
    
    // Gói gém lại cho đẹp
    const events = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    // Gửi trả về cho app Flutter
    res.status(200).json(events);

  } catch (error) {
    res.status(500).json({ error: "Lỗi khi tải danh sách: " + error.message });
  }
});