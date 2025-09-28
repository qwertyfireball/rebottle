import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rebottle/auth/auth_page.dart';
import 'package:rebottle/pages_correct_version/customer_pages/nav.dart';
import 'package:rebottle/pages_correct_version/owner_pages/owner_scanner.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  Future<String> getUserRole(String userId) async {
    try {
      var ownerDoc = await FirebaseFirestore.instance
          .collection('owner')
          .doc(userId)
          .get();

      // Assuming the 'role' field exists in the user document
      if (ownerDoc.exists)
      {
        return 'Owner'; 
      }
// Return the user's role (either 'admin' or 'user')

      var customerDoc = await FirebaseFirestore.instance
      .collection('customer')
      .doc(userId)
      .get();
      if (customerDoc.exists) {
        return 'Customer';
      }
      return 'Customer';
    } catch (e) {
      return 'Customer'; // Default role if there’s an error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(); // Show loading while waiting for auth state
          }

          if (snapshot.hasData) {
            // Fetch the user role once the user is authenticated
            return FutureBuilder<String>(
              future: getUserRole(snapshot.data!.uid),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(); // Show loading while fetching role
                }

                if (roleSnapshot.hasData) {
                  String role = roleSnapshot.data!;

                  // Navigate to the respective page based on the role
                  if (role == 'Owner') {
                    return OwnerPage(); // Show admin home page
                  } else {
                    return CustomerPage(); // Show user home page
                  }
                } else {
                  return AuthPage(); // If there was an issue fetching role, show auth page
                }
              },
            );
          } else {
            return AuthPage(); // If no user is logged in, show the auth page
          }
        },
      ),
    );
  }
}
