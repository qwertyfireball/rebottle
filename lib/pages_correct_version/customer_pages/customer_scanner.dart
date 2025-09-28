import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';

/// Helper to compute grid childAspectRatio based on width
double _gridAspect(double w) {
  if (w < 340) return 0.95; // very narrow -> tall tiles
  if (w < 380) return 1.05; // small phones
  return 1.22; // normal phones
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin<HomePage> {
  String scannedCode = '';
  double _rating = 3;
  String? userFeedback;
  final TextEditingController review = TextEditingController();

  String uid = '';
  Timer? qrTimer;
  String qrData = '';

  SharedPreferences? prefs;
  bool _prefsReady = false;
  String? lastShownOrderId;
  String? currentDocID;

  final int goal = 1000;

  final totalscancountNotifier = ValueNotifier<int>(0);
  final totalcafevisitedNotifier = ValueNotifier<int>(0);
  final percentageNotifier = ValueNotifier<double>(0);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    uid = user?.uid ?? '';

    _initPrefs();
    if (uid.isNotEmpty) {
      _startQrTimer();
      _fetchLatestScan();
    }
  }

  @override
  void dispose() {
    qrTimer?.cancel();
    review.dispose();
    totalscancountNotifier.dispose();
    totalcafevisitedNotifier.dispose();
    percentageNotifier.dispose();
    super.dispose();
  }

  Future<void> _initPrefs() async {
    try {
      prefs = await SharedPreferences.getInstance();
      lastShownOrderId = prefs!.getString('lastShownOrderId');
    } catch (_) {
      prefs = null;
      lastShownOrderId = null;
    } finally {
      if (mounted) setState(() => _prefsReady = true);
    }
  }

  void _startQrTimer() {
    qrTimer?.cancel();
    qrTimer = Timer.periodic(const Duration(minutes: 60), (_) => _generateQr());
    _generateQr();
  }

  Future<void> _generateQr() async {
    if (uid.isEmpty) return;
    final expiresAt =
        DateTime.now().add(const Duration(minutes: 60)).millisecondsSinceEpoch;
    final token = DateTime.now().millisecondsSinceEpoch.toString();
    qrData = '$uid/$token/$expiresAt';
    if (mounted) setState(() {});
    await FirebaseFirestore.instance
        .collection('customer')
        .doc(uid)
        .set({'current expire time': expiresAt, 'current token': token},
            SetOptions(merge: true));
  }

  Future<void> _fetchLatestScan() async {
    if (uid.isEmpty) return;
    final snap =
        await FirebaseFirestore.instance.collection('customer').doc(uid).get();
    if (!snap.exists) return;

    final totalscan = (snap.data()?['totalscancount'] as num? ?? 0).toInt();
    final totalcafe = (snap.data()?['totalcafevisited'] as num? ?? 0).toInt();

    totalscancountNotifier.value = totalscan;
    totalcafevisitedNotifier.value = totalcafe;
    percentageNotifier.value = (totalscan / (10 * goal)).clamp(0.0, 1.0);
  }

  void _reviewDialog() {
    if (currentDocID == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Tell us about your experience!",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: SizedBox(
          height: 250,
          child: Column(
            children: [
              RatingBar.builder(
                itemBuilder: (context, _) =>
                    const Icon(Icons.water_drop, color: Colors.blue),
                onRatingUpdate: (rating) => _rating = rating,
                itemCount: 5,
                allowHalfRating: true,
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: review,
                decoration: InputDecoration(
                  hintText: "Write a review!",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.all(10),
                ),
                maxLines: 3,
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  userFeedback = review.text;
                  await _writeReview();
                  await _firestoreUpdate();
                },
                child:
                    Text("CONFIRM", style: GoogleFonts.poppins(color: Colors.blue)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _writeReview() async {
    if (prefs == null) return;
    final text = review.text;
    if (text.isNotEmpty) {
      await prefs!.setString('userFeedback', text);
    }
  }

  Future<void> _firestoreUpdate() async {
    if (currentDocID == null || uid.isEmpty) return;

    final doc = await FirebaseFirestore.instance
        .collection("customer")
        .doc(uid)
        .collection("orderid")
        .doc(currentDocID)
        .get();
    if (!doc.exists) return;

    final ownerUid = doc.data()?["owneruid"];
    if (ownerUid == null) return;

    await FirebaseFirestore.instance.collection("owner").doc(ownerUid).set({
      'aggregate rating': FieldValue.increment(_rating),
      'total rating': FieldValue.increment(1),
      'reviews': FieldValue.arrayUnion([userFeedback]),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final w = MediaQuery.of(context).size.width;
    final paddingTop = MediaQuery.of(context).padding.top;
    final isCompact = w < 360;
    final titleSize = (w * 0.06).clamp(18.0, 26.0);

    if (uid.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[300],
        body: Center(
          child: Text(
            "Please sign in to view your home dashboard.",
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: paddingTop + 20)),

          // QR SECTION (bounded)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(width: 2, color: Colors.grey),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Provide concrete width and keep square with AspectRatio
                  SizedBox(
                    width: w * (isCompact ? 0.45 : 0.38),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFA7EADD),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Scan\nYour\nQR Code",
                      style: GoogleFonts.poppins(fontSize: titleSize),
                    ),
                  ),
                ],
              ),
            ),
          ),

          ValueListenableBuilder<int>(
            valueListenable: totalscancountNotifier,
            builder: (context, totalscancount, _) {
              return ValueListenableBuilder<int>(
                valueListenable: totalcafevisitedNotifier,
                builder: (context, totalcafevisited, __) {
                  return SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 240, 
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: _gridAspect(w),
                      ),
                      delegate: SliverChildListDelegate.fixed([
                        BigStatBox(
                          value: totalscancount,
                          titleLine1: "Plastic",
                          titleLine2: "Cup\nSaved!",
                        ),
                        CounterBox(
                          label: "Cafe Visited",
                          value: totalcafevisited,
                          icon: Icons.coffee,
                        ),
                      ]),
                    ),
                  );
                },
              );
            },
          ),

          ValueListenableBuilder<int>(
            valueListenable: totalscancountNotifier,
            builder: (context, totalscancount, _) {
              return SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                sliver: SliverToBoxAdapter(
                  child: LinearIndicator(totalScan: totalscancount),
                ),
              );
            },
          ),

          SliverToBoxAdapter(
            child: !_prefsReady
                ? const SizedBox.shrink()
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('customer')
                        .doc(uid)
                        .collection('orderid')
                        .orderBy('loggedAt', descending: true)
                        .limit(1)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        final latestDoc = snapshot.data!.docs.first;
                        final latestDocId = latestDoc.id;

                        if (lastShownOrderId != latestDocId) {
                          lastShownOrderId = latestDocId;
                          if (prefs != null) {
                            prefs!.setString('lastShownOrderId', latestDocId);
                          }
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            currentDocID = latestDocId;
                            _reviewDialog();
                          });
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class BigStatBox extends StatelessWidget {
  final int value;
  final String titleLine1;
  final String titleLine2;
  final double numberScale; 

  const BigStatBox({
    super.key,
    required this.value,
    this.titleLine1 = "Plastic",
    this.titleLine2 = "Cup Saved!",
    this.numberScale = 0.6, 
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final tileW = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.of(context).size.width * 0.45;
      final tileH = constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : 140.0;
      final numberBoxByWidth = tileW * 0.45;
      final numberBoxByHeight = tileH * 0.92;
      final numberBoxSize = numberBoxByWidth.clamp(64.0, 220.0).clamp(0.0, numberBoxByHeight);
      final numberFontSize = (numberBoxSize * numberScale).clamp(30.0, 140.0);
      final titleFontSize = (tileW * 0.09).clamp(14.0, 28.0);

      return Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF9FE8E0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: numberBoxSize,
              height: numberBoxSize,
              decoration: BoxDecoration(
                color: const Color(0xFF9FE8DD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: AnimatedFlipCounter(
                  value: value,
                  duration: const Duration(milliseconds: 600),
                  textStyle: GoogleFonts.poppins(
                    fontSize: numberFontSize,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                  ),
                  suffix: "",
                ),
              ),
            ),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleLine1,
                    style: GoogleFonts.poppins(
                      fontSize: titleFontSize,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    titleLine2,
                    style: GoogleFonts.poppins(
                      fontSize: titleFontSize,
                      color: Colors.black87,
                      height: 1.02,
                    ),
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class CounterBox extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  const CounterBox({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final h = c.maxHeight.isFinite && c.maxHeight > 0 ? c.maxHeight : 160.0;
      // scale by available height
      final iconSide = (h * 0.26).clamp(26.0, 44.0);
      final gapSmall = (h * 0.035).clamp(4.0, 8.0);
      final labelSize = (h * 0.11).clamp(12.0, 16.0);
      final valueSize = (h * 0.24).clamp(18.0, 28.0);

      return Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFA7EADD),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // icon chip
            Container(
              width: iconSide,
              height: iconSide,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: iconSide * 0.62),
            ),
            SizedBox(height: gapSmall),
            // label
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(color: Colors.black, fontSize: labelSize),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AnimatedFlipCounter(
                value: value,
                suffix: "+",
                duration: const Duration(seconds: 2),
                textStyle: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: valueSize,
                  height: 1.05,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class LinearIndicator extends StatelessWidget {
  final int totalScan;
  const LinearIndicator({super.key, required this.totalScan});

  static const List<List<int>> _levels = [
    [1, 10],
    [11, 25],
    [26, 50],
    [51, 100],
    [101, 250],
    [251, 500],
  ];

  Map<String, dynamic> _progressInDomain(int current) {
    for (final range in _levels) {
      final min = range[0];
      final max = range[1];
      if (current <= max) {
        final percent = ((current - min + 1) / (max - min + 1)).clamp(0.0, 1.0);
        final remaining = current < max ? max - current : 0;
        return {'percent': percent, 'remaining': remaining, 'min': min, 'max': max};
      }
    }
    return {'percent': 1.0, 'remaining': 0, 'min': 0, 'max': 0};
  }

  @override
  Widget build(BuildContext context) {
    final data = _progressInDomain(totalScan);
    final percent = data['percent'] as double;
    final remaining = data['remaining'] as int;
    final min = data['min'] as int;
    final max = data['max'] as int;

    final w = MediaQuery.of(context).size.width;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 120),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFABD7FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              remaining > 0
                  ? "Only $remaining more reuses\nleft to claim next badge! ($min–$max)"
                  : "🎉 You’ve reached the top badge!",
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: (w * 0.045).clamp(14.0, 18.0),
              ),
            ),
            const SizedBox(height: 14),
            LinearPercentIndicator(
              percent: percent,
              animation: true,
              animationDuration: 1000,
              progressColor: Colors.grey,
              backgroundColor: Colors.white,
              lineHeight: 14,
              barRadius: const Radius.circular(25),
            ),
          ],
        ),
      ),
    );
  }
}
