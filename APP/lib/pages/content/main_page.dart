import 'package:ddbookstore/pages/content/components/my_drawer.dart';
import 'package:ddbookstore/pages/content/components/my_list_tile.dart';
import 'package:ddbookstore/pages/content/models/book.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final Book book = Book();
  late Future<List<dynamic>> books;

  @override
  void initState() {
    books = book.bookDetails();
    super.initState();
  }

  Future<void> onRefresh() async {
    setState(() {
      books = book.bookDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('Main Page'),
        ),
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.grey.shade700,
        actions: [
          Row(
            children: [
              IconButton(
                color: Colors.grey.shade700,
                icon: const Icon(Icons.person),
                onPressed: () => Navigator.pushNamed(context, '/profile_page'),
                style: ButtonStyle(
                  shape: WidgetStateProperty.all(const CircleBorder(
                      side: BorderSide(color: Colors.grey, width: 3))),
                ),
              ),
              const SizedBox(
                width: 15,
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      drawer: const MyDrawer(),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: FutureBuilder<List<dynamic>>(
          future: books,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: onRefresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No books found'));
            }

            if (snapshot.hasData) {
              final booksList = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: booksList.length,
                itemBuilder: (context, index) {
                  final bookData = booksList[index];
                  final Book book = Book(
                      author: bookData['author'],
                      coverImage: bookData['coverImage'],
                      description: bookData['description'],
                      title: bookData['title'],
                      ownedBy: bookData['user_id'],
                      isAvailable: bookData['available'],
                      currentlyHas: bookData['borrowed_by']);

                  return MyListTile(
                    book: book,
                  );
                },
              );
            }

            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
