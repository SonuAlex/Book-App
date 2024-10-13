import 'package:ddbookstore/pages/content/models/book.dart';
import 'package:ddbookstore/pages/content/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookDetailsPage extends StatefulWidget {
  const BookDetailsPage({super.key});

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  late Book book;
  final StoreUser user = StoreUser();
  bool favoriteIcon = false;

  @override
  void didChangeDependencies() {
    book = ModalRoute.of(context)!.settings.arguments as Book;
    super.didChangeDependencies();
  }

  void addToFav() {
    setState(() {
      favoriteIcon = !favoriteIcon;
    });
  }

  Future<bool> isRequested() async {
    final response = await user.hasRequested(
        book.title, FirebaseAuth.instance.currentUser!.uid, book.ownedBy);
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(favoriteIcon ? Icons.favorite : Icons.favorite_border),
            onPressed: addToFav,
          ),
          FutureBuilder<bool>(
            future: isRequested(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.data == false) {
                  return Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await book.requestBook(book.title);
                          setState(() {});
                        },
                        child: const Text('Borrow'),
                      ),
                      const SizedBox(width: 10),
                    ],
                  );
                } else {
                  return const SizedBox(
                    width: 85,
                    child: Text('Requested',
                        style: TextStyle(color: Colors.white)),
                  );
                }
              }
              return const CircularProgressIndicator();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              // Book Cover Image
              Image.network(
                book.coverImage!,
                height: 300,
              ),

              const SizedBox(height: 20),

              // Boook Title
              Text(
                book.title!,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              // Book Author
              Text(
                book.author!,
                style: const TextStyle(fontSize: 20),
              ),

              // Book Owner
              FutureBuilder<String>(
                future: book.getName(book.ownedBy),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(fontSize: 20, color: Colors.red),
                    );
                  } else {
                    return Text(
                      'Owned by: ${snapshot.data}',
                      style: const TextStyle(fontSize: 20),
                    );
                  }
                },
              ),

              // Book Availability
              RichText(
                text: TextSpan(
                  text: 'Availability: ',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                  ), // Default text style
                  children: <TextSpan>[
                    TextSpan(
                      text: book.isAvailable! ? 'Available' : 'Not Available',
                      style: TextStyle(
                        color: book.isAvailable! ? Colors.green : Colors.red,
                      ), // Green if available, red if not available
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // Book Description
              const Text(
                'Description:',
                style: TextStyle(fontSize: 20),
              ),
              Text(
                book.description!,
                style: const TextStyle(fontSize: 16),
              ),

              // Borrow Button
            ],
          ),
        ),
      ),
    );
  }
}
