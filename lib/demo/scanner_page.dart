// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:google_fonts/google_fonts.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//         textTheme: TextTheme(
//           headlineLarge: TextStyle(fontSize: 32), // Large headings
//           // Add more text styles as needed
//         ),
//       ),
//       home: const MyHomePage(title: 'Qr Scanner'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   bool isScannerActive = false; // State to track if the scanner is active

//   void toggleScanner() {
//     setState(() {
//       isScannerActive = !isScannerActive; // Toggle the scanner state
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(75),
//         child: AppBar(
//           backgroundColor: const Color.fromARGB(255, 146, 206, 255),
//           title: Row(children: [
//             Image.asset(
//               'assests/logo.png',
//               height: 30,
//             ),
//             Text(
//               'Qr Scanner',
//               style: GoogleFonts.openSans(fontSize: 24),
//             ),
//           ]),
//           // centerTitle: true, // Center the AppBar title
//         ),
//       ),
//       body: isScannerActive
//           ? MobileScanner(
//               controller: MobileScannerController(
//                   detectionSpeed: DetectionSpeed.normal),
//               onDetect: (capture) {
//                 final List<Barcode> barcodes = capture.barcodes;
//                 final Uint8List? image = capture.image;

//                 // Debugging barcode detection
//                 for (final barcode in barcodes) {
//                   debugPrint('Barcode found: ${barcode.rawValue}');
//                 }

//                 // Check if image is available and show dialog after frame
//                 if (image != null) {
//                   // Ensure dialog is shown after the current frame
//                   WidgetsBinding.instance.addPostFrameCallback((_) {
//                     showDialog(
//                       context: context,
//                       builder: (context) {
//                         return AlertDialog(
//                           title: Text(
//                             barcodes.isNotEmpty
//                                 ? barcodes.first.rawValue ?? "No Data"
//                                 : "No Barcode Found",
//                           ),
//                           content: Image(
//                             image: MemoryImage(image),
//                           ),
//                         );
//                       },
//                     );
//                   });
//                 }
//               },
//             )
//           : Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: const [
//                   Text('Press the button to start scanning'),
//                 ],
//               ),
//             ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: toggleScanner, // Toggle the scanner
//         tooltip: isScannerActive ? 'Stop Scanning' : 'Start Scanning',
//         child: Icon(
//           isScannerActive ? Icons.stop : Icons.qr_code_scanner,
//           size: 30,
//         ),
//       ),
//     );
//   }
// }
