import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class BarcodeScannerService {
  static Future<String?> scanBarcode({
    required String title,
    String? promptMessage,
  }) async {
    // Check camera permission
    final permissionStatus = await Permission.camera.request();
    
    if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
      Get.snackbar(
        'Permission Denied',
        'Camera permission is required to scan barcodes',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }

    // Show scanner screen
    final result = await Get.to<String>(
      () => BarcodeScannerScreen(
        title: title,
        promptMessage: promptMessage,
      ),
    );

    return result;
  }
}

class BarcodeScannerScreen extends StatefulWidget {
  final String title;
  final String? promptMessage;

  const BarcodeScannerScreen({
    Key? key,
    required this.title,
    this.promptMessage,
  }) : super(key: key);

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  late MobileScannerController cameraController;
  bool isScanned = false;
  bool isTorchOn = false;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onBarcodeDetect(BarcodeCapture barcodeCapture) {
    if (isScanned) return;

    final List<Barcode> barcodes = barcodeCapture.barcodes;
    
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      final String? code = barcode.rawValue;

      if (code != null && code.isNotEmpty) {
        setState(() {
          isScanned = true;
        });

        // Vibrate on successful scan (optional)
        // HapticFeedback.vibrate();

        // Return the scanned code
        Get.back(result: code);
      }
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await cameraController.toggleTorch();
      setState(() {
        isTorchOn = !isTorchOn;
      });
    } catch (e) {
      print('Error toggling torch: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: cameraController,
            onDetect: _onBarcodeDetect,
          ),

          // Overlay with scanning area
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: Container(),
          ),

          // Prompt message
          if (widget.promptMessage != null)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.promptMessage!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Manual cancel button
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: TextButton(
                onPressed: () => Get.back(),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = size.width * 0.7;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;

    // Draw semi-transparent overlay
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final scanAreaPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize),
          const Radius.circular(12),
        ),
      );

    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      scanAreaPath,
    );

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withOpacity(0.5),
    );

    // Draw corner brackets
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const cornerLength = 30.0;
    final rect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    // Top-left corner
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left, rect.top + cornerLength),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.top),
      Offset(rect.right, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(rect.left, rect.bottom - cornerLength),
      Offset(rect.left, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(rect.right, rect.bottom - cornerLength),
      Offset(rect.right, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.bottom),
      Offset(rect.right, rect.bottom),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}