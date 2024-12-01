import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CoverBook {
  final String? title;
  final String? author;
  final String? coverImage;
  final String? description;

  CoverBook({
    this.title,
    this.author,
    this.coverImage,
    this.description,
  });
}

class CoverImageService {
  String userId;
  File coverImage;

  CoverImageService({required this.userId, required this.coverImage});

  Future<String> getFromImage() async {
    final url = Uri.parse('http://172.25.246.253:8000/cover');

    var request = http.MultipartRequest('POST', url);
    request.fields['user_id'] = userId;
    request.files
        .add(await http.MultipartFile.fromPath('file', coverImage.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);
      return data['title'];
    } else {
      throw Exception('Failed to load book title');
    }
  }
}
