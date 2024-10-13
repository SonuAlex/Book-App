import 'package:flutter/material.dart';

class BookTitleEntry extends StatefulWidget {
  const BookTitleEntry({super.key});

  @override
  State<BookTitleEntry> createState() => _BookTitleEntryState();
}

class _BookTitleEntryState extends State<BookTitleEntry> {
  final TextEditingController _bookTitle = TextEditingController();

  @override
  void dispose() {
    _bookTitle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 300,
              child: TextField(
                controller: _bookTitle,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  labelText: 'Enter Book Title',
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/displayDetailsPage',
                      arguments: _bookTitle.text);
                },
                child: const Text('Search'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
