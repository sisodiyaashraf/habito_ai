import 'package:flutter/material.dart';

class Responsive {
  static double width(BuildContext context) => MediaQuery.of(context).size.width;
  static double height(BuildContext context) => MediaQuery.of(context).size.height;

  static bool isMobile(BuildContext context) => width(context) < 600;
  static bool isTablet(BuildContext context) => width(context) >= 600 && width(context) < 1200;
  static bool isDesktop(BuildContext context) => width(context) >= 1200;

  static double scaleText(BuildContext context, double size) {
    double scaleFactor = isMobile(context) ? 1.0 : (isTablet(context) ? 1.2 : 1.4);
    return size * scaleFactor;
  }

  static double scalePadding(BuildContext context, double padding) {
    return isMobile(context) ? padding : padding * 1.5;
  }
}
