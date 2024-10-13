import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String msg = '';
  double progress = 0;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        msg = 'Loading User Details . . .';
        progress = 0.25;
      });
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      setState(() {
        msg = 'Loading Book Details . . .';
        progress = 0.50;
      });
    });

    Future.delayed(const Duration(milliseconds: 3000), () {
      setState(() {
        msg = 'Done!';
        progress = 1;
      });
    });

    Future.delayed(const Duration(milliseconds: 4000), () {
      if (FirebaseAuth.instance.currentUser == null) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login_page',
          (route) => false,
        );
      } else {
        if (FirebaseAuth.instance.currentUser!.emailVerified) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/main_page',
            (route) => false,
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/verifyEmail_page',
            (route) => false,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(msg),
            const SizedBox(
              height: 15,
            ),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            )
          ],
        ),
      ),
    );
  }
}
