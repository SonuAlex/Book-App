import 'package:ddbookstore/firebase_options.dart';
import 'package:ddbookstore/pages/content/book_details_page.dart';
import 'package:ddbookstore/pages/content/main_page.dart';
import 'package:ddbookstore/pages/content/profile_page.dart';
import 'package:ddbookstore/pages/content/request_page.dart';
import 'package:ddbookstore/pages/intermediate_page.dart';
import 'package:ddbookstore/pages/validation/login_page.dart';
import 'package:ddbookstore/pages/validation/register_page.dart';
import 'package:ddbookstore/pages/validation/verify_email_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      routes: {
        '/home_page': (context) => const HomePage(),
        '/login_page': (context) => const LoginPage(),
        '/register_page': (context) => const RegisterPage(),
        '/verifyEmail_page': (context) => const VerifyEmailPage(),
        '/main_page': (context) => const MainPage(),
        '/profile_page': (context) => const ProfilePage(),
        '/book_details': (context) => const BookDetailsPage(),
        '/request_page': (context) => const RequestPage(),
      },
    );
  }
}
