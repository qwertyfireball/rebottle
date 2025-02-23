import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rebottle/pages/customer_pages/notifications.dart';
import 'package:rebottle/pages/customer_pages/account_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isScanning = false;
  String scannedCode = '';
  MobileScannerController? controller;
  final NotificationService _notificationService = NotificationService();
  var collection = FirebaseFirestore.instance.collection("14 use");
  int scanCount = 0;

  @override
  void initState() {
    super.initState();
    _notificationService.initNotification();
  }

  @override
  void dispose() {
    stopScanner();
    super.dispose();
  }

  Future<void> initializeController() async {
    if (controller != null) {
      await stopScanner();
    }

    controller = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false, // Prevent torch issues
    );

    if (mounted) {
      setState(() {
        isScanning = true;
      });
    }
  }

  Future<void> stopScanner() async {
    try {
      await controller?.stop();
      await controller?.dispose();
      controller = null;

      if (mounted) {
        setState(() {
          isScanning = false;
        });
      }
    } catch (e) {
      debugPrint('Error stopping scanner: $e');
    }
  }

  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      await initializeController();
    } else {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Camera Permission'),
            content: const Text(
                'Please grant camera permission to use the QR scanner'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> resetScanner() async {
    setState(() {
      scannedCode = '';
    });
    await initializeController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Stack(
        children: [
          if (isScanning && controller != null)
            Positioned.fill(
              child: Container(
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 50),
                child: Column(
                  children: [
                    Container(
                      height: 300,
                      width: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: MobileScanner(
                          controller: controller!,
                          onDetect: (capture) async {
                            final List<Barcode> barcodes = capture.barcodes;

                            scanCount++;
                            collection.add({'scancount': scanCount.toString()});
                            debugPrint("Scan count: $scanCount");

                            if (scanCount == 14) {
                              _notificationService.showNotification(
                                title: "Rebottle Reward!",
                                body:
                                    "14 times a charm, you win a free drink! 🎉",
                              );
                            }
                            callback();
                            timezone();

                            for (final barcode in barcodes) {
                              await stopScanner();
                              if (mounted) {
                                setState(() {
                                  scannedCode =
                                      barcode.rawValue ?? 'Failed to scan';
                                });
                              }
                              break;
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: stopScanner,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop Scanning'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (scannedCode.isEmpty) ...[
                      const Icon(
                        Icons.qr_code_scanner,
                        size: 100,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Scan QR Code',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: requestCameraPermission,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Start Scanning'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                      ),
                    ],
                    if (scannedCode.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Scanned Code:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              scannedCode,
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: resetScanner,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Scan Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
