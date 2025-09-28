import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerPage extends StatefulWidget {
  const OwnerPage({super.key});
  @override
  State<OwnerPage> createState() => _OwnerPageState();
}

String? currentDocID;

class _OwnerPageState extends State<OwnerPage> {
  bool isScanning = false;
  String scannedCode = '';
  MobileScannerController? controller;
  int scanCount = 0;
  String? userFeedback;
  final TextEditingController review = TextEditingController();
  late String owner_uid;
  @override
  void initState() {
    super.initState();
    final owner = FirebaseAuth.instance.currentUser;
    if (owner != null) {
      owner_uid = owner.uid;
    }
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
      torchEnabled: false,
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

  Future<void> firestoreOncapture(customer_uid) async {
    String cafe_name = '';
    DocumentSnapshot snapshot_cafe_name = await FirebaseFirestore.instance
        .collection('owner')
        .doc(owner_uid)
        .get();
    if (snapshot_cafe_name.exists) {
      cafe_name = snapshot_cafe_name['cafe name'];
    }
    DocumentReference docref = await FirebaseFirestore.instance
        .collection('customer')
        .doc(customer_uid)
        .collection('orderid')
        .add({
      'loggedAt': FieldValue.serverTimestamp(),
      'owneruid': owner_uid,
    });
    await docref.update({"docID": docref.id});
    await FirebaseFirestore.instance
        .collection('customer')
        .doc(customer_uid)
        .set({
      'totalscancount': FieldValue.increment(1),
      'cafe visited': FieldValue.arrayUnion([cafe_name]),
    }, SetOptions(merge: true));

    DocumentSnapshot snapshot_cafe_length = await FirebaseFirestore.instance
        .collection("customer")
        .doc(customer_uid)
        .get();
    if (snapshot_cafe_length.exists) {
      List<dynamic> cafe_length = snapshot_cafe_length['cafe visited'] ?? [];
      int totalcafevisited = cafe_length.length;

      await FirebaseFirestore.instance
          .collection('customer')
          .doc(customer_uid)
          .update({"totalcafevisited": totalcafevisited});
    }

    currentDocID = docref.id;
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
                            final barcode = barcodes.first;
                            final qrValue = barcode.rawValue;
                            if (qrValue == null) return;
                            final parts = qrValue.split('/');
                            final customer_uid = parts[0];
                            final expiresAt = int.tryParse(parts[2]) ?? 0;
                            final now = DateTime.now().millisecondsSinceEpoch;
                            if (now > expiresAt) {
                              return;
                            }
                            firestoreOncapture(customer_uid);
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
                    Column(
                      children: [
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
                                const SizedBox(
                                  height: 8,
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
                    const SizedBox(
                      height: 250,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: SizedBox(
                          width: 250, // Fixed width for buttons
                          child: ElevatedButton(
                            onPressed: () {
                              FirebaseAuth.instance.signOut();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Sign Out'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
