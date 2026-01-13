import 'package:flutter/material.dart';

class FlowerColor {
  final String name;
  final String key; // BLUE, ORANGE, PINK, PURPLE, RED
  final Color displayColor;
  final String level6ImagePath;

  const FlowerColor({
    required this.name,
    required this.key,
    required this.displayColor,
    required this.level6ImagePath,
  });

  // Get image path for a specific level (4, 5, or 6)
  String getImagePath(int level) {
    if (level < 4 || level > 6) {
      throw ArgumentError('Flower color images only available for levels 4-6');
    }
    // If default plant, use standard plant_levelX.svg
    if (key == 'DEFAULT') {
      return 'assets/images/plant_level$level.svg';
    }
    return 'assets/images/Level${level}_$key.svg';
  }
}

class FlowerColors {
  static const FlowerColor defaultPlant = FlowerColor(
    name: 'Mr YellowPlant',
    key: 'DEFAULT',
    displayColor: Color(0xFF8BC34A),
    level6ImagePath: 'assets/images/plant_level6.svg',
  );

  static const FlowerColor pink = FlowerColor(
    name: 'Mr PinkPlant',
    key: 'PINK',
    displayColor: Color(0xFFFF69B4),
    level6ImagePath: 'assets/images/Level6_PINK.svg',
  );

  static const FlowerColor blue = FlowerColor(
    name: 'Mr BluePlant',
    key: 'BLUE',
    displayColor: Color(0xFF4169E1),
    level6ImagePath: 'assets/images/Level6_BLUE.svg',
  );

  static const FlowerColor purple = FlowerColor(
    name: 'Mr PurplePlant',
    key: 'PURPLE',
    displayColor: Color(0xFF9370DB),
    level6ImagePath: 'assets/images/Level6_PURPLE.svg',
  );

  static const FlowerColor orange = FlowerColor(
    name: 'Mr OrangePlant',
    key: 'ORANGE',
    displayColor: Color(0xFFFF8C00),
    level6ImagePath: 'assets/images/Level6_ORANGE.svg',
  );

  static const FlowerColor red = FlowerColor(
    name: 'Mr RedPlant',
    key: 'RED',
    displayColor: Color(0xFFDC143C),
    level6ImagePath: 'assets/images/Level6_RED.svg',
  );

  static const List<FlowerColor> all = [
    defaultPlant,
    pink,
    blue,
    purple,
    orange,
    red,
  ];

  static FlowerColor getByKey(String key) {
    return all.firstWhere(
      (color) => color.key == key,
      orElse: () => defaultPlant, // Default to default plant if not found
    );
  }
}
