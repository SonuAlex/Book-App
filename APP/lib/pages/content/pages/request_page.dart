import 'dart:async';
import 'dart:convert';
import 'dart:developer' as d;

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
  late final int resposneValue;
  final StreamController<RequestData> _streamController =
      StreamController.broadcast();

  @override
  void initState() {
    super.initState();
    fetchRequestData(FirebaseAuth.instance.currentUser!.uid);
  }

  Future<void> acceptRequest(String title, String userId) async {
    // Implement accept request logic here
    final url = Uri.parse('http://172.25.246.253:8000/acceptRequest');
    final Map<String, dynamic> request = {
      'title': title,
      'user_id': userId,
    };
    final response = await http.post(url, body: json.encode(request), headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      setState(() {
        fetchRequestData(FirebaseAuth.instance.currentUser!.uid);
      });
    } else {
      d.log('Failed to accept request: ${response.statusCode}');
    }
  }

  Future<void> rejectRequest(String title, String userId) async {
    // Implement reject request logic here
    final url = Uri.parse('http://172.25.246.253:8000/rejectRequest');
    final Map<String, dynamic> request = {
      'title': title,
      'user_id': userId,
    };
    final response = await http.post(url, body: json.encode(request), headers: {
      'Content-Type': 'application/json',
    });
    if (response.statusCode == 200) {
      setState(() {
        fetchRequestData(FirebaseAuth.instance.currentUser!.uid);
      });
    } else {
      d.log('Failed to reject request: ${response.statusCode}');
    }
  }

  Future<void> cancelRequest(String title, String userId) async {
    // Implement cancel request logic here
    final url = Uri.parse('http://172.25.246.253:8000/cancelRequest');
    final Map<String, dynamic> request = {
      'title': title,
      'user_id': userId,
    };
    final response = await http.post(url, body: json.encode(request), headers: {
      'Content-Type': 'application/json',
    });
    if (response.statusCode == 200) {
      setState(() {
        fetchRequestData(FirebaseAuth.instance.currentUser!.uid);
      });
    } else {
      d.log('Failed to cancel request: ${response.statusCode}');
    }
  }

  Future<void> fetchRequestData(String userId) async {
    final url =
        Uri.parse('http://172.25.246.253:8000/requests?user_id=$userId');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final requestData = RequestData.fromJson(data);

        // Fetch response data for all outgoing requests
        for (var request in requestData.outgoing) {
          request.response =
              await fetchResponseData(request.userId, request.title);
        }

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

  Future<int> fetchResponseData(String userId, String title) async {
    final url = Uri.parse(
        'http://172.25.246.253:8000/response?user_id=$userId&title=$title');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body)['response'];
    } else {
      d.log('Failed to load response: ${response.statusCode}');
      return -2; // Indicate an error
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

                              return ListTile(
                                title: Text(request.title),
                                subtitle: RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Requested by: ',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.black),
                                      ),
                                      TextSpan(
                                        text: request.requestedBy,
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.green),
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
                                            request.title, request.userId),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.red,
                                          size: 30,
                                        ),
                                        onPressed: () => rejectRequest(
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

                              if (request.response == 0) {
                                return ListTile(
                                  title: Text(request.title),
                                  subtitle: Text(
                                    // request.response == 0 ?
                                    'Book has yet to be accepted',
                                    // : request.response == 1
                                    //     ? 'Book has been accepted'
                                    //     : request.response == -1
                                    //         ? 'Book has been rejected'
                                    //         : 'Error getting status of the book',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: request.response == 1
                                          ? Colors.green
                                          : request.response == -1
                                              ? Colors.red
                                              : Colors.black,
                                    ),
                                  ),
                                  trailing: request.response == 0
                                      ? SizedBox(
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
                                                    request.title,
                                                    request.userId),
                                              ),
                                            ],
                                          ),
                                        )
                                      : null,
                                );
                              } else {
                                return const ListTile();
                              }
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
