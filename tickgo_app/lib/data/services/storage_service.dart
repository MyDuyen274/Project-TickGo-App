import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Hàm 1: Mở thư viện và cho user chọn ảnh
  Future<File?> pickImage() async {
    // Mở thư viện ảnh (muốn mở camera thì đổi thành ImageSource.camera)
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      return File(pickedFile.path); // Trả về cái file ảnh user vừa chọn
    }
    return null; // Trả về null nếu user bấm Hủy
  }

  // Hàm 2: Nhận file ảnh và đẩy lên Firebase Storage
  Future<String?> uploadImage(File imageFile, String folderName) async {
    try {
      // 1. Tạo một cái tên file ngẫu nhiên để không bị trùng (dùng thời gian hiện tại)
      String fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
      
      // 2. Trỏ đường dẫn tới cái kho trên Firebase (Ví dụ: events/123456789.jpg)
      Reference ref = _storage.ref().child(folderName).child(fileName);

      // 3. Tiến hành đẩy file lên
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // 4. Lấy cái link web của ảnh sau khi đẩy thành công
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl; // Có link này rồi thì quăng vô Image.network() thôi!
    } catch (e) {
      print("Lỗi up ảnh rồi bồ ơi: $e");
      return null;
    }
  }
}