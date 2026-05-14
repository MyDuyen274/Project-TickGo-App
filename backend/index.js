const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');

const app = express();
app.use(cors());
app.use(express.json());

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// ==========================================
// TỰ ĐỘNG NẠP DỮ LIỆU MẪU (SEED DATA)
// ==========================================
const seedData = async () => {
  try {
    const eventsRef = db.collection('events');
    const eventSnapshot = await eventsRef.get();
    if (eventSnapshot.empty) {
      const dummyEvents = [
        {
          title: "WORLD TOUR: TWICE READY TO BE",
          date: "19:00, 15/05/2026",
          location: "Hồ Chí Minh",
          price: 2500000,
          imageUrl: "https://picsum.photos/id/1025/600/400",
          description: "READY TO BE WORLD TOUR in VN.",
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        },
        {
          title: "ĐÊM NHẠC VŨ. & LÂN NHÃ",
          date: "20:00, Tối nay",
          location: "Đà Lạt",
          price: 450000,
          imageUrl: "https://picsum.photos/id/158/600/400",
          description: "Acoustic night.",
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        }
      ];
      for (const e of dummyEvents) await eventsRef.add(e);
      console.log("✅ Đã nạp Events mẫu!");
    }

    const userUID = "ckq4U85y3Ka9w4QCZgEVuFERlWY2"; 
    const userRef = db.collection('users').doc(userUID);
    const userDoc = await userRef.get();
    if (!userDoc.exists) {
      await userRef.set({
        full_name: "Minh Anh",
        email: "mmaa@gmail.com",
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
      console.log("✅ Đã tạo User mẫu có full_name!");
    }
  } catch (e) { console.log("Lỗi Seed Data: ", e); }
};

seedData();

// --- API ROUTES (Lấy danh sách sk) ---
app.get('/api/events', async (req, res) => {
  try {
    const snapshot = await db.collection('events').orderBy('createdAt', 'desc').get();
    const events = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.status(200).json(events);
  } catch (error) { res.status(500).json({ error: error.message }); }
});

// 👉 API Tạo sự kiện mới & Bắn thông báo (ĐÃ CẬP NHẬT)
app.post('/api/events', async (req, res) => {
  try {
    const eventData = req.body; 
    eventData.createdAt = admin.firestore.FieldValue.serverTimestamp();

    // 1. Lưu sự kiện vào Firestore
    const docRef = await db.collection('events').add(eventData);
    console.log(`✅ Đã tạo thành công sự kiện mới có ID: ${docRef.id}`);

    // 2. TẠO TIN NHẮN VÀ BẮN THÔNG BÁO TỚI KÊNH "new_events"
    try {
      const message = {
        notification: {
          title: "🔥 Sự kiện mới vừa mở bán!",
          // Lấy luôn tên sự kiện vừa tạo để nhét vào thông báo cho xịn
          body: `"${eventData.title}" đã có mặt trên TickGo. Đặt vé ngay kẻo lỡ!`
        },
        topic: "new_events" // Gửi tới tất cả user đã cài app
      };

      // Gọi lệnh bắn thông báo của Firebase Admin
      const response = await admin.messaging().send(message);
      console.log("🚀 Đã bắn thông báo Push Notification thành công:", response);
    } catch (fcmError) {
      // Dùng try-catch riêng ở đây để lỡ gửi thông báo xịt thì sự kiện vẫn được tạo thành công
      console.error("❌ Lỗi khi bắn thông báo:", fcmError);
    }

    // 3. Trả kết quả về cho Flutter
    res.status(201).json({ 
      message: "Tạo sự kiện và gửi thông báo thành công", 
      id: docRef.id,
      data: eventData 
    });
  } catch (error) { 
    console.error("❌ Lỗi tạo sự kiện: ", error);
    res.status(500).json({ error: error.message }); 
  }
});

const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Server chạy tại: http://localhost:${PORT}`);
});