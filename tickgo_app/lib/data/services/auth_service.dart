import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Hàm Đăng Ký
  Future<String?> signUp(String email, String password, String name, String phone) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': name,
        'email': email,
        'phone': phone, // Lưu thêm số điện thoại kèm mã vùng
        'createdAt': DateTime.now(),
      });
      return "Success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // 2. Hàm Đăng Nhập
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "Success";
    } on FirebaseAuthException catch (e) {
      return e.message; // Trả về lỗi (vd: sai mật khẩu)
    } catch (e) {
      return e.toString();
    }
  }

  // 3. Hàm Đăng Xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }
}