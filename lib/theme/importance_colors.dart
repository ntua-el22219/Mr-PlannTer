import 'package:flutter/material.dart';

/// Returns a color based on importance and type.
/// For deadlines: more important = more red.
/// For tasks: more important = more blue.
/// Importance is expected in [1,5].
Color getImportanceColor({required String type, required int importance}) {
  // Clamp importance
  final imp = importance.clamp(1, 5);
  if (type == 'deadline') {
    // Red gradient: light to strong
    const colors = [
      Color(0xFFFFE5E5), // 1: very light red
      Color(0xFFFFB3B3), // 2
      Color(0xFFFF8080), // 3
      Color(0xFFFF4D4D), // 4
      Color(0xFFFF1A1A), // 5: strong red
    ];
    return colors[imp - 1];
  } else {
    // Task: blue gradient: light to strong
    const colors = [
      Color(0xFFE5F0FF), // 1: very light blue
      Color(0xFFB3D1FF), // 2
      Color(0xFF80B3FF), // 3
      Color(0xFF4D94FF), // 4
      Color(0xFF1A75FF), // 5: strong blue
    ];
    return colors[imp - 1];
  }
}
