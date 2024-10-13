import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  String error = '';

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Log In')),
        backgroundColor: Colors.grey.shade200,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              const SizedBox(
                height: 50,
              ),
              const Icon(
                Icons.person,
                size: 72,
              ),
              const SizedBox(
                height: 100,
              ),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _email,
                  enableSuggestions: false,
                  autocorrect: false,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      const InputDecoration(hintText: 'Enter your email'),
                ),
              ),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _password,
                  enableSuggestions: false,
                  autocorrect: false,
                  obscureText: true,
                  decoration:
                      const InputDecoration(hintText: 'Enter your password'),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                error,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: () async {
                  final email = _email.text;
                  final password = _password.text;

                  try {
                    final userCredential = await FirebaseAuth.instance
                        .signInWithEmailAndPassword(
                            email: email, password: password);
                    devtools.log(userCredential.toString());
                  } on FirebaseAuthException catch (e) {
                    switch (e.code) {
                      case 'invalid-email':
                        devtools.log('Invalid Email');
                        setState(() {
                          error = 'Invalid Email';
                        });
                        break;
                      case 'user-disabled':
                        devtools.log('User has been disabled');
                        setState(() {
                          error = 'This account is disabled';
                        });
                        break;
                      case 'invalid-credential':
                        devtools.log('Invalid Email or Password');
                        setState(() {
                          error = 'Incorrect Email or Password';
                        });
                        break;
                      default:
                        devtools.log('Error ${e.code} ');
                        setState(() {
                          error = 'Something has gone wrong.\nPlease try again';
                        });
                    }
                  }
                  if (FirebaseAuth.instance.currentUser != null) {
                    if (FirebaseAuth.instance.currentUser?.emailVerified ==
                        false) {
                      Navigator.pushNamed(context, '/verifyEmail_page');
                    } else {
                      Navigator.pushNamedAndRemoveUntil(
                        // Change the route to an actual route
                        context,
                        '/main_page',
                        (route) => false,
                      );
                    }
                  }
                },
                child: const Text('Log In'),
              ),
              TextButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      // Change the route to an actual route
                      context,
                      '/register_page',
                      (route) => false,
                    );
                  },
                  child: const Text('Not Register yet? Register Here!'))
            ],
          ),
        ),
      ),
    );
  }
}
