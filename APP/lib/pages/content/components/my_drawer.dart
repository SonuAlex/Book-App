import 'package:ddbookstore/pages/content/components/my_drawer_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              const DrawerHeader(
                child: Center(
                  child: Icon(
                    Icons.book,
                    size: 72,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              MyDrawerTile(
                icon: const Icon(Icons.home),
                title: 'Home',
                onTap: () => Navigator.pop(context),
              ),
              MyDrawerTile(
                icon: const Icon(Icons.checklist_rounded),
                title: 'Request',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/request_page');
                },
              ),
              MyDrawerTile(
                icon: const Icon(Icons.bookmark),
                title: 'Borrowed Books',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/borrowed_books_page');
                },
              ),
              MyDrawerTile(
                icon: const Icon(Icons.library_books_outlined),
                title: 'My Books',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/owned_books_page');
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 25.0),
            child: Column(
              children: [
                // MyDrawerTile(
                //   icon: const Icon(Icons.settings),
                //   title: 'Settings',
                //   onTap: () => Navigator.pop(context),
                // ),
                MyDrawerTile(
                  icon: const Icon(Icons.logout),
                  title: 'Logout',
                  onTap: () {
                    FirebaseAuth.instance.signOut();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login_page',
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
