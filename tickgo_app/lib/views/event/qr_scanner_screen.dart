import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  // Biến cờ để tránh việc camera quét liên tục 1 mã n lần trong 1 giây
  bool _isProcessing = false;
  MobileScannerController cameraController = MobileScannerController();

  // Hàm xử lý khi quét ra mã QR
  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return; // Nếu đang xử lý thì bỏ qua các khung hình tiếp theo
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? qrCodeData = barcodes.first.rawValue; // Lấy chuỗi purchaseId từ QR
    if (qrCodeData == null) return;

    setState(() => _isProcessing = true);
    cameraController.stop(); // Tạm dừng camera để xử lý

    // Gọi hàm kiểm tra vé trên Firestore
    await _verifyTicket(qrCodeData);
  }

  Future<void> _verifyTicket(String purchaseId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      DocumentReference purchaseRef = FirebaseFirestore.instance.collection('purchases').doc(purchaseId);
      DocumentSnapshot purchaseSnap = await purchaseRef.get();

      if (!mounted) return; 
      Navigator.pop(context); // Tắt vòng loading

      if (!purchaseSnap.exists) {
        _showResultDialog(false, "VÉ GIẢ HOẶC KHÔNG TỒN TẠI!", "Không tìm thấy dữ liệu vé trên hệ thống.");
        return;
      }

      var data = purchaseSnap.data() as Map<String, dynamic>;
      String status = data['status'] ?? '';
      String eventTitle = data['eventTitle'] ?? 'Sự kiện';
      String buyerName = data['buyerName'] ?? 'Khách hàng';

      if (status == 'checked_in') {
        _showResultDialog(false, "VÉ ĐÃ ĐƯỢC SỬ DỤNG!", "Vé của $buyerName cho sự kiện $eventTitle đã được quét trước đó vào lúc cổng mở.");
      } else if (status == 'success') {
        // Cập nhật trạng thái thành đã check-in
        await purchaseRef.update({
          'status': 'checked_in',
          'checkInTime': FieldValue.serverTimestamp(),
        });
        _showResultDialog(true, "CHECK-IN THÀNH CÔNG!", "Chào mừng $buyerName tham gia $eventTitle.");
      } else {
        _showResultDialog(false, "LỖI TRẠNG THÁI VÉ", "Trạng thái vé không hợp lệ ($status).");
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Tắt vòng loading nếu lỗi
      _showResultDialog(false, "LỖI HỆ THỐNG", e.toString());
    }
  }

  void _showResultDialog(bool isSuccess, String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.cancel,
              color: isSuccess ? Colors.green : Colors.red,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSuccess ? Colors.green : Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Đóng popup
                  setState(() => _isProcessing = false);
                  cameraController.start(); // Mở lại camera để quét khách tiếp theo
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSuccess ? Colors.green : Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("QUÉT TIẾP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Quét Mã Check-in", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          // 👉 CÁCH LẮNG NGHE FLASH MỚI NHẤT
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: cameraController,
            builder: (context, state, child) {
              final TorchState torchState = state.torchState;
              return IconButton(
                icon: Icon(
                  torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                  color: torchState == TorchState.on ? Colors.yellow : Colors.white,
                ),
                onPressed: () => cameraController.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.orange, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const Positioned(
            bottom: 40,
            child: Text("Đưa mã QR vào trong khung hình", style: TextStyle(color: Colors.white, fontSize: 16)),
          )
        ],
      ),
    );
  }
}