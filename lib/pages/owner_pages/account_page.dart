import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rebottle/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void timezone() async {
  FirebaseFirestore.instance.collection('orders').add({
    'orderId': '12345',
    'status': 'Completed',
    'loggedAt': FieldValue.serverTimestamp(),
  });
}

void callback() async {
  try {
    DocumentSnapshot order = await FirebaseFirestore.instance
        .collection('orders')
        .doc('12345')
        .get();

    if (order.exists) {
      var data = order.data() as Map<String, dynamic>?;

      if (data != null) {
        var loggedAt = data['loggedAt']; // Access field safely

        if (loggedAt is Timestamp) {
          DateTime dateTime = loggedAt.toDate();
          debugPrint("Order 12345 Timestamp: $dateTime");
        } else {
          debugPrint("loggedAt is null or not a Timestamp");
        }
      } else {
        debugPrint("Error: Document exists but data is null.");
      }
    } else {
      debugPrint("Order not found.");
    }
  } catch (e) {
    debugPrint("Error fetching order: $e");
  }
}

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late User user;
  bool showHistory = false;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser!; // Fetch user in initState
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        color: Colors.grey[300],
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 50),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Text(
              user.email ?? 'No email',
              style: const TextStyle(fontSize: 18, color: Colors.black),
            ),
            const SizedBox(height: 100),
            ElevatedButton(
              onPressed: () => _showInfoDialog(
                context,
                "App Info",
                "Rebottle App\nVersion: 1.0.0\nDeveloped by Matt Shih and Michael Shih",
              ),
              style: _buttonStyle(),
              child: const Text('App Info', style: TextStyle(color: Colors.black87)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _showInfoDialog(context, "History", "dates");
                setState(() {
                  showHistory = !showHistory; // Toggle the history visibility
                });
              },
              style: _buttonStyle(),
              child: const Text('History', style: TextStyle(color: Colors.black87)),
            ),
            const SizedBox(height: 20),

            // Conditionally show the history section if showHistory is true
            if (showHistory)
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection("orders")
                      .orderBy('loggedAt', descending: true)
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final orderHistory = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: orderHistory.length,
                      itemBuilder: (context, index) {
                        final order = orderHistory[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  child: Row(
                                    children: [
                                      Text(
                                        (order['loggedAt'] != null &&
                                                order['loggedAt'] is Timestamp)
                                            ? DateFormat('yyyy-MM-dd HH:mm:ss')
                                                .format(order['loggedAt'].toDate())
                                            : "No Timestamp",
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

            // Sign Out Button
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
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
        title: Text(title, style: const TextStyle(color: Colors.black)),
        content: Text(content),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.grey[200],
      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}