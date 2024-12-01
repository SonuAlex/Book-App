import 'package:ddbookstore/firebase_options.dart';
import 'package:ddbookstore/pages/bookInsertion/pages/book_main_page.dart';
import 'package:ddbookstore/pages/bookInsertion/pages/book_title_entry.dart';
import 'package:ddbookstore/pages/bookInsertion/pages/display_details_page.dart';
import 'package:ddbookstore/pages/bookInsertion/pages/image_options_page.dart';
import 'package:ddbookstore/pages/content/pages/book_details_page.dart';
import 'package:ddbookstore/pages/content/pages/borrowed_books_page.dart';
import 'package:ddbookstore/pages/content/pages/main_page.dart';
import 'package:ddbookstore/pages/content/pages/owned_books_page.dart';
import 'package:ddbookstore/pages/content/pages/profile_page.dart';
import 'package:ddbookstore/pages/content/pages/request_page.dart';
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
        // Validation Pages
        '/home_page': (context) => const HomePage(),
        '/login_page': (context) => const LoginPage(),
        '/register_page': (context) => const RegisterPage(),
        '/verifyEmail_page': (context) => const VerifyEmailPage(),

        // Main Pages
        '/main_page': (context) => const MainPage(),
        '/profile_page': (context) => const ProfilePage(),
        '/book_details': (context) => const BookDetailsPage(),
        '/request_page': (context) => const RequestPage(),
        '/borrowed_books_page': (context) => const BorrowedBooksPage(),
        '/owned_books_page': (context) => const OwnedBooksPage(),

        // Book Entry Pages
        '/bookMainPage': (context) => const BookMainPage(),
        '/bookTitleEntry': (context) => const BookTitleEntry(),
        '/displayDetailsPage': (context) => const DisplayDetailsPage(),
        '/image_options_page': (context) => const ImageOptionsPage(),
      },
    );
  }
}
