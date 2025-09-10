import 'package:flutter/material.dart';
import 'package:ramanas_waiter/Reusable/color.dart';

import 'navigator_item.dart';

class DashboardScreen extends StatefulWidget {
  final selectTab;

  const DashboardScreen({super.key, this.selectTab});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  int currentIndex = 0;

  callApis() async {
    if (widget.selectTab == 1) {
      currentIndex = 1;
    }
  }

  @override
  void initState() {
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
        body: navigatorItems[currentIndex].screen,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(15),
              topLeft: Radius.circular(15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black38.withOpacity(0.1),
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
