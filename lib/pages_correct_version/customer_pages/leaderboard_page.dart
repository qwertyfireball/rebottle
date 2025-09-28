import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  String sortedField = "totalscancount";

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Leaderboard',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 20),
          DropdownButton<String>(
              value: sortedField,
              items: [
                DropdownMenuItem(
                    value: "totalscancount",
                    child: Text('Total Scans',
                        style: GoogleFonts.poppins(color: Colors.blue))),
                DropdownMenuItem(
                    value: "totalcafevisited",
                    child: Text("Cafes Visited",
                        style: GoogleFonts.poppins(color: Colors.blue)))
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    sortedField = value;
                  });
                }
              }),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('customer')
                    .limit(10)
                    .orderBy(sortedField, descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final users = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userData =
                          users[index].data() as Map<String, dynamic>;
                      final email = userData['email'] ?? 'Unknown User';
                      final scanCount = userData['totalscancount'] ?? 0;
                      final cafeVisited = userData['totalcafevisited'] ?? 0;
                      List colors = [
                        Color(0xFF529AFF),
                        Color(0xFFFF9700),
                        Color(0xFF03C7A4)
                      ];

                      return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Stack(
                            children: [
                            ListTile(
                              contentPadding: const EdgeInsets.only(left: 16, right: 64),
                              leading: CircleAvatar(
                                backgroundColor: colors[index % colors.length],
                                child: Text(
                                  '${index + 1}',
                                  style:
                                      GoogleFonts.poppins(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                email,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold),
                              ),
                              trailing: Text(
                                sortedField == 'totalscancount'
                                    ? "$scanCount scans"
                                    : "$cafeVisited cafes",
                                style: GoogleFonts.poppins(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (index < 3)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: _RankBadge(index: index)
                              ),
                          ]));
                    },
                  );
                }),
          )
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int index;
  const _RankBadge({required this.index});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final double size = (width * 0.09).clamp(20.0, 40.0);

    final asset = switch (index) {
      0 => 'assets/1.png',
      1 => 'assets/2.png',
      _ => 'assets/3.png',
    };

    return Image.asset(asset, width: size, height: size);
  }
}
