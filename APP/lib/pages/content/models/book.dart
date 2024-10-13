import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as d;

class Book {
  final String? title;
  final String? author;
  final String? coverImage;
  final String? description;
  final String? ownedBy;
  final bool? isAvailable;
  final String? currentlyHas;

  Book({
    this.title,
    this.author,
    this.coverImage,
    this.description,
    this.ownedBy,
    this.isAvailable,
    this.currentlyHas,
  });

  Future<List<dynamic>> bookDetails() async {
    final url = Uri.parse('https://ghoul-nearby-daily.ngrok-free.app/allBooks');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> books = jsonDecode(response.body);
      return books;
    } else {
      throw Exception('Failed to load book details');
    }
  }

  Future<String> getName(userId) async {
    final url = Uri.parse(
        'https://ghoul-nearby-daily.ngrok-free.app/userDetails?user_id=$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> user = jsonDecode(response.body);
      return user['name'];
    } else {
      throw Exception('Failed to load user details');
    }
  }

  Future<String> requestBook(title) async {
    final url =
        Uri.parse('https://ghoul-nearby-daily.ngrok-free.app/requestBorrow');
    final Map<String, dynamic> request = {
      'title': title,
      'user_id': FirebaseAuth.instance.currentUser!.uid,
    };

    final response = await http.post(url, body: json.encode(request), headers: {
      'Content-Type': 'application/json',
    });

    Map<String, dynamic> data = jsonDecode(response.body);
    d.log('${data.toString()} for the book $title');

    return '';

    // if (response.statusCode == 200) {
    //   if(response['status'] == 400) {
    //     return response['message'];
    //   }
    //   return 'Request sent successfully';
    // }
  }
}
