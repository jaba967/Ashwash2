import 'package:flutter/material.dart';

class CategoryModel {
  final int id;
  final String slug;
  final String titleEn;
  final String titleBn;
  final String descriptionEn;
  final String descriptionBn;
  final String icon;
  final String colorHex;

  CategoryModel({
    required this.id,
    required this.slug,
    required this.titleEn,
    required this.titleBn,
    required this.descriptionEn,
    required this.descriptionBn,
    required this.icon,
    required this.colorHex,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      slug: json['slug'] ?? '',
      titleEn: json['title_en'] ?? '',
      titleBn: json['title_bn'] ?? '',
      descriptionEn: json['description_en'] ?? '',
      descriptionBn: json['description_bn'] ?? '',
      icon: json['icon'] ?? 'heart',
      colorHex: json['color_hex'] ?? '#EC4899',
    );
  }

  Color get color {
    final hexString = colorHex.replaceAll('#', '');
    return Color(int.parse('FF$hexString', radix: 16));
  }
}
