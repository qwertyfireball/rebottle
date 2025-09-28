// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_fonts/google_fonts.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
// }

// class CafePage extends StatefulWidget {
//   const CafePage({super.key});

//   @override
//   _CafePageState createState() => _CafePageState();
// }

// class _CafePageState extends State<CafePage> {
//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: Colors.grey[300],
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: [
//           Center(
//             child: Text(
//               'Explore Cafes',
//               style: GoogleFonts.poppins(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue,
//               ),
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//                 stream:
//                     FirebaseFirestore.instance.collection('owner').snapshots(),
//                 builder: (context, snapshot) {
//                   if (!snapshot.hasData) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   final cafes = snapshot.data!.docs;
//                   return ListView.builder(
//                     padding: const EdgeInsets.symmetric(vertical: 8),
//                     itemCount: cafes.length,
//                     itemBuilder: (context, index) {
//                       final doc = cafes[index]; // always use index here
//                       final data = doc.data() as Map<String, dynamic>;

//                       final cafeName = data['cafe name'] ?? 'Unknown Cafe';
//                       final aggregate = (data['aggregate rating'] ?? 0) as num;
//                       final totalRating = (data['total rating'] ?? 0) as num;
//                       final average =
//                           totalRating > 0 ? (aggregate / totalRating) : 0;
//                       final reviews = (data['reviews'] as List<dynamic>?) ?? [];
//                       final firstThreeReviews = reviews.take(3).toList();

//                       return Container(
//                         margin: const EdgeInsets.only(
//                             bottom: 16), // spacing between cards
//                         padding: const EdgeInsets.all(10),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.white, width: 3.5),
//                           borderRadius: BorderRadius.circular(25),
//                           color: const Color(0xFFABD7FF).withOpacity(0.85),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   "# ${index + 1}: $cafeName", // just sequential numbers
//                                   style: GoogleFonts.poppins(
//                                     color: Colors.black,
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 30,
//                                   ),
//                                 ),
//                                 Row(
//                                   children: [
//                                     const Icon(Icons.star,
//                                         color: Colors.yellow, size: 40),
//                                     const SizedBox(width: 6),
//                                     Text(
//                                       average.toStringAsFixed(1),
//                                       style: GoogleFonts.poppins(
//                                         color: Colors.white,
//                                         fontWeight: FontWeight.bold,
//                                         fontSize: 30,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 5),
//                             Text(
//                               firstThreeReviews.isNotEmpty
//                                   ? firstThreeReviews
//                                       .map((r) => '"${r.toString()}"')
//                                       .join("\n")
//                                   : "No reviews",
//                               style: GoogleFonts.poppins(
//                                 color: Colors.black,
//                                 fontSize: 20,
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   );
//                 }),
//           )
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
}

class CafePage extends StatefulWidget {
  const CafePage({super.key});

  @override
  _CafePageState createState() => _CafePageState();
}

class _CafePageState extends State<CafePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Center(
            child: Text(
              'Explore Cafes',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('owner').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final cafes = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: cafes.length,
                    itemBuilder: (context, index) {
                      final doc = cafes[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final cafeName = (data['cafe name'] ?? 'Unknown Cafe')
                          .toString()
                          .trim();
                      final aggregate = (data['aggregate rating'] ?? 0) as num;
                      final totalRating = (data['total rating'] ?? 0) as num;
                      final average =
                          totalRating > 0 ? (aggregate / totalRating) : 0.0;
                      final reviews = (data['reviews'] as List<dynamic>?) ?? [];
                      final firstThreeReviews = reviews.take(3).toList();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 3.5),
                          borderRadius: BorderRadius.circular(25),
                          color: const Color(0xFFABD7FF).withOpacity(0.85),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ROW: left = cafe name (constrained), right = rating (fixed width)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left: takes remaining width and wraps / ellipsizes
                                Expanded(
                                  child: Text(
                                    "# ${index + 1}: $cafeName",
                                    style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24, // reduced a bit to help wrapping
                                    ),
                                    maxLines: 2,
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Right: rating, fixed width so left knows its bounds
                                SizedBox(
                                  width: 96, // tweak this to change rating block width
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      const Icon(Icons.star,
                                          color: Colors.yellow, size: 28),
                                      const SizedBox(width: 6),
                                      Text(
                                        average.toStringAsFixed(1),
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Reviews: show up to 3 lines, ellipsize if too long
                            Text(
                              firstThreeReviews.isNotEmpty
                                  ? firstThreeReviews
                                      .map((r) => r.toString())
                                      .join("\n")
                                  : "No reviews",
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
          )
        ],
      ),
    );
  }
}
