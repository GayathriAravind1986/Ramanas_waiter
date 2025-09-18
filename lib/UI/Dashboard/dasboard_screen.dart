import 'package:flutter/material.dart';
import 'package:ramanas_waiter/ModelClass/Order/Get_view_order_model.dart';
import 'package:ramanas_waiter/Reusable/color.dart';
import 'package:ramanas_waiter/UI/Landing/Home/home_screen.dart';
import 'package:ramanas_waiter/UI/Landing/Order/order_screen.dart';
import 'navigator_item.dart';

class DashboardScreen extends StatefulWidget {
  final selectTab;
  final GetViewOrderModel? existingOrder;
  final bool? isEditingOrder;
  const DashboardScreen({
    super.key,
    this.selectTab,
    this.existingOrder,
    this.isEditingOrder,
  });

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  int currentIndex = 0;

  GetViewOrderModel? currentOrder;
  bool? currentIsEditing;

  Widget getCurrentScreen() {
    switch (currentIndex) {
      case 0:
        return HomePage(
          existingOrder: currentOrder,
          isEditingOrder: currentIsEditing,
        );
      case 1:
        return OrderPage();
      default:
        return HomePage(
          existingOrder: currentOrder,
          isEditingOrder: currentIsEditing,
        );
    }
  }

  List<NavigatorItem> get navigatorItems => [
    NavigatorItem(Icons.home_outlined, 0, Container()),
    NavigatorItem(Icons.shopping_cart_outlined, 1, Container()),
  ];

  Future<void> callApis() async {
    if (widget.selectTab == 1) {
      currentIndex = 1;
    }
  }

  @override
  void initState() {
    currentOrder = widget.existingOrder;
    currentIsEditing = widget.isEditingOrder;
    callApis();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          if (currentIndex == 0) {
            debugPrint("Pop action was Unblocked.");
            Navigator.pop(context);
          }
        } else {
          debugPrint("Pop action was blocked.");
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (Route<dynamic> route) => false,
          );
        }
      },
      child: Scaffold(
        body: getCurrentScreen(),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(15),
              topLeft: Radius.circular(15),
            ),
            boxShadow: [
              BoxShadow(
                color: blackColor45,
                spreadRadius: 0,
                blurRadius: 37,
                offset: const Offset(0, -12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: BottomNavigationBar(
              backgroundColor: appPrimaryColor,
              currentIndex: currentIndex,
              onTap: (index) {
                setState(() {
                  currentIndex = index;
                  if (index == 1) {
                    currentOrder = null;
                    currentIsEditing = null;
                  }
                });
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: appPrimaryColor,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              unselectedItemColor: whiteColor,
              items: navigatorItems.map((e) {
                return getNavigationBarItem(
                  index: e.index,
                  iconData: e.iconData,
                  size: size,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem getNavigationBarItem({
    required int index,
    required IconData iconData,
    required Size size,
  }) {
    bool isSelected = index == currentIndex;
    Color itemIconColor = isSelected ? appPrimaryColor : whiteColor;
    Color itemBackgroundColor = isSelected ? whiteColor : Colors.transparent;

    return BottomNavigationBarItem(
      label: '',
      icon: SizedBox(
        height: 35,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  alignment: Alignment.center,
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: itemBackgroundColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Icon(iconData, size: 24, color: itemIconColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
