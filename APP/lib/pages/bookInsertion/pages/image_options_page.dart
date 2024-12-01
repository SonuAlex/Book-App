import 'dart:io';

import 'package:ddbookstore/pages/bookInsertion/services/cover_image_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageOptionsPage extends StatefulWidget {
  const ImageOptionsPage({super.key});

  @override
  State<ImageOptionsPage> createState() => _ImageOptionsPageState();
}

class _ImageOptionsPageState extends State<ImageOptionsPage> {
  Future _pickImageFromGallery() async {
    final returnedValue =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnedValue == null) return;
    return returnedValue;
  }

  Future _pickImageFromCamera() async {
    final returnedValue =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (returnedValue == null) return;
    return returnedValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Upload Book Cover')),
        actions: const [
          SizedBox(
            width: 40,
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('How would you like to upload the book cover?'),
            const SizedBox(
              height: 30,
            ),
            Container(
              width: 200,
              padding: const EdgeInsets.fromLTRB(7, 1, 7, 1),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.cyanAccent],
                ),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  final XFile? data = await _pickImageFromGallery();
                  if (data == null) return;
                  final File? _selectedImage = File(data.path);
                  final String result = await CoverImageService(
                          userId: FirebaseAuth.instance.currentUser!.uid,
                          coverImage: _selectedImage!)
                      .getFromImage();
                  Navigator.pushNamed(context, '/displayDetailsPage',
                      arguments: result);
                },
                child: const Text('Open Gallery'),
              ),
            ),
            Container(
              width: 200,
              padding: const EdgeInsets.fromLTRB(7, 1, 7, 1),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Colors.red, Colors.amberAccent],
                ),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  final XFile? data = await _pickImageFromCamera();
                  if (data == null) return;
                  final File? _selectedImage = File(data.path);
                  final String result = await CoverImageService(
                          userId: FirebaseAuth.instance.currentUser!.uid,
                          coverImage: _selectedImage!)
                      .getFromImage();
                  Navigator.pushNamed(context, '/displayDetailsPage',
                      arguments: result);
                },
                child: const Text('Open Camera'),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
