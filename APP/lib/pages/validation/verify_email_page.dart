import 'dart:async';
import 'package:ddbookstore/pages/content/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  late StoreUser storeuser;
  late Timer _timer;

  @override
  void didChangeDependencies() {
    storeuser = ModalRoute.of(context)!.settings.arguments as StoreUser;
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        if (user.emailVerified) {
          _timer.cancel();
          storeuser.verifyUser();
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/main_page',
            (route) => false,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('Email Verification'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
                text: TextSpan(children: [
              const TextSpan(
                text: 'Email: ',
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: FirebaseAuth.instance.currentUser?.email,
                style: const TextStyle(color: Colors.red),
              )
            ])),
            const SizedBox(height: 20),
            const Text('Please verify your email address:'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                await user?.sendEmailVerification();
              },
              child: const Text('Send Link'),
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              'The screen will automatically\n refresh upon verification.',
              style: TextStyle(color: Colors.green),
            ),
            const SizedBox(height: 20),
            SizedBox(
              child: TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home_page',
                    (route) => false,
                  );
                },
                child: const Text(
                  'CANCEL',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontSize: 17,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
