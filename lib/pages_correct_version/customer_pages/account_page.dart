import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rebottle/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

late User user;
late String uid;

class _AccountPageState extends State<AccountPage> {
  bool showHistory = false;
  bool showBadges = false;
  int? scancount;
  final List<Map<String, dynamic>> milestones = [
    {
      'scancount': [1, 10],
      'title': 'Sip Saver',
      'description': '(1-10 Cups)'
    },
    {
      'scancount': [11, 25],
      'title': 'Cup Crusader',
      'description': '(11-25 Cups)'
    },
    {
      'scancount': [26, 50],
      'title': 'Plastic Slayer',
      'description': '(26-50 Cups)'
    },
    {
      'scancount': [51, 100],
      'title': 'Forest Builder',
      'description': '(51-100 Cups)'
    },
    {
      'scancount': [101, 250],
      'title': 'Earth Guardian',
      'description': '(101-250 Cups)'
    },
    {
      'scancount': [251, 500],
      'title': 'Rebottle Legend',
      'description': '(251-500 Cups)'
    },
  ];

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser!; // Fetch user in initState
    uid = user.uid;
    getscans();
  }

  void getscans() async {
    final doc =
        await FirebaseFirestore.instance.collection('customer').doc(uid).get();
    if (!mounted) return;
    setState(() {
      scancount = (doc.data()?['totalscancount'] as num?)?.toInt() ?? 0;
    });
  }

  Widget chooseBadge(int scancount, Map<String, dynamic> milestone) {
    final range = (milestone['scancount'] as List).cast<int>();
    final earned = scancount >= range[0];
    return Image.asset(
      earned ? 'assets/gold_badge.png' : 'assets/grey_badge.png',
      width: 60,
      height: 60,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Column(
          children: [
            // Profile section
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 50, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      user.email ?? 'No email',
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Buttons section - centered with fixed width
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 250, // Fixed width for buttons
                    child: OutlinedButton(
                      onPressed: () => _showInfoDialog(
                        context,
                        "App Info",
                        "Rebottle App\nVersion: 1.0.0\nDeveloped by Matt Shih and Michael Shih",
                      ),
                      style: _buttonStyle(),
                      child: Text('App Info',
                          style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 250, // Fixed width for buttons
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          showHistory =
                              !showHistory; // Toggle the history visibility
                        });
                      },
                      style: _buttonStyle(),
                      child: Text(
                        showHistory ? 'Hide History' : 'Show History',
                        style: GoogleFonts.poppins(
                            color: Colors.black87, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                      width: 250, // Fixed width for buttons
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            showBadges = !showBadges;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Color(0xFFF59F0A),
                            width: 2,
                          ),
                          backgroundColor: Colors.grey[200],
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          showBadges ? 'Hide Badges' : 'Show Badges',
                          style: GoogleFonts.poppins(
                              color: Color(0xFFF59F0A),
                              fontWeight: FontWeight.bold),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // History section
            if (showHistory) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Bottle Return History',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("customer")
                        .doc(uid)
                        .collection('orderid')
                        .orderBy('loggedAt', descending: true)
                        .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final orderHistory = snapshot.data!.docs;

                      if (orderHistory.isEmpty) {
                        return Center(
                          child: Text(
                            'No history found',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: orderHistory.length,
                        itemBuilder: (context, index) {
                          final order = orderHistory[index];
                          final timestamp = order['loggedAt'] is Timestamp
                              ? order['loggedAt'].toDate()
                              : null;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Icon(
                                  Icons.recycling,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                timestamp != null
                                    ? DateFormat('MMM d, yyyy')
                                        .format(timestamp)
                                    : "No Date",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                timestamp != null
                                    ? DateFormat('h:mm a').format(timestamp)
                                    : "",
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: Text(
                                "Bottle Returned",
                                style: GoogleFonts.poppins(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ]

            else if (showBadges) ...[
              Expanded(
                  child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.7,
                  mainAxisSpacing: 1,
                  crossAxisSpacing: 10,
                ),
                itemCount: milestones.length,
                itemBuilder: (context, index) {
                  final milestone = milestones[index];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      chooseBadge(scancount ?? 0, milestone),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        milestone['title'],
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        milestone['description'],
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                      const SizedBox(
                        height: 5,
                      )
                    ],
                  );
                },
              ))
            ],

            if (!showHistory && !showBadges) const Spacer(),

            // Sign Out Button - always at the bottom
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
                      backgroundColor: Color(0xFF5CACF3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'Sign Out',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[200],
        title: Text(title, style: GoogleFonts.poppins(color: Colors.black)),
        content: Text(
          content,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "OK",
                style: GoogleFonts.poppins(),
              ))
        ],
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return OutlinedButton.styleFrom(
      backgroundColor: Colors.grey[200],
      padding: const EdgeInsets.symmetric(vertical: 15),
      side: BorderSide(
        color: Colors.grey,
        width: 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
    );
  }
}
