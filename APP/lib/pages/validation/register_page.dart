import 'package:ddbookstore/pages/content/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _flatNo;
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _repassword;
  String error = '';

  @override
  void initState() {
    _email = TextEditingController();
    _fullName = TextEditingController();
    _phone = TextEditingController();
    _flatNo = TextEditingController();
    _password = TextEditingController();
    _repassword = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _fullName.dispose();
    _phone.dispose();
    _flatNo.dispose();
    _password.dispose();
    _repassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('Register'),
        ),
        backgroundColor: Colors.grey.shade200,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              const Icon(
                Icons.person,
                size: 72,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _fullName,
                      enableSuggestions: true,
                      autocorrect: false,
                      decoration: const InputDecoration(hintText: 'Full Name'),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 195,
                        child: TextField(
                          controller: _phone,
                          enableSuggestions: false,
                          autocorrect: false,
                          keyboardType: TextInputType.phone,
                          decoration:
                              const InputDecoration(hintText: 'Phone No.'),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      SizedBox(
                          width: 95,
                          child: TextField(
                              controller: _flatNo,
                              enableSuggestions: false,
                              autocorrect: false,
                              keyboardType: TextInputType.streetAddress,
                              decoration:
                                  const InputDecoration(hintText: 'Flat No'))),
                    ],
                  ),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _email,
                      enableSuggestions: false,
                      autocorrect: false,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'Email'),
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _password,
                      enableSuggestions: false,
                      autocorrect: false,
                      obscureText: true,
                      decoration: const InputDecoration(hintText: 'Password'),
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _repassword,
                      enableSuggestions: false,
                      autocorrect: false,
                      obscureText: true,
                      decoration:
                          const InputDecoration(hintText: 'Re-Type Password'),
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
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_email.text.isEmpty ||
                          _password.text.isEmpty ||
                          _repassword.text.isEmpty ||
                          _fullName.text.isEmpty ||
                          _phone.text.isEmpty ||
                          _flatNo.text.isEmpty ||
                          _phone.text.length != 10) {
                        setState(() {
                          error = 'Please fill all the fields correctly';
                        });
                      } else if (_password.text != _repassword.text) {
                        setState(() {
                          error = '';
                        });
                      } else {
                        final email = _email.text;
                        final password = _password.text;
                        try {
                          final userCred = await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                                  email: email, password: password);
                          devtools.log(userCred.toString());
                        } on FirebaseAuthException catch (e) {
                          if (e.code == 'invalid-email') {
                            devtools.log('Invalid Email');
                            setState(() {
                              error = 'Invalid Email';
                            });
                          } else if (e.code == 'weak-password') {
                            devtools.log('Weak Password');
                            setState(() {
                              error =
                                  'Weak Password\nPassword should be longer than 5';
                            });
                          } else if (e.code == 'email-already-in-use') {
                            devtools.log('Email is already In-use');
                            setState(() {
                              error = 'Email address is already taken';
                            });
                          } else {
                            devtools.log(e.code);

                            setState(() {
                              error = 'Something has gone wrong';
                            });
                          }
                        }
                        if (FirebaseAuth.instance.currentUser != null) {
                          final StoreUser user = StoreUser(
                            email: _email.text,
                            flatNo: _flatNo.text,
                            fullName: _fullName.text,
                            phone: int.parse(_phone.text),
                            userId: FirebaseAuth.instance.currentUser!.uid,
                          );
                          user.addUser();
                          Navigator.pushNamed(context, '/verifyEmail_page',
                              arguments: user);
                        }
                      }
                    },
                    child: const Text('Register'),
                  ),
                  TextButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login_page',
                          (route) => false,
                        );
                      },
                      child: const Text('Already Registered? Login Here!'))
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
