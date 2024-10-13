import 'package:flutter/material.dart';

class MyTableRow extends StatelessWidget {
  final String text;
  final String text2;
  const MyTableRow({super.key, required this.text, required this.text2});

  TableRow getTableRow() {
    return TableRow(
      children: [
        SizedBox(height: 10, child: Center(child: Text(text))),
        Center(child: Text(text2)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
