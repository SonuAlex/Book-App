import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DisplayDetailsPage extends StatefulWidget {
  const DisplayDetailsPage({super.key});

  @override
  State<DisplayDetailsPage> createState() => _DisplayDetailsPageState();
}

class _DisplayDetailsPageState extends State<DisplayDetailsPage> {
  late String title;

  @override
  void didChangeDependencies() {
    title = ModalRoute.of(context)!.settings.arguments as String;
    super.didChangeDependencies();
  }

  Future<Map<String, dynamic>> getDataByTitle(String title) async {
    final url = Uri.parse('https://ghoul-nearby-daily.ngrok-free.app/book');
    final request = {
      "user_id": FirebaseAuth.instance.currentUser!.uid,
      "title": title,
    };
    final response = await http.post(url, body: json.encode(request), headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<Map<String, dynamic>> addBookToUser(Map<String, dynamic> data) async {
    final url = Uri.parse('https://ghoul-nearby-daily.ngrok-free.app/submit');
    final response = await http.post(url, body: json.encode(data), headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getDataByTitle(title),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Error'),
            ),
          );
        } else {
          final data = snapshot.data!;
          return Scaffold(
            appBar: AppBar(
              title: Center(
                child: Text('Book Details: ${data['title']}'),
              ),
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.grey.shade700,
              actions: [
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                  child: ElevatedButton(
                    style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.green),
                      foregroundColor: WidgetStatePropertyAll(Colors.white),
                    ),
                    onPressed: () async {
                      data['user_id'] = FirebaseAuth.instance.currentUser!.uid;
                      final response = await addBookToUser(data);
                      if (response['status'] == 200) {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/main_page', (route) => false);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Center(child: Text(response['message'])),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    child: const Text("Add?"),
                  ),
                )
              ],
            ),
            body: Center(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        data['coverImage'],
                      ),
                      const SizedBox(height: 20),
                      RichText(
                        text: TextSpan(
                          text: 'Title: ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Colors.red,
                          ),
                          children: [
                            TextSpan(
                              text: data['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 17,
                                color: Colors.black,
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      RichText(
                        text: TextSpan(
                          text: 'Author: ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Colors.red,
                          ),
                          children: [
                            TextSpan(
                              text: data['author'],
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 17,
                                color: Colors.black,
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      RichText(
                        text: TextSpan(
                          text: 'Description: ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Colors.red,
                          ),
                          children: [
                            TextSpan(
                              text: data['description'],
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 17,
                                color: Colors.black,
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
