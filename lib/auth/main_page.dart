import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rebottle/auth/auth_page.dart';
import 'package:rebottle/pages/customer_pages/customer_page.dart';
import 'package:rebottle/pages/owner_pages/owner_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  Future<String> getUserRole(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      // Assuming the 'role' field exists in the user document
      if (userDoc.exists) {
        return userDoc['role']; // Return the user's role (either 'admin' or 'user')
      } else {
        return 'user'; // Default role if none found
      }
    } catch (e) {
      return 'user'; // Default role if there’s an error
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
