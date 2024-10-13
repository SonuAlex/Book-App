import 'package:flutter/material.dart';

class BookMainPage extends StatelessWidget {
  const BookMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('List Books')),
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.grey.shade700,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "How would you like to list your books?",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 40,
            ),

            // Adding books via title
            Container(
              width: 200,
              padding: const EdgeInsets.fromLTRB(7, 1, 7, 1),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Colors.cyan, Colors.indigoAccent],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/bookTitleEntry');
                },
                child: const Text('By Title'),
              ),
            ),

            // Adding books via book cover image
            Container(
              width: 200,
              padding: const EdgeInsets.fromLTRB(7, 1, 7, 1),
              margin: const EdgeInsets.fromLTRB(0, 20, 0, 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Colors.limeAccent, Colors.green],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('By Cover Image'),
              ),
            ),
            const SizedBox(
              width: 200,
              child: Text(
                  'Disclaimer: This feature is currently under development and may not perform with full accuracy. We are continuously working to enhance its reliability. Please use it with discretion and report any issues to help us improve.',
                  style: TextStyle(fontSize: 7, color: Colors.red),
                  textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
