import 'dart:async';
import 'dart:convert';
import 'dart:developer' as d;

import 'package:ddbookstore/pages/content/models/book.dart';
import 'package:ddbookstore/pages/content/service/book_request.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final StreamController<RequestData> _streamController =
      StreamController.broadcast();

  @override
  void initState() {
    super.initState();
    fetchRequestData(FirebaseAuth.instance.currentUser!.uid);
  }

  Future<void> acceptRequest(String title, String userId) async {
    // Implement accept request logic here
    final url =
        Uri.parse('https://ghoul-nearby-daily.ngrok-free.app/acceptRequest');
    final Map<String, dynamic> request = {
      'title': title,
      'user_id': userId,
    };
    final response = await http.post(url, body: json.encode(request), headers: {
      'Content-Type': 'application/json',
    });
    setState(() {
      if (response.statusCode == 200) {
        fetchRequestData(FirebaseAuth.instance.currentUser!.uid);
      } else {
        d.log('Failed to accept request: ${response.statusCode}');
      }
    });
  }

  Future<void> rejectRequest(String title, String userId) async {
    // Implement reject request logic here
    final url =
        Uri.parse('https://ghoul-nearby-daily.ngrok-free.app/rejectRequest');
    final Map<String, dynamic> request = {
      'title': title,
      'user_id': userId,
    };
    final response = await http.post(url, body: json.encode(request), headers: {
      'Content-Type': 'application/json',
    });
    setState(() {
      if (response.statusCode == 200) {
        fetchRequestData(FirebaseAuth.instance.currentUser!.uid);
      } else {
        d.log('Failed to reject request: ${response.statusCode}');
      }
    });
  }

  Future<void> cancelRequest(String title, String userId) async {
    // Implement cancel request logic here
    final url =
        Uri.parse('https://ghoul-nearby-daily.ngrok-free.app/cancelRequest');
    final Map<String, dynamic> request = {
      'title': title,
      'user_id': userId,
    };
    final response = await http.post(url, body: json.encode(request), headers: {
      'Content-Type': 'application/json',
    });
    setState(() {
      if (response.statusCode == 200) {
        fetchRequestData(FirebaseAuth.instance.currentUser!.uid);
      } else {
        d.log('Failed to cancel request: ${response.statusCode}');
      }
    });
  }

  Future<void> fetchRequestData(String userId) async {
    final url = Uri.parse(
        'https://ghoul-nearby-daily.ngrok-free.app/requests?user_id=$userId');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final requestData = RequestData.fromJson(data);
        _streamController.add(requestData);
      } else {
        d.log('Failed to load requests: ${response.statusCode}');
        _streamController.addError('Failed to load requests');
      }
    } catch (e) {
      d.log('Failed to load requests: $e');
      _streamController.addError('Failed to load requests');
    }
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('Request Page'),
        ),
        actions: const [
          SizedBox(
            width: 20,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          fetchRequestData(FirebaseAuth.instance.currentUser!.uid);
        },
        child: const Icon(Icons.refresh),
      ),
      body: Column(
        // Inbox
        children: [
          const SizedBox(
            height: 20,
          ),
          Container(
            color: const Color.fromARGB(23, 33, 149, 243),
            height: 300,
            width: double.maxFinite,
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  'INBOX:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: StreamBuilder<RequestData>(
                    stream: _streamController.stream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        d.log('Error: ${snapshot.error}');
                        return const Center(
                          child: Text('Failed to load requests'),
                        );
                      } else if (!snapshot.hasData ||
                          snapshot.data!.incoming.isEmpty) {
                        return const Center(child: Text('No data available'));
                      } else {
                        final requests = snapshot.data!.incoming;
                        final ScrollController scrollController =
                            ScrollController();

                        return Scrollbar(
                          thumbVisibility: true,
                          interactive: true,
                          radius: const Radius.circular(10),
                          controller: scrollController,
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: requests.length,
                            itemBuilder: (context, index) {
                              final request = requests[index];

                              return FutureBuilder<String>(
                                future: Book().getName(request.userId),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const ListTile(
                                      title: Text('Loading...'),
                                    );
                                  } else if (snapshot.hasError) {
                                    return ListTile(
                                      title: Text(request.title),
                                      subtitle: const Text(
                                          'Failed to load user name',
                                          style: TextStyle(fontSize: 12)),
                                      trailing: SizedBox(
                                        width: 100,
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.check,
                                                color: Colors.green,
                                                size: 30,
                                              ),
                                              onPressed: () => acceptRequest(
                                                  request.title,
                                                  request.userId),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.red,
                                                size: 30,
                                              ),
                                              onPressed: () => rejectRequest(
                                                  request.title,
                                                  request.userId),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  } else {
                                    return ListTile(
                                      title: Text(request.title),
                                      subtitle: RichText(
                                        text: TextSpan(
                                          children: [
                                            const TextSpan(
                                              text: 'Requested by: ',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black),
                                            ),
                                            TextSpan(
                                              text: snapshot.data,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green),
                                            ),
                                          ],
                                        ),
                                      ),
                                      trailing: SizedBox(
                                        width: 100,
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.check,
                                                color: Colors.green,
                                                size: 30,
                                              ),
                                              onPressed: () => acceptRequest(
                                                  request.title,
                                                  request.userId),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.red,
                                                size: 30,
                                              ),
                                              onPressed: () => rejectRequest(
                                                  request.title,
                                                  request.userId),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          // Outbox
          Container(
            color: const Color.fromARGB(24, 76, 175, 79),
            height: 300,
            width: double.maxFinite,
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  'OUTBOX:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: StreamBuilder<RequestData>(
                    stream: _streamController.stream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (!snapshot.hasData ||
                          snapshot.data!.outgoing.isEmpty) {
                        return const Center(child: Text('No data available'));
                      } else {
                        final requests = snapshot.data!.outgoing;
                        final ScrollController scrollController =
                            ScrollController();

                        return Scrollbar(
                          thumbVisibility: true,
                          interactive: true,
                          radius: const Radius.circular(10),
                          controller: scrollController,
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: requests.length,
                            itemBuilder: (context, index) {
                              final request = requests[index];
                              return ListTile(
                                title: Text(request.title),
                                subtitle: const Text(
                                    'Book has yet to be accepted',
                                    style: TextStyle(fontSize: 12)),
                                trailing: SizedBox(
                                  width: 48,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.red,
                                          size: 30,
                                        ),
                                        onPressed: () => cancelRequest(
                                            request.title, request.userId),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
