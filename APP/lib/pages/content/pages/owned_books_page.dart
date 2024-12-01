import 'dart:convert';

import 'package:ddbookstore/pages/content/models/book.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OwnedBooksPage extends StatefulWidget {
  const OwnedBooksPage({super.key});

  @override
  State<OwnedBooksPage> createState() => _OwnedBooksPageState();
}

class _OwnedBooksPageState extends State<OwnedBooksPage> {
  Future<List<Map<String, dynamic>>> fetchOwnedBooks() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final url =
        Uri.parse('http://172.25.246.253:8000/ownedBooks?user_id=$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final List<Map<String, dynamic>> ownedBooks = [];
      for (var book in data) {
        ownedBooks.add({
          'title': book['title'],
          'author': book['author'],
          'coverImage': book['coverImage'],
          'borrowed_by': book['borrowed_by'],
          'description': book['description'],
          'isAvailable': book['available'],
        });
      }
      return ownedBooks;
    } else {
      throw Exception('Failed to load owned books');
    }
  }

  Future<void> deleteBook(String title) async {
    final url = Uri.parse('http://172.25.246.253:8000/deleteBook');
    final Map<String, dynamic> request = {
      'title': title,
      'user_id': FirebaseAuth.instance.currentUser!.uid,
    };
    final response = await http.post(url,
        body: json.encode(request),
        headers: {'Content-Type': 'application/json'});

    if (response.statusCode != 200) {
      throw Exception('Failed to delete book');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Center(
            child: Text('My Books'),
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
          future: fetchOwnedBooks(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  children: [
                    const Text('Error'),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {});
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasData) {
              return ListView.builder(
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
                        await deleteBook(snapshot.data![index]['title']);
                        setState(() {});
                      },
                      style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.red),
                        foregroundColor: WidgetStatePropertyAll(Colors.white),
                      ),
                      child: const Text('Delete'),
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
              );
            } else {
              return const Center(
                child: Text('No data'),
              );
            }
          },
        ));
  }
}
