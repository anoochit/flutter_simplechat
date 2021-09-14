import 'package:flutter/material.dart';

Widget getavatar({required String displayName}) {
  return CircleAvatar(
    child: Text(
      displayName.toUpperCase().characters.first,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    backgroundColor: Colors.pink.shade100,
  );
}
