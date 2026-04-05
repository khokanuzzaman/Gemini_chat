// Feature: Split
// Layer: Presentation

import 'package:flutter/material.dart';

class PersonColor {
  const PersonColor._();

  static Color getColor(int index) {
    const colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }
}
