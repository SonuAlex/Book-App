import 'package:flutter/material.dart';

class MyDrawerTile extends StatelessWidget {
  final Icon icon;
  final String title;
  final GestureTapCallback onTap;
  const MyDrawerTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 25.0),
      child: ListTile(
        leading: icon,
        title: Text(title),
        onTap: onTap,
      ),
    );
  }
}
