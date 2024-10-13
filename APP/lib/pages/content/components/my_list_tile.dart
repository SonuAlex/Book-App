import 'package:ddbookstore/pages/content/models/book.dart';
import 'package:flutter/material.dart';

class MyListTile extends StatelessWidget {
  final Book book;
  const MyListTile({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120, // Set the desired height
      padding: const EdgeInsets.all(8.0), // Add padding for better readability
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      margin: const EdgeInsets.only(bottom: 10.0),
      child: Center(
        child: ListTile(
          leading: Image.network(
            book.coverImage!,
          ),
          title: Text(
            book.title!,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            book.author!,
            style: const TextStyle(fontSize: 16),
          ),
          trailing: const Icon(Icons.arrow_forward_rounded),
          onTap: () {
            // Navigate to the book details page
            Navigator.pushNamed(context, '/book_details', arguments: book);
          },
        ),
      ),
    );
  }
}
