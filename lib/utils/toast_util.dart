import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showModernToast({
  required String message,
  Color backgroundColor = const Color(0xFF615EFC),
  Color textColor = Colors.white,
  ToastGravity gravity = ToastGravity.BOTTOM,
}) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: gravity,
    backgroundColor: backgroundColor,
    textColor: textColor,
    fontSize: 16.0,
  );
}
