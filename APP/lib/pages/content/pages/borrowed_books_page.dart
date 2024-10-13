import 'dart:convert';
import 'dart:developer' as d;

import 'package:ddbookstore/pages/content/models/book.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BorrowedBooksPage extends StatefulWidget {
  const BorrowedBooksPage({super.key});

  @override
  State<BorrowedBooksPage> createState() => _BorrowedBooksPageState();
}

class _BorrowedBooksPageState extends State<BorrowedBooksPage> {
  Future<List<Map<String, dynamic>>> fetchBorrowedBooks() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final url = Uri.parse(
        'https://ghoul-nearby-daily.ngrok-free.app/borrowedBooks?user_id=$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final List<Map<String, dynamic>> borrowedBooks = [];
      for (final book in data) {
        borrowedBooks.add({
          'title': book['title'],
          'author': book['author'],
          'coverImage': book['coverImage'],
          'borrowed_by': book['borrowed_by'],
          'description': book['description'],
          'isAvailable': book['available'],
        });
      }
      return borrowedBooks;
    } else {
      throw Exception('Failed to load borrowed books');
    }
  }

  Future<void> returnBook(String title) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final url = Uri.parse(
        'https://ghoul-nearby-daily.ngrok-free.app/return?user_id=$userId&title=$title');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to return book');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('Borrowed Books'),
        ),
        // backgroundColor: Colors.grey,
        shadowColor: Colors.grey,
        actions: const [
          SizedBox(
            width: 50,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchBorrowedBooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            d.log(snapshot.error.toString());
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Retry the future
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData) {
            return Scrollbar(
              thumbVisibility: true,
              child: ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Image.network(snapshot.data![index]['coverImage']),
                    title: Text(snapshot.data![index]['title'],
                        overflow: TextOverflow.ellipsis),
                    subtitle: Text(snapshot.data![index]['author'],
                        overflow: TextOverflow.ellipsis),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        await returnBook(snapshot.data![index]['title']);
                        setState(() {});
                      },
                      style: const ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(Colors.red),
                          foregroundColor:
                              WidgetStatePropertyAll(Colors.white)),
                      child: const Text('Return'),
                    ),
                    onTap: () {
                      Book book = Book(
                        title: snapshot.data![index]['title'],
                        author: snapshot.data![index]['author'],
                        coverImage: snapshot.data![index]['coverImage'],
                        currentlyHas: snapshot.data![index]['borrowed_by'],
                        ownedBy: FirebaseAuth.instance.currentUser!.uid,
                        description: snapshot.data![index]['description'],
                        isAvailable: snapshot.data![index]['isAvailable'],
                      );
                      Navigator.pushNamed(context, '/book_details',
                          arguments: book);
                    },
                  );
                },
              ),
            );
          } else {
            return const Center(
              child: Text('No data found'),
            );
          }
        },
      ),
      floatingActionButton: IconButton(
        onPressed: () {
          setState(() {});
        },
        style: const ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.blue),
          foregroundColor: WidgetStatePropertyAll(Colors.white),
        ),
        constraints: const BoxConstraints(
          minWidth: 50,
          minHeight: 50,
        ),
        icon: const Icon(Icons.refresh),
      ),
    );
  }
}
