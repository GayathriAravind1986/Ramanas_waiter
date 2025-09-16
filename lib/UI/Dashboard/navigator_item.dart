import 'package:flutter/material.dart';

class NavigatorItem {
  final IconData iconData;
  final int index;
  final Widget screen;

  NavigatorItem(this.iconData, this.index, this.screen);
}
