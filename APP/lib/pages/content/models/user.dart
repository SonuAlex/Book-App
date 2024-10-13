import 'dart:convert';
import 'dart:developer' as d;
import 'package:http/http.dart' as http;

class StoreUser {
  final String? fullName;
  final int? phone;
  final String? flatNo;
  final String? email;
  final String? userId;
  final int? hostedBooks;
  final int? borrowedBooks;
  final List<dynamic>? borrowedBookList;

  StoreUser({
    this.fullName,
    this.phone,
    this.flatNo,
    this.email,
    this.userId,
    this.hostedBooks,
    this.borrowedBooks,
    this.borrowedBookList,
  });

  Future<void> addUser() async {
    // Add user using api
    final url = Uri.parse('https://ghoul-nearby-daily.ngrok-free.app/user');
    Map<String, dynamic> request = {
      'user_id': userId,
      'name': fullName,
      'email': email,
      'phone': phone,
      'flat_no': flatNo
    };
    final response = await http.post(
      url,
      body: json.encode(request),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add user');
    }
  }

  Future<void> verifyUser() async {
    final url = Uri.parse('https://ghoul-nearby-daily.ngrok-free.app/verify');
    Map<String, dynamic> request = {
      'user_id': userId,
    };

    final reponse = await http.post(
      url,
      body: json.encode(request),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (reponse.statusCode != 200) {
      throw Exception('Failed to verify user');
    }
  }

  Future<Map<String, dynamic>> getUser(getUserId) async {
    final url = Uri.parse(
        'https://ghoul-nearby-daily.ngrok-free.app/userDetails?user_id=$getUserId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user');
    }
  }

  Future<bool> hasRequested(title, userId, ownerId) async {
    try {
      final url = Uri.parse(
          'https://ghoul-nearby-daily.ngrok-free.app/requests?user_id=$userId');
      final response = await http.get(url);
      final data = json.decode(response.body)['outgoing'];
      for (var request in data) {
        if (request['title'] == title &&
            request['user_id'] == userId &&
            request['owner_id'] == ownerId) {
          return true;
        }
      }
    } catch (e) {
      d.log('Error: $e');
      return false;
    }
    return false;
  }
}
