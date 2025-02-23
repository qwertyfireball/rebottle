import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rebottle/pages/customer_pages/account_page.dart';
import 'package:rebottle/pages/customer_pages/notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QRScannerWidget extends StatefulWidget {
  final VoidCallback? onScannerToggle;
  final bool isScannerActive;

  const QRScannerWidget({
    super.key,
    required this.isScannerActive,
    this.onScannerToggle,
  });

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  final NotificationService _notificationService = NotificationService(); // ✅ Use Singleton
  var collection = FirebaseFirestore.instance.collection("14 use");
  int scanCount = 0;

  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted && widget.onScannerToggle != null) {
      widget.onScannerToggle!();
    }
  }

  @override
  void initState() {
    super.initState();
    _notificationService.initNotification(); 
  }

  @override
  Widget build(BuildContext context) {
    return widget.isScannerActive
        ? MobileScanner(
            controller: MobileScannerController(detectionSpeed: DetectionSpeed.normal),
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              final Uint8List? image = capture.image;

              scanCount++; 
              collection.add({'scancount': scanCount.toString()});
              debugPrint("Scan count: $scanCount");

              if (scanCount == 14) {
                _notificationService.showNotification(
                  title: "Rebottle Reward!",
                  body: "14 times a charm, you win a free drink! 🎉",
                );
                scanCount = 0;
                
                callback();
                timezone();

              }

              // Debugging barcode detection
              for (final barcode in barcodes) {
                debugPrint('Barcode found: ${barcode.rawValue}');
              }

              // Show barcode image (if available)
              if (image != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(
                          barcodes.isNotEmpty ? barcodes.first.rawValue ?? "No Data" : "No Barcode Found",
                        ),
                        content: Image(image: MemoryImage(image)),
                      );
                    },
                  );
                });
              }
            },
          )
        : const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Press the button to start scanning'),
              ],
            ),
          );
  }
}