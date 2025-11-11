import 'package:flutter/material.dart';

class TextItem {
  String text;
  Offset position;
  double fontSize;
  Color color;
  FontWeight fontWeight;
  String fontFamily;

  TextItem({
    required this.text,
    required this.position,
    this.fontSize = 24,
    this.color = Colors.black,
    this.fontWeight = FontWeight.normal,
    this.fontFamily = 'Roboto',
  });

  TextItem copy() => TextItem(
    text: text,
    position: position,
    fontSize: fontSize,
    color: color,
    fontWeight: fontWeight,
    fontFamily: fontFamily,
  );
}