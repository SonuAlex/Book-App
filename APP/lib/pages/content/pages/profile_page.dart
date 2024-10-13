import 'package:ddbookstore/pages/content/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<Map<String, dynamic>> userDetails() {
  return StoreUser().getUser(FirebaseAuth.instance.currentUser!.uid);
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late StoreUser storeuser;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: userDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('An error occurred'),
          );
        }

        storeuser = StoreUser(
          fullName: snapshot.data!['name'],
          phone: snapshot.data!['phone'],
          flatNo: snapshot.data!['flat_no'],
          email: snapshot.data!['email'],
          hostedBooks: snapshot.data!['hosted_books'],
          borrowedBooks: snapshot.data!['borrowed_books'],
          borrowedBookList: snapshot.data!['borrowed_titles'],
        );

        TableColumnWidth columnWidth = const FlexColumnWidth(1.0);

        return Scaffold(
          appBar: AppBar(
            title: const Center(
              child: Text('User Profile'),
            ),
            backgroundColor: Colors.grey.shade200,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushNamed(context, '/login_page');
                },
              ),
            ],
          ),
          // floatingActionButton: FloatingActionButton(
          //   onPressed: () {},
          //   child: const Icon(Icons.edit),
          // ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Table(
                defaultColumnWidth: columnWidth,
                border: TableBorder.all(),
                children: [
                  TableRow(children: [
                    const Center(heightFactor: 3.0, child: Text('Name:')),
                    Center(heightFactor: 3.0, child: Text(storeuser.fullName!))
                  ]),
                  TableRow(children: [
                    const Center(
                        heightFactor: 3.0, child: Text('Phone Number:')),
                    Center(
                        heightFactor: 3.0,
                        child: Text(storeuser.phone!.toString()))
                  ]),
                  TableRow(children: [
                    const Center(
                        heightFactor: 3.0, child: Text('Flat Number:')),
                    Center(heightFactor: 3.0, child: Text(storeuser.flatNo!))
                  ]),
                  TableRow(children: [
                    const Center(heightFactor: 3.0, child: Text('Email Id:')),
                    Center(
                        heightFactor: 3.0,
                        child: Text(
                          storeuser.email!,
                          style: const TextStyle(fontSize: 12),
                        ))
                  ]),
                  TableRow(children: [
                    const Center(
                        heightFactor: 3.0,
                        child: Text('Books currently hosted:')),
                    Center(
                        heightFactor: 3.0,
                        child: Text(storeuser.hostedBooks!.toString()))
                  ]),
                  TableRow(children: [
                    const Center(
                        heightFactor: 3.0,
                        child: Text('Books currently borrowed:')),
                    Center(
                        heightFactor: 3.0,
                        child: Text(storeuser.borrowedBooks!.toString()))
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
