import 'package:flutter/material.dart';
import 'package:ramanas_waiter/UI/Landing/Home/home_screen.dart';
import 'package:ramanas_waiter/UI/Landing/Order/order_screen.dart';

class NavigatorItem {
  final IconData iconData;
  final int index;
  final Widget screen;

  NavigatorItem(this.iconData, this.index, this.screen);
}

List<NavigatorItem> navigatorItems = [
  NavigatorItem(Icons.home_outlined, 0, HomePage()),
  NavigatorItem(Icons.shopping_cart_outlined, 1, const OrderPage()),
];
