import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ramanas_waiter/Alertbox/AlertDialogBox.dart';
import 'package:ramanas_waiter/Alertbox/snackBarAlert.dart';
import 'package:ramanas_waiter/Bloc/Order/order_list_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ramanas_waiter/ModelClass/Order/Get_view_order_model.dart';
import 'package:ramanas_waiter/ModelClass/Order/Update_generate_order_model.dart';
import 'package:ramanas_waiter/ModelClass/Order/get_order_list_today_model.dart';
import 'package:ramanas_waiter/ModelClass/ShopDetails/getStockMaintanencesModel.dart';
import 'package:ramanas_waiter/ModelClass/Table/Get_table_model.dart';
import 'package:ramanas_waiter/ModelClass/User/getUserModel.dart';
import 'package:ramanas_waiter/ModelClass/Waiter/getWaiterModel.dart';
import 'package:ramanas_waiter/Reusable/color.dart';
import 'package:ramanas_waiter/Reusable/responsive.dart';
import 'package:ramanas_waiter/Reusable/text_styles.dart';
import 'package:ramanas_waiter/UI/Authentication/login_screen.dart';
import 'package:ramanas_waiter/UI/Dashboard/dasboard_screen.dart';
import 'package:ramanas_waiter/UI/Landing/Order/Helper/time_formatter.dart';
import 'package:ramanas_waiter/UI/Landing/Order/pop_view_order.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderPage extends StatelessWidget {
  final from;
  const OrderPage({super.key, this.from});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrderTodayBloc(),
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

