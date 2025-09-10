import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ramanas_waiter/Bloc/demo/demo_bloc.dart';
import 'package:ramanas_waiter/Reusable/color.dart';
import 'package:ramanas_waiter/Reusable/responsive.dart';
import 'package:ramanas_waiter/Reusable/text_styles.dart';


class OrderPage extends StatelessWidget {
  final from;
  const OrderPage({super.key, this.from});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DemoBloc(),
      child: OrderPageView(from: from),
    );
  }
}

class OrderPageView extends StatefulWidget {
  final from;
  const OrderPageView({super.key, this.from});

  @override
  OrderPageViewState createState() => OrderPageViewState();
}

class OrderPageViewState extends State<OrderPageView> {
  TextEditingController searchController = TextEditingController();
  dynamic notCount = 0;
  dynamic wishCount = 3;
  bool homeLoad = false;
  DateTime? lastPressed;
  String? errorMessage;
  @override
  void initState() {
    //  context.read<HomeBloc>().add(Home(searchController.text ?? ""));
    homeLoad = true;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    Widget mainContainer() {
      return RefreshIndicator(
        displacement: 60.0,
        color: appPrimaryColor,
        onRefresh: () async {
          //searchController.clear();
          // context.read<HomeBloc>().add(Home(searchController.text ?? ""));
          homeLoad = true;
          setState(() {});
        },
        child: ResponsiveBuilder(
          mobileBuilder: (context, constraints) {
            return Text(
              "No Orders found !!!",
              style: MyTextStyle.f20(appHomeTextColor, weight: FontWeight.w500),
            );
          },
          tabletBuilder: (context, constraints) {
            return Text(
              "No Orders found !!!",
              style: MyTextStyle.f20(appHomeTextColor, weight: FontWeight.w500),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: whiteColor,
      appBar: PreferredSize(
        preferredSize: size.width < 650
            ? const Size.fromHeight(40)
            : const Size.fromHeight(75),
        child: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            width: double.infinity,
            color: whiteColor,
            padding: const EdgeInsets.only(top: 35, left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "Welcome",
                      style: size.width < 650
                          ? MyTextStyle.f20(
                        appPrimaryColor,
                        weight: FontWeight.bold,
                      )
                          : MyTextStyle.f30(
                        appPrimaryColor,
                        weight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: BlocBuilder<DemoBloc, dynamic>(
        buildWhen: ((previous, current) {
          return false;
        }),
        builder: (context, dynamic) {
          return mainContainer();
        },
      ),
    );
  }
}
