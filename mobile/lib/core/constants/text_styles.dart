import 'package:flutter/material.dart';

class AppTextStyles {
  // Headings
  static TextStyle h1({Color? color}) => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: color ?? Colors.black87,
        height: 1.2,
      );

  static TextStyle h2({Color? color}) => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: color ?? Colors.black87,
        height: 1.2,
      );

  static TextStyle h3({Color? color}) => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: color ?? Colors.black87,
        height: 1.3,
      );

  static TextStyle h4({Color? color}) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color ?? Colors.black87,
        height: 1.3,
      );

  // Body Text
  static TextStyle bodyLarge({Color? color, FontWeight? fontWeight}) => TextStyle(
        fontSize: 18,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? Colors.black87,
        height: 1.5,
      );

  static TextStyle bodyMedium({Color? color, FontWeight? fontWeight}) => TextStyle(
        fontSize: 16,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? Colors.black87,
        height: 1.5,
      );

  static TextStyle bodySmall({Color? color}) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: color ?? Colors.black87,
        height: 1.5,
      );

  // Button Text
  static TextStyle button({Color? color}) => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color ?? Colors.white,
      );

  static TextStyle buttonSmall({Color? color}) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color ?? Colors.white,
      );

  // Label Text
  static TextStyle label({Color? color}) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color ?? Colors.black87,
      );

  // Caption Text
  static TextStyle caption({Color? color}) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: color ?? Colors.black54,
      );
}