class OrderPageViewState extends State<OrderPageView>
    with TickerProviderStateMixin {
  GetStockMaintanencesModel getStockMaintanencesModel =
      GetStockMaintanencesModel();
  GetViewOrderModel getViewOrderModel = GetViewOrderModel();
  GetTableModel getTableModel = GetTableModel();
  GetWaiterModel getWaiterModel = GetWaiterModel();
  GetUserModel getUserModel = GetUserModel();
  GetOrderListTodayModel getOrderListTodayModel = GetOrderListTodayModel();
  UpdateGenerateOrderModel updateGenerateOrderModel =
      UpdateGenerateOrderModel();
  final TextEditingController ipController = TextEditingController();
  final TextEditingController tipController = TextEditingController();
  bool orderLoad = false;
  bool tableLoad = false;
  bool view = false;
  bool completeLoad = false;
  dynamic selectedValue;
  dynamic selectedValueWaiter;
  dynamic selectedValueUser;
  dynamic tableId;
  dynamic waiterId;
  dynamic userId;
  dynamic operatorId;
  String selectedFullPaymentMethod = "";
  final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? fromDate;

  // Add TabController
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Tab names matching your order types
  final List<String> _tabNames = [
    "All",
    "Line",
    "AC",
    "Parcel",
    "HD",
    "SWIGGY",
  ];

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    _loadInitialData();
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> getOperatorId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      operatorId = prefs.getString("userId");
    });
    debugPrint("operatorId: $operatorId");
  }

  String? type;
  String? errorMessage;

  void _loadInitialData() {
    debugPrint("tableIntialLoad:$selectedValue");
    getOperatorId();
    setState(() {
      orderLoad = true;
      tableLoad = true;
      selectedValue = null;
      selectedValueWaiter = null;
      selectedValueUser = null;
      tableId = null;
      waiterId = null;
      userId = null;
    });
    context.read<OrderTodayBloc>().add(
      OrderTodayList(todayDate, todayDate, "", "", ""),
    );
    context.read<OrderTodayBloc>().add(StockDetails());
    context.read<OrderTodayBloc>().add(TableDine());
    context.read<OrderTodayBloc>().add(WaiterDine());
    context.read<OrderTodayBloc>().add(UserDetails());
  }

  void _refreshData() {
    setState(() {
      selectedValue = null;
      selectedValueWaiter = null;
      selectedValueUser = null;
      tableId = null;
      waiterId = null;
      userId = null;
    });
    context.read<OrderTodayBloc>().add(TableDine());
    context.read<OrderTodayBloc>().add(WaiterDine());
    context.read<OrderTodayBloc>().add(UserDetails());
    _loadOrdersForCurrentTab();
  }

  void _loadOrdersForCurrentTab() {
    setState(() {
      orderLoad = true;
    });
    context.read<OrderTodayBloc>().add(
      OrderTodayList(
        todayDate,
        todayDate,
        tableId ?? "",
        waiterId ?? "",
        userId ?? "",
      ),
    );
  }

  // Build order grid widget
  Widget _buildOrderGrid(List<dynamic> orders) {
    String tabName = _tabNames[_currentTabIndex];
    if (orderLoad) {
      return Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.1),
        alignment: Alignment.center,
        child: const SpinKitChasingDots(color: appPrimaryColor, size: 30),
      );
    }

    if (orders.isEmpty) {
      return Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.1),
        alignment: Alignment.center,
        child: Text(
          tabName == "All"
              ? "No Orders Today !!!"
              : "No $tabName Orders Today !!!",
          style: MyTextStyle.f16(greyColor, weight: FontWeight.w500),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        itemCount: orders.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width < 632
              ? 1
              : MediaQuery.of(context).size.width >= 632 &&
                    MediaQuery.of(context).size.width < 830
              ? 2
              : 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio:
              MediaQuery.of(context).size.width > 500 &&
                  MediaQuery.of(context).size.width < 632
              ? 3
              : MediaQuery.of(context).size.width >= 632 &&
                    MediaQuery.of(context).size.width < 776
              ? 2
              : MediaQuery.of(context).size.width >= 776 &&
                    MediaQuery.of(context).size.width < 830
              ? 2.5
              : MediaQuery.of(context).size.width >= 830 &&
                    MediaQuery.of(context).size.width < 895
              ? 1.5
              : 1.8,
        ),
        itemBuilder: (context, index) {
          final order = orders[index];
          final payment = order.payments?.isNotEmpty == true
              ? order.payments!.first
              : null;
          debugPrint("sizeWidthOrder:${MediaQuery.of(context).size.width}");
          debugPrint("sizeHeightOrder:${MediaQuery.of(context).size.height}");
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order ID & Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          "Order ID: ${order.orderNumber ?? '--'}",
                          style: MyTextStyle.f14(
                            appPrimaryColor,
                            weight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        "₹${order.total?.toStringAsFixed(2) ?? '0.00'}",
                        style: MyTextStyle.f14(
                          appPrimaryColor,
                          weight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Time: ${formatTime(order.invoice?.date)}"),
                      Text(
                        payment?.paymentMethod != null &&
                                payment!.paymentMethod!.isNotEmpty
                            ? "Payment: ${payment.paymentMethod}: ₹${payment.amount?.toStringAsFixed(2) ?? '0.00'}"
                            : "Payment: N/A",
                        style: MyTextStyle.f12(greyColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Type: ${order.orderType ?? '--'}"),
                      Text(
                        "Status: ${order.orderStatus}",
                        style: TextStyle(
                          color: order.orderStatus == 'COMPLETED'
                              ? greenColor
                              : orangeColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text("Table: ${order.tableName ?? 'N/A'}"),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            icon: Icon(
                              Icons.remove_red_eye,
                              color: appPrimaryColor,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                view = true;
                              });
                              context.read<OrderTodayBloc>().add(
                                ViewOrder(order.id),
                              );
                            },
                          ),
                          if (MediaQuery.of(context).size.width >= 500)
                            SizedBox(width: 8),
                          if ((operatorId == userId ||
                                  userId == null ||
                                  userId == "") &&
                              order.orderStatus != 'COMPLETED')
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              icon: Icon(
                                Icons.edit,
                                color: appPrimaryColor,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  view = false;
                                });
                                context.read<OrderTodayBloc>().add(
                                  ViewOrder(order.id),
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    Widget mainContainer() {
      return RefreshIndicator(
        displacement: 60.0,
        color: appPrimaryColor,
        onRefresh: () async {
          setState(() {
            if (getOrderListTodayModel.data == null ||
                getOrderListTodayModel.data!.isEmpty) {
              orderLoad = true;
            }
          });
          _loadOrdersForCurrentTab();
        },
        child: ResponsiveBuilder(
          mobileBuilder: (context, constraints) {
            return DefaultTabController(
              length: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Orders",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: appPrimaryColor,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _refreshData();
                          },
                          icon: const Icon(
                            Icons.refresh,
                            color: appPrimaryColor,
                            size: 28,
                          ),
                          tooltip: 'Refresh Orders',
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Select Table',
                            style: MyTextStyle.f14(
                              blackColor,
                              weight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Select Waiter',
                            style: MyTextStyle.f14(
                              blackColor,
                              weight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Expanded(
                      //   child: Padding(
                      //     padding: const EdgeInsets.all(8.0),
                      //     child: Text(
                      //       'Select Operator',
                      //       style: MyTextStyle.f14(
                      //         blackColor,
                      //         weight: FontWeight.bold,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                  Row(
                    children: [
                      // Table Dropdown
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          child: DropdownButtonFormField<String>(
                            value:
                                (getTableModel.data?.any(
                                      (item) => item.name == selectedValue,
                                    ) ??
                                    false)
                                ? selectedValue
                                : null,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: appPrimaryColor,
                            ),
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: appPrimaryColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: appGreyColor,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: appPrimaryColor,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: getTableModel.data?.map((item) {
                              return DropdownMenuItem<String>(
                                value: item.name,
                                child: Text(
                                  "Table ${item.name}",
                                  style: MyTextStyle.f14(
                                    blackColor,
                                    weight: FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedValue = newValue;
                                  final selectedItem = getTableModel.data
                                      ?.firstWhere(
                                        (item) => item.name == newValue,
                                      );
                                  tableId = selectedItem?.id.toString();
                                });
                                _loadOrdersForCurrentTab();
                              }
                            },
                            hint: Text(
                              '-- Select Table --',
                              style: MyTextStyle.f14(
                                blackColor,
                                weight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Waiter Dropdown
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          child: DropdownButtonFormField<String>(
                            value:
                                (getWaiterModel.data?.any(
                                      (item) =>
                                          item.name == selectedValueWaiter,
                                    ) ??
                                    false)
                                ? selectedValueWaiter
                                : null,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: appPrimaryColor,
                            ),
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: appPrimaryColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: appGreyColor,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: appPrimaryColor,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: getWaiterModel.data?.map((item) {
                              return DropdownMenuItem<String>(
                                value: item.name,
                                child: Text(
                                  "${item.name}",
                                  style: MyTextStyle.f14(
                                    blackColor,
                                    weight: FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedValueWaiter = newValue;
                                  final selectedItem = getWaiterModel.data
                                      ?.firstWhere(
                                        (item) => item.name == newValue,
                                      );
                                  waiterId = selectedItem?.id.toString();
                                  // userId = selectedItem?.user?.id.toString();
                                  // debugPrint("userId:$userId");
                                });
                                _loadOrdersForCurrentTab();
                              }
                            },
                            hint: Text(
                              '-- Select Waiter --',
                              style: MyTextStyle.f14(
                                blackColor,
                                weight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // User Dropdown
                      // Expanded(
                      //   child: Container(
                      //     margin: const EdgeInsets.all(8),
                      //     child: DropdownButtonFormField<String>(
                      //       value:
                      //           (getUserModel.data?.any(
                      //                 (item) => item.name == selectedValueUser,
                      //               ) ??
                      //               false)
                      //           ? selectedValueUser
                      //           : null,
                      //       icon: const Icon(
                      //         Icons.arrow_drop_down,
                      //         color: appPrimaryColor,
                      //       ),
                      //       isExpanded: true,
                      //       decoration: InputDecoration(
                      //         border: OutlineInputBorder(
                      //           borderRadius: BorderRadius.circular(8),
                      //           borderSide: const BorderSide(
                      //             color: appPrimaryColor,
                      //           ),
                      //         ),
                      //         enabledBorder: OutlineInputBorder(
                      //           borderSide: BorderSide(
                      //             color: appGreyColor,
                      //             width: 1.5,
                      //           ),
                      //           borderRadius: BorderRadius.circular(8),
                      //         ),
                      //         focusedBorder: OutlineInputBorder(
                      //           borderSide: BorderSide(
                      //             color: appPrimaryColor,
                      //             width: 1.5,
                      //           ),
                      //           borderRadius: BorderRadius.circular(8),
                      //         ),
                      //       ),
                      //       items: getUserModel.data?.map((item) {
                      //         return DropdownMenuItem<String>(
                      //           value: item.name,
                      //           child: Text(
                      //             "${item.name}",
                      //             style: MyTextStyle.f14(
                      //               blackColor,
                      //               weight: FontWeight.normal,
                      //             ),
                      //           ),
                      //         );
                      //       }).toList(),
                      //       onChanged: (String? newValue) {
                      //         if (newValue != null) {
                      //           setState(() {
                      //             selectedValueUser = newValue;
                      //             final selectedItem = getUserModel.data
                      //                 ?.firstWhere(
                      //                   (item) => item.name == newValue,
                      //                 );
                      //             userId = selectedItem?.id.toString();
                      //             debugPrint("operatorSelectr:$userId");
                      //           });
                      //
                      //           _loadOrdersForCurrentTab();
                      //         }
                      //       },
                      //       hint: Text(
                      //         '-- Select Operator --',
                      //         style: MyTextStyle.f14(
                      //           blackColor,
                      //           weight: FontWeight.normal,
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                  TabBar(
                    controller: _tabController,
                    //isScrollable: true,
                    //tabAlignment: TabAlignment.center,
                    labelColor: appPrimaryColor,
                    unselectedLabelColor: greyColor,
                    indicatorColor: appPrimaryColor,
                    tabs: const [
                      Tab(text: "All"),
                      Tab(text: "Line"),
                      // Tab(text: "Parcel"),
                      Tab(text: "AC"),
                      // Tab(text: "HD"),
                      // Tab(text: "SWIGGY"),
                    ],
                  ),
                  // Updated TabBarView
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: List.generate(3, (index) {
                        // Get filtered orders for each tab
                        List<dynamic> filteredOrders;
                        if (index == 0) {
                          // All tab
                          filteredOrders = getOrderListTodayModel.data ?? [];
                        } else {
                          // Filter by specific tab
                          String tabName = _tabNames[index];
                          filteredOrders =
                              getOrderListTodayModel.data?.where((order) {
                                String? orderType = order.orderType
                                    ?.toString()
                                    .toUpperCase();
                                return orderType == tabName.toUpperCase();
                              }).toList() ??
                              [];
                        }

                        return _buildOrderGrid(filteredOrders);
                      }),
                    ),
                  ),
                ],
              ),
            );
          },
          tabletBuilder: (context, constraints) {
            return DefaultTabController(
              length: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Orders",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: appPrimaryColor,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _refreshData();
                          },
                          icon: const Icon(
                            Icons.refresh,
                            color: appPrimaryColor,
                            size: 28,
                          ),
                          tooltip: 'Refresh Orders',
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Select Table',
                            style: MyTextStyle.f14(
                              blackColor,
                              weight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Select Waiter',
                            style: MyTextStyle.f14(
                              blackColor,
                              weight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Expanded(
                      //   child: Padding(
                      //     padding: const EdgeInsets.all(8.0),
                      //     child: Text(
                      //       'Select Operator',
                      //       style: MyTextStyle.f14(
                      //         blackColor,
                      //         weight: FontWeight.bold,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                  Row(
                    children: [
                      // Table Dropdown
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          child: DropdownButtonFormField<String>(
                            value:
                                (getTableModel.data?.any(
                                      (item) => item.name == selectedValue,
                                    ) ??
                                    false)
                                ? selectedValue
                                : null,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: appPrimaryColor,
                            ),
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: appPrimaryColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: appGreyColor,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: appPrimaryColor,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: getTableModel.data?.map((item) {
                              return DropdownMenuItem<String>(
                                value: item.name,
                                child: Text(
                                  "Table ${item.name}",
                                  style: MyTextStyle.f14(
                                    blackColor,
                                    weight: FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedValue = newValue;
                                  final selectedItem = getTableModel.data
                                      ?.firstWhere(
                                        (item) => item.name == newValue,
                                      );
                                  tableId = selectedItem?.id.toString();
                                });
                                _loadOrdersForCurrentTab();
                              }
                            },
                            hint: Text(
                              '-- Select Table --',
                              style: MyTextStyle.f14(
                                blackColor,
                                weight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Waiter Dropdown
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          child: DropdownButtonFormField<String>(
                            value:
                                (getWaiterModel.data?.any(
                                      (item) =>
                                          item.name == selectedValueWaiter,
                                    ) ??
                                    false)
                                ? selectedValueWaiter
                                : null,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: appPrimaryColor,
                            ),
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: appPrimaryColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: appGreyColor,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: appPrimaryColor,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: getWaiterModel.data?.map((item) {
                              return DropdownMenuItem<String>(
                                value: item.name,
                                child: Text(
                                  "${item.name}",
                                  style: MyTextStyle.f14(
                                    blackColor,
                                    weight: FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedValueWaiter = newValue;
                                  final selectedItem = getWaiterModel.data
                                      ?.firstWhere(
                                        (item) => item.name == newValue,
                                      );
                                  waiterId = selectedItem?.id.toString();
                                  debugPrint("waiterId:$waiterId");
                                });

                                _loadOrdersForCurrentTab();
                              }
                            },
                            hint: Text(
                              '-- Select Waiter --',
                              style: MyTextStyle.f14(
                                blackColor,
                                weight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // User Dropdown
                      // Expanded(
                      //   child: Container(
                      //     margin: const EdgeInsets.all(8),
                      //     child: DropdownButtonFormField<String>(
                      //       value:
                      //           (getUserModel.data?.any(
                      //                 (item) => item.name == selectedValueUser,
                      //               ) ??
                      //               false)
                      //           ? selectedValueUser
                      //           : null,
                      //       icon: const Icon(
                      //         Icons.arrow_drop_down,
                      //         color: appPrimaryColor,
                      //       ),
                      //       isExpanded: true,
                      //       decoration: InputDecoration(
                      //         border: OutlineInputBorder(
                      //           borderRadius: BorderRadius.circular(8),
                      //           borderSide: const BorderSide(
                      //             color: appPrimaryColor,
                      //           ),
                      //         ),
                      //         enabledBorder: OutlineInputBorder(
                      //           borderSide: BorderSide(
                      //             color: appGreyColor,
                      //             width: 1.5,
                      //           ),
                      //           borderRadius: BorderRadius.circular(8),
                      //         ),
                      //         focusedBorder: OutlineInputBorder(
                      //           borderSide: BorderSide(
                      //             color: appPrimaryColor,
                      //             width: 1.5,
                      //           ),
                      //           borderRadius: BorderRadius.circular(8),
                      //         ),
                      //       ),
                      //       items: getUserModel.data?.map((item) {
                      //         return DropdownMenuItem<String>(
                      //           value: item.name,
                      //           child: Text(
                      //             "${item.name}",
                      //             style: MyTextStyle.f14(
                      //               blackColor,
                      //               weight: FontWeight.normal,
                      //             ),
                      //           ),
                      //         );
                      //       }).toList(),
                      //       onChanged: (String? newValue) {
                      //         if (newValue != null) {
                      //           setState(() {
                      //             selectedValueUser = newValue;
                      //             final selectedItem = getUserModel.data
                      //                 ?.firstWhere(
                      //                   (item) => item.name == newValue,
                      //                 );
                      //             userId = selectedItem?.id.toString();
                      //             debugPrint("userId:$userId");
                      //           });
                      //
                      //           _loadOrdersForCurrentTab();
                      //         }
                      //       },
                      //       hint: Text(
                      //         '-- Select Operator --',
                      //         style: MyTextStyle.f14(
                      //           blackColor,
                      //           weight: FontWeight.normal,
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                  TabBar(
                    controller: _tabController,
                    // isScrollable: true,
                    // tabAlignment: TabAlignment.start,
                    labelColor: appPrimaryColor,
                    unselectedLabelColor: greyColor,
                    indicatorColor: appPrimaryColor,
                    tabs: const [
                      Tab(text: "All"),
                      Tab(text: "Line"),
                      //  Tab(text: "Parcel"),
                      Tab(text: "AC"),
                      // Tab(text: "HD"),
                      // Tab(text: "SWIGGY"),
                    ],
                  ),
                  // Updated TabBarView
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: List.generate(3, (index) {
                        // Get filtered orders for each tab
                        List<dynamic> filteredOrders;
                        if (index == 0) {
                          // All tab
                          filteredOrders = getOrderListTodayModel.data ?? [];
                        } else {
                          // Filter by specific tab
                          String tabName = _tabNames[index];
                          filteredOrders =
                              getOrderListTodayModel.data?.where((order) {
                                String? orderType = order.orderType
                                    ?.toString()
                                    .toUpperCase();
                                return orderType == tabName.toUpperCase();
                              }).toList() ??
                              [];
                        }

                        return _buildOrderGrid(filteredOrders);
                      }),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: whiteColor,
      appBar: PreferredSize(
        preferredSize: size.width < 650
            ? const Size.fromHeight(60)
            : const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: whiteColor,
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            width: double.infinity,
            color: whiteColor,
            padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                getStockMaintanencesModel.data?.name != null
                    ? Expanded(
                        child: Text(
                          getStockMaintanencesModel.data!.name.toString(),
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
                      )
                    : Text(""),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.logout,
                        size: size.width < 650 ? 25 : 35,
                        color: appPrimaryColor,
                      ),
                      onPressed: () {
                        showLogoutDialog(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: BlocBuilder<OrderTodayBloc, dynamic>(
        buildWhen: ((previous, current) {
          if (current is GetStockMaintanencesModel) {
            getStockMaintanencesModel = current;
            if (getStockMaintanencesModel.errorResponse?.isUnauthorized ==
                true) {
              _handle401Error();
              return true;
            }
            if (getStockMaintanencesModel.success == true) {
              setState(() {
                tableLoad = false;
              });
            } else {
              setState(() {
                tableLoad = false;
              });
              showToast("No Stock found", context, color: false);
            }
            return true;
          }
          if (current is GetOrderListTodayModel) {
            getOrderListTodayModel = current;
            if (getOrderListTodayModel.errorResponse?.isUnauthorized == true) {
              _handle401Error();
              return true;
            }
            setState(() {
              orderLoad = false;
            });
            return true;
          }
          if (current is GetTableModel) {
            getTableModel = current;
            if (getTableModel.errorResponse?.isUnauthorized == true) {
              _handle401Error();
              return true;
            }
            if (getTableModel.success == true) {
              setState(() {
                tableLoad = false;
              });
            } else {
              setState(() {
                tableLoad = false;
              });
              showToast("No Tables found", context, color: false);
            }
            return true;
          }
          if (current is GetWaiterModel) {
            getWaiterModel = current;
            if (getWaiterModel.errorResponse?.isUnauthorized == true) {
              _handle401Error();
              return true;
            }
            if (getWaiterModel.success == true) {
              setState(() {
                tableLoad = false;
              });
            } else {
              setState(() {
                tableLoad = false;
              });
              showToast("No Waiter found", context, color: false);
            }
            return true;
          }
          if (current is GetUserModel) {
            getUserModel = current;
            if (getUserModel.errorResponse?.isUnauthorized == true) {
              _handle401Error();
              return true;
            }
            if (getUserModel.success == true) {
              setState(() {
                tableLoad = false;
              });
            } else {
              setState(() {
                tableLoad = false;
              });
              showToast("No Operator found", context, color: false);
            }
            return true;
          }
          if (current is GetViewOrderModel) {
            try {
              getViewOrderModel = current;
              if (getViewOrderModel.errorResponse?.isUnauthorized == true) {
                _handle401Error();
                return true;
              }
              if (getViewOrderModel.success == true) {
                if (view == true) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return const Center(child: CircularProgressIndicator());
                    },
                  );
                  Future.delayed(Duration(seconds: 1));

                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (context) =>
                        ThermalReceiptDialog(getViewOrderModel),
                  );
                } else {
                  Navigator.of(context)
                      .pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => DashboardScreen(
                            selectTab: 0,
                            existingOrder: getViewOrderModel,
                            isEditingOrder: true,
                          ),
                        ),
                        (Route<dynamic> route) => false,
                      )
                      .then((value) {
                        if (value == true) {
                          context.read<OrderTodayBloc>().add(
                            OrderTodayList(todayDate, todayDate, "", "", ""),
                          );
                        }
                      });
                }
              }
            } catch (e, stackTrace) {
              debugPrint("Error in processing view order: $e");
              print(stackTrace);
              if (e is DioException) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Something went wrong: ${e.toString()}"),
                  ),
                );
              }
            }
            return true;
          }
          return false;
        }),
        builder: (context, dynamic) {
          return mainContainer();
        },
      ),
    );
  }

  void _handle401Error() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.remove("token");
    await sharedPreferences.clear();
    showToast("Session expired. Please login again.", context, color: false);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }
}
