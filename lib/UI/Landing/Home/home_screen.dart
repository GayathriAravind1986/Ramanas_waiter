import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ramanas_waiter/Alertbox/AlertDialogBox.dart';
import 'package:ramanas_waiter/Alertbox/snackBarAlert.dart';
import 'package:ramanas_waiter/Bloc/Category/category_bloc.dart';
import 'package:collection/collection.dart';
import 'package:ramanas_waiter/ModelClass/Cart/Post_Add_to_billing_model.dart';
import 'package:ramanas_waiter/ModelClass/HomeScreen/Category&Product/Get_category_model.dart';
import 'package:ramanas_waiter/ModelClass/HomeScreen/Category&Product/Get_product_by_catId_model.dart';
import 'package:ramanas_waiter/ModelClass/Order/Get_view_order_model.dart';
import 'package:ramanas_waiter/ModelClass/ShopDetails/getStockMaintanencesModel.dart';
import 'package:ramanas_waiter/ModelClass/Table/Get_table_model.dart';
import 'package:ramanas_waiter/ModelClass/Waiter/getWaiterModel.dart';
import 'package:ramanas_waiter/Reusable/color.dart';
import 'package:ramanas_waiter/Reusable/image.dart';
import 'package:ramanas_waiter/Reusable/responsive.dart';
import 'package:ramanas_waiter/Reusable/space.dart';
import 'package:ramanas_waiter/Reusable/text_styles.dart';
import 'package:ramanas_waiter/UI/Authentication/login_screen.dart';
import 'package:ramanas_waiter/UI/Cart/Widget/payment_option.dart';
import 'package:ramanas_waiter/UI/Landing/Home/Helper/order_helper.dart';
import 'package:ramanas_waiter/UI/Landing/Home/Widget/category_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatelessWidget {
  final from;
  final GetViewOrderModel? existingOrder;
  bool? isEditingOrder;
  HomePage({super.key, this.from, this.existingOrder, this.isEditingOrder});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FoodCategoryBloc(),
      child: HomePageView(
        from: from,
        existingOrder: existingOrder,
        isEditingOrder: isEditingOrder,
      ),
    );
  }
}

class HomePageView extends StatefulWidget {
  final from;
  final GetViewOrderModel? existingOrder;
  bool? isEditingOrder;
  HomePageView({super.key, this.from, this.existingOrder, this.isEditingOrder});

  @override
  HomePageViewState createState() => HomePageViewState();
}

enum OrderType { line, parcel, ac, hd, swiggy }

extension OrderTypeX on OrderType {
  String get apiValue {
    switch (this) {
      case OrderType.line:
        return "LINE";
      case OrderType.parcel:
        return "PARCEL";
      case OrderType.ac:
        return "AC";
      case OrderType.hd:
        return "HD";
      case OrderType.swiggy:
        return "SWIGGY";
    }
  }

  // 👇 to convert back from API string
  static OrderType fromApi(String value) {
    switch (value) {
      case "LINE":
        return OrderType.line;
      case "PARCEL":
        return OrderType.parcel;
      case "AC":
        return OrderType.ac;
      case "HD":
        return OrderType.hd;
      case "SWIGGY":
        return OrderType.swiggy;
      default:
        return OrderType.line;
    }
  }
}

class HomePageViewState extends State<HomePageView> {
  GetCategoryModel getCategoryModel = GetCategoryModel();
  GetProductByCatIdModel getProductByCatIdModel = GetProductByCatIdModel();
  PostAddToBillingModel postAddToBillingModel = PostAddToBillingModel();
  GetStockMaintanencesModel getStockMaintanencesModel =
      GetStockMaintanencesModel();
  GetTableModel getTableModel = GetTableModel();
  GetWaiterModel getWaiterModel = GetWaiterModel();

  TextEditingController searchController = TextEditingController();
  TextEditingController searchCodeController = TextEditingController();
  Map<String, TextEditingController> quantityControllers = {};

  List<TextEditingController> splitAmountControllers = [];
  List<String?> selectedPaymentMethods = [];
  double totalSplit = 0.0;

  String selectedCategory = "All";
  String? selectedCatId = "";

  String? errorMessage;
  bool categoryLoad = false;

  int counter = 0;
  OrderType? selectedOrderType = OrderType.line;
  bool isSplitPayment = false;
  bool splitChange = false;
  bool isCompleteOrder = false;
  int _paymentFieldCount = 1;
  double balance = 0;
  bool allSplitAmountsFilled() {
    return splitAmountControllers.every(
      (controller) => controller.text.trim().isNotEmpty,
    );
  }

  bool allPaymentMethodsSelected() {
    return selectedPaymentMethods.every(
      (method) => method != null && method.isNotEmpty,
    );
  }

  void addPaymentField() {
    if (_paymentFieldCount < 3) {
      setState(() {
        _paymentFieldCount++;
        splitAmountControllers.add(TextEditingController());
        selectedPaymentMethods.add(null);
      });
    }
  }

  dynamic selectedValue;
  dynamic selectedValueWaiter;
  dynamic tableId;
  dynamic waiterId;

  bool showTipField = false;
  final TextEditingController tipController = TextEditingController();
  double tipAmount = 0.0;
  void toggleTipField() {
    setState(() {
      showTipField = !showTipField;
      if (!showTipField) {
        tipAmount = 0.0;
        tipController.clear();
      }
    });
  }

  void updateTip(String value) {
    setState(() {
      tipAmount = double.tryParse(value) ?? 0.0;
    });
  }

  bool orderLoad = false;
  bool completeLoad = false;
  bool cartLoad = false;
  bool isToppingSelected = false;

  String selectedFullPaymentMethod = "";
  double totalAmount = 0.0;
  double paidAmount = 0.0;
  double balanceAmount = 0.0;
  bool isCartLoaded = false;
  bool isDiscountApplied = false;
  List<Map<String, dynamic>> billingItems = [];

  void loadExistingOrder(GetViewOrderModel? order) {
    if (order == null || order.data == null) return;
    debugPrint("existOrderId:${widget.existingOrder?.data?.id}");
    final data = order.data!;

    setState(() {
      switch (data.orderType) {
        case 'LINE':
          selectedOrderType = OrderType.line;
          break;
        case 'PARCEL':
          selectedOrderType = OrderType.parcel;
          break;
        case 'AC':
          selectedOrderType = OrderType.ac;
          break;
        case 'HD':
          selectedOrderType = OrderType.hd;
          break;
        case 'SWIGGY':
          selectedOrderType = OrderType.swiggy;
          break;
        default:
          selectedOrderType = OrderType.line;
      }
      tableId = data.tableNo;
      waiterId = data.waiter;
      selectedValue = data.tableName;
      selectedValueWaiter = data.waiterName;
      isCartLoaded = true;
      isDiscountApplied =
          widget.existingOrder?.data!.isDiscountApplied ?? false;
      billingItems =
          data.items?.map((e) {
            final product = e.product;
            return {
              "_id": product?.id,
              "name": e.name,
              "basePrice": (product?.basePrice ?? 0),
              "qty": e.quantity,
              "image": product?.image,
              "selectedAddons":
                  e.addons?.map((addonItem) {
                    final addon = addonItem.addon;
                    return {
                      "_id": addon?.id,
                      "name": addon?.name,
                      "price": addon?.price,
                      "isFree": addon?.isFree,
                      "quantity": addonItem.quantity ?? 1,
                      "isAvailable": addon?.isAvailable,
                      "maxQuantity": addon?.maxQuantity,
                    };
                  }).toList() ??
                  [],
            };
          }).toList() ??
          [];
      context.read<FoodCategoryBloc>().add(
        AddToBilling(
          List.from(billingItems),
          widget.existingOrder?.data!.isDiscountApplied,
          OrderTypeX.fromApi(widget.existingOrder?.data!.orderType ?? "LINE"),
        ),
      );
    });
  }

  void resetCartState() {
    setState(() {
      billingItems.clear();
      tableId = null;
      waiterId = null;
      selectedValue = null;
      selectedValueWaiter = null;
      selectedOrderType = OrderType.line;
      isSplitPayment = false;
      selectedFullPaymentMethod = "";
      // widget.isEditingOrder = false;
      balance = 0;
      if (billingItems.isEmpty || billingItems == []) {
        isDiscountApplied = false;
      }
      context.read<FoodCategoryBloc>().add(
        AddToBilling([], isDiscountApplied, selectedOrderType),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    context.read<FoodCategoryBloc>().add(FoodCategory());
    context.read<FoodCategoryBloc>().add(
      FoodProductItem(
        selectedCatId.toString(),
        searchController.text,
        searchCodeController.text,
      ),
    );
    context.read<FoodCategoryBloc>().add(TableDine());
    context.read<FoodCategoryBloc>().add(WaiterDine());
    context.read<FoodCategoryBloc>().add(StockDetails());
    setState(() {
      categoryLoad = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isEditingOrder == true && widget.existingOrder != null) {
        loadExistingOrder(widget.existingOrder!);
      } else {
        resetCartState();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in quantityControllers.values) {
      controller.dispose();
    }
    quantityControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    Widget mainContainer() {
      final sortedCategories = (getCategoryModel.data ?? [])
          .map(
            (data) => Category(id: data.id, name: data.name, image: data.image),
          )
          .toList();

      final List<Category> displayedCategories = [
        Category(name: 'All', image: Images.all, id: ""),
        ...sortedCategories,
      ];

      double total = (postAddToBillingModel.total ?? 0).toDouble();
      double paidAmount = (widget.existingOrder?.data?.total ?? 0).toDouble();
      balance = total - paidAmount;

      TextEditingController getOrCreateController(String itemId, int quantity) {
        if (!quantityControllers.containsKey(itemId)) {
          quantityControllers[itemId] = TextEditingController(
            text: quantity.toString(),
          );
        }
        return quantityControllers[itemId]!;
      }

      void updateControllerText(String itemId, int quantity) {
        if (quantityControllers.containsKey(itemId)) {
          quantityControllers[itemId]!.text = quantity.toString();
        }
      }

      int getCurrentQuantity(String itemId) {
        final item = billingItems.firstWhereOrNull(
          (item) => item['_id'].toString() == itemId,
        );
        return item?['qty'] ?? 0;
      }

      @override
      Widget price(String label, String value, {bool isBold = false}) {
        return SizedBox(
          height: 20,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: isBold
                      ? MyTextStyle.f12(blackColor, weight: FontWeight.bold)
                      : MyTextStyle.f12(greyColor),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  style: isBold
                      ? MyTextStyle.f12(blackColor, weight: FontWeight.bold)
                      : MyTextStyle.f12(blackColor),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        displacement: 60.0,
        color: appPrimaryColor,
        onRefresh: () async {
          searchController.clear();
          searchCodeController.clear();
          context.read<FoodCategoryBloc>().add(FoodCategory());
          context.read<FoodCategoryBloc>().add(
            FoodProductItem(
              selectedCatId.toString(),
              searchController.text,
              searchCodeController.text,
            ),
          );
          categoryLoad = true;
          setState(() {});
        },
        child: ResponsiveBuilder(
          mobileBuilder: (context, constraints) {
            return DefaultTabController(
              length: 2,
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 15,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TabBar(
                      indicatorColor: appPrimaryColor,
                      labelColor: appPrimaryColor,
                      unselectedLabelColor: greyColor,
                      tabs: [
                        Tab(text: "Home"),
                        Tab(text: "Cart"),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          /// category screen
                          categoryLoad
                              ? Container(
                                  padding: EdgeInsets.only(
                                    top:
                                        MediaQuery.of(context).size.height *
                                        0.15,
                                  ),
                                  alignment: Alignment.center,
                                  child: const SpinKitChasingDots(
                                    color: appPrimaryColor,
                                    size: 30,
                                  ),
                                )
                              : Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: SizedBox(
                                                width: size.width * 0.5,
                                                child: TextField(
                                                  controller: searchController,
                                                  decoration: InputDecoration(
                                                    hintText: 'Search product',
                                                    prefixIcon: Icon(
                                                      Icons.search,
                                                    ),
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            30,
                                                          ),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                            color: appGreyColor,
                                                            width: 1.5,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                30,
                                                              ),
                                                        ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                            color:
                                                                appPrimaryColor,
                                                            width: 1.5,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                30,
                                                              ),
                                                        ),
                                                  ),
                                                  onChanged: (value) {
                                                    searchController
                                                      ..text = (value)
                                                      ..selection =
                                                          TextSelection.collapsed(
                                                            offset:
                                                                searchController
                                                                    .text
                                                                    .length,
                                                          );
                                                    setState(() {
                                                      context
                                                          .read<
                                                            FoodCategoryBloc
                                                          >()
                                                          .add(
                                                            FoodProductItem(
                                                              selectedCatId
                                                                  .toString(),
                                                              searchController
                                                                  .text,
                                                              searchCodeController
                                                                  .text,
                                                            ),
                                                          );
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                            horizontalSpace(width: 10),
                                            Expanded(
                                              child: SizedBox(
                                                width: size.width * 0.5,
                                                child: TextField(
                                                  controller:
                                                      searchCodeController,
                                                  decoration: InputDecoration(
                                                    hintText: 'Search code',
                                                    prefixIcon: Icon(
                                                      Icons.search,
                                                    ),
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            30,
                                                          ),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                            color: appGreyColor,
                                                            width: 1.5,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                30,
                                                              ),
                                                        ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                            color:
                                                                appPrimaryColor,
                                                            width: 1.5,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                30,
                                                              ),
                                                        ),
                                                  ),
                                                  onChanged: (value) {
                                                    searchCodeController
                                                      ..text = (value)
                                                      ..selection =
                                                          TextSelection.collapsed(
                                                            offset:
                                                                searchCodeController
                                                                    .text
                                                                    .length,
                                                          );
                                                    setState(() {
                                                      context
                                                          .read<
                                                            FoodCategoryBloc
                                                          >()
                                                          .add(
                                                            FoodProductItem(
                                                              selectedCatId
                                                                  .toString(),
                                                              searchController
                                                                  .text,
                                                              searchCodeController
                                                                  .text,
                                                            ),
                                                          );
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        verticalSpace(
                                          height: size.height * 0.02,
                                        ),

                                        Text(
                                          "Choose Category",
                                          style: MyTextStyle.f18(
                                            blackColor,
                                            weight: FontWeight.bold,
                                          ),
                                        ),
                                        verticalSpace(
                                          height: size.height * 0.02,
                                        ),

                                        /// Category - list
                                        displayedCategories.isEmpty
                                            ? Container()
                                            : SizedBox(
                                                height: size.height * 0.14,
                                                width: size.width * 0.9,
                                                child: ListView.separated(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount: displayedCategories
                                                      .length,
                                                  separatorBuilder: (_, _) =>
                                                      SizedBox(width: 12),
                                                  itemBuilder: (context, index) {
                                                    final category =
                                                        displayedCategories[index];
                                                    final isSelected =
                                                        category.name ==
                                                        selectedCategory;
                                                    return CategoryCard(
                                                      label: category.name!,
                                                      imagePath:
                                                          category.image ?? "",
                                                      isSelected: isSelected,
                                                      onTap: () {
                                                        setState(() {
                                                          selectedCategory =
                                                              category.name!;
                                                          selectedCatId =
                                                              category.id;
                                                          if (selectedCategory ==
                                                              'All') {
                                                            context.read<FoodCategoryBloc>().add(
                                                              FoodProductItem(
                                                                selectedCatId
                                                                    .toString(),
                                                                searchController
                                                                    .text,
                                                                searchCodeController
                                                                    .text,
                                                              ),
                                                            );
                                                          } else {
                                                            context.read<FoodCategoryBloc>().add(
                                                              FoodProductItem(
                                                                selectedCatId
                                                                    .toString(),
                                                                searchController
                                                                    .text,
                                                                searchCodeController
                                                                    .text,
                                                              ),
                                                            );
                                                          }
                                                        });
                                                      },
                                                    );
                                                  },
                                                ),
                                              ),

                                        /// Product - list
                                        SizedBox(
                                          height: size.height * 0.4,
                                          width: size.width * 1.8,
                                          child:
                                              getProductByCatIdModel.rows ==
                                                      null ||
                                                  getProductByCatIdModel.rows ==
                                                      [] ||
                                                  getProductByCatIdModel
                                                      .rows!
                                                      .isEmpty
                                              ? Container()
                                              : GridView.builder(
                                                  padding: EdgeInsets.only(
                                                    top: 10,
                                                  ),
                                                  gridDelegate:
                                                      SliverGridDelegateWithFixedCrossAxisCount(
                                                        crossAxisCount:
                                                            MediaQuery.of(
                                                                  context,
                                                                ).size.width >
                                                                600
                                                            ? 3
                                                            : 2,
                                                        crossAxisSpacing: 8,
                                                        mainAxisSpacing: 8,
                                                        childAspectRatio: 0.6,
                                                      ),
                                                  itemCount:
                                                      getProductByCatIdModel
                                                          .rows!
                                                          .length,
                                                  itemBuilder: (_, index) {
                                                    int getCurrentQuantity(
                                                      String productId,
                                                    ) {
                                                      return billingItems
                                                              .firstWhere(
                                                                (item) =>
                                                                    item['_id'] ==
                                                                    productId,
                                                                orElse: () =>
                                                                    {},
                                                              )['qty'] ??
                                                          0;
                                                    }

                                                    TextEditingController
                                                    getQuantityController(
                                                      String productId,
                                                    ) {
                                                      if (!quantityControllers
                                                          .containsKey(
                                                            productId,
                                                          )) {
                                                        final currentQty =
                                                            getCurrentQuantity(
                                                              productId,
                                                            );
                                                        quantityControllers[productId] =
                                                            TextEditingController(
                                                              text: currentQty
                                                                  .toString(),
                                                            );
                                                      }
                                                      return quantityControllers[productId]!;
                                                    }

                                                    void updateControllerText(
                                                      String productId,
                                                      int quantity,
                                                    ) {
                                                      if (quantityControllers
                                                          .containsKey(
                                                            productId,
                                                          )) {
                                                        quantityControllers[productId]!
                                                            .text = quantity
                                                            .toString();
                                                      }
                                                    }

                                                    final p =
                                                        getProductByCatIdModel
                                                            .rows![index];
                                                    int currentQuantity =
                                                        getCurrentQuantity(
                                                          p.id.toString(),
                                                        );
                                                    TextEditingController
                                                    currentController =
                                                        getQuantityController(
                                                          p.id.toString(),
                                                        );
                                                    return InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          currentQuantity = 1;
                                                          if (p
                                                              .addons!
                                                              .isNotEmpty) {
                                                            showDialog(
                                                              context: context,
                                                              builder: (context2) {
                                                                return BlocProvider(
                                                                  create:
                                                                      (
                                                                        context,
                                                                      ) =>
                                                                          FoodCategoryBloc(),
                                                                  child: BlocProvider.value(
                                                                    value:
                                                                        BlocProvider.of<
                                                                          FoodCategoryBloc
                                                                        >(
                                                                          context,
                                                                          listen:
                                                                              false,
                                                                        ),
                                                                    child: StatefulBuilder(
                                                                      builder:
                                                                          (
                                                                            context,
                                                                            setState,
                                                                          ) {
                                                                            return Dialog(
                                                                              insetPadding: EdgeInsets.symmetric(
                                                                                horizontal: 40,
                                                                                vertical: 24,
                                                                              ),
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.circular(
                                                                                  8,
                                                                                ),
                                                                              ),
                                                                              child: Container(
                                                                                constraints: BoxConstraints(
                                                                                  maxWidth:
                                                                                      size.width *
                                                                                      0.4,
                                                                                  maxHeight:
                                                                                      size.height *
                                                                                      0.6,
                                                                                ),
                                                                                padding: EdgeInsets.all(
                                                                                  16,
                                                                                ),
                                                                                child: SingleChildScrollView(
                                                                                  child: Column(
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    mainAxisSize: MainAxisSize.min,
                                                                                    children: [
                                                                                      ClipRRect(
                                                                                        borderRadius: BorderRadius.circular(
                                                                                          15.0,
                                                                                        ),
                                                                                        child: CachedNetworkImage(
                                                                                          imageUrl: p.image!,
                                                                                          width:
                                                                                              size.width *
                                                                                              0.5,
                                                                                          height:
                                                                                              size.height *
                                                                                              0.2,
                                                                                          fit: BoxFit.cover,
                                                                                          errorWidget:
                                                                                              (
                                                                                                context,
                                                                                                url,
                                                                                                error,
                                                                                              ) {
                                                                                                return const Icon(
                                                                                                  Icons.error,
                                                                                                  size: 30,
                                                                                                  color: appHomeTextColor,
                                                                                                );
                                                                                              },
                                                                                          progressIndicatorBuilder:
                                                                                              (
                                                                                                context,
                                                                                                url,
                                                                                                downloadProgress,
                                                                                              ) => const SpinKitCircle(
                                                                                                color: appPrimaryColor,
                                                                                                size: 30,
                                                                                              ),
                                                                                        ),
                                                                                      ),
                                                                                      SizedBox(
                                                                                        height: 16,
                                                                                      ),
                                                                                      Text(
                                                                                        'Choose Add‑Ons for ${p.name}',
                                                                                        style: MyTextStyle.f16(
                                                                                          weight: FontWeight.bold,
                                                                                          blackColor,
                                                                                        ),
                                                                                        textAlign: TextAlign.left,
                                                                                      ),
                                                                                      SizedBox(
                                                                                        height: 12,
                                                                                      ),
                                                                                      Column(
                                                                                        children: p.addons!.map(
                                                                                          (
                                                                                            e,
                                                                                          ) {
                                                                                            return Padding(
                                                                                              padding: const EdgeInsets.symmetric(
                                                                                                vertical: 4.0,
                                                                                              ),
                                                                                              child: Container(
                                                                                                padding: const EdgeInsets.all(
                                                                                                  8,
                                                                                                ),
                                                                                                decoration: BoxDecoration(
                                                                                                  border: Border.all(
                                                                                                    color: blackColor,
                                                                                                  ),
                                                                                                  borderRadius: BorderRadius.circular(
                                                                                                    8,
                                                                                                  ),
                                                                                                ),
                                                                                                child: Row(
                                                                                                  children: [
                                                                                                    Expanded(
                                                                                                      child: Column(
                                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                        children: [
                                                                                                          Text(
                                                                                                            e.name ??
                                                                                                                '',
                                                                                                            style: const TextStyle(
                                                                                                              fontWeight: FontWeight.bold,
                                                                                                            ),
                                                                                                          ),
                                                                                                          const SizedBox(
                                                                                                            height: 4,
                                                                                                          ),
                                                                                                          Text(
                                                                                                            e.isFree ==
                                                                                                                    true
                                                                                                                ? "Free (Max: ${e.maxQuantity})"
                                                                                                                : "₹ ${e.price?.toStringAsFixed(2) ?? '0.00'} (Max: ${e.maxQuantity})",
                                                                                                            style: TextStyle(
                                                                                                              color: Colors.grey.shade600,
                                                                                                            ),
                                                                                                          ),
                                                                                                        ],
                                                                                                      ),
                                                                                                    ),
                                                                                                    Row(
                                                                                                      children: [
                                                                                                        IconButton(
                                                                                                          icon: const Icon(
                                                                                                            Icons.remove,
                                                                                                          ),
                                                                                                          onPressed:
                                                                                                              (e.quantity) >
                                                                                                                  0
                                                                                                              ? () {
                                                                                                                  setState(
                                                                                                                    () {
                                                                                                                      e.quantity =
                                                                                                                          (e.quantity) -
                                                                                                                          1;
                                                                                                                    },
                                                                                                                  );
                                                                                                                }
                                                                                                              : null,
                                                                                                        ),
                                                                                                        Text(
                                                                                                          '${e.quantity}',
                                                                                                        ),
                                                                                                        IconButton(
                                                                                                          icon: const Icon(
                                                                                                            Icons.add,
                                                                                                            color: Colors.brown,
                                                                                                          ),
                                                                                                          onPressed:
                                                                                                              (e.quantity) <
                                                                                                                  (e.maxQuantity ??
                                                                                                                      1)
                                                                                                              ? () {
                                                                                                                  setState(
                                                                                                                    () {
                                                                                                                      e.quantity =
                                                                                                                          (e.quantity) +
                                                                                                                          1;
                                                                                                                    },
                                                                                                                  );
                                                                                                                }
                                                                                                              : null,
                                                                                                        ),
                                                                                                      ],
                                                                                                    ),
                                                                                                  ],
                                                                                                ),
                                                                                              ),
                                                                                            );
                                                                                          },
                                                                                        ).toList(),
                                                                                      ),
                                                                                      SizedBox(
                                                                                        height: 20,
                                                                                      ),
                                                                                      Row(
                                                                                        mainAxisAlignment: MainAxisAlignment.end,
                                                                                        children: [
                                                                                          ElevatedButton(
                                                                                            onPressed: () {
                                                                                              setState(
                                                                                                () {
                                                                                                  if (counter >
                                                                                                          1 ||
                                                                                                      counter ==
                                                                                                          1) {
                                                                                                    counter--;
                                                                                                  }
                                                                                                },
                                                                                              );
                                                                                              Navigator.of(
                                                                                                context,
                                                                                              ).pop();
                                                                                            },
                                                                                            style: ElevatedButton.styleFrom(
                                                                                              backgroundColor: greyColor.shade400,
                                                                                              minimumSize: Size(
                                                                                                80,
                                                                                                40,
                                                                                              ),
                                                                                              padding: EdgeInsets.all(
                                                                                                20,
                                                                                              ),
                                                                                              shape: RoundedRectangleBorder(
                                                                                                borderRadius: BorderRadius.circular(
                                                                                                  10,
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            child: Text(
                                                                                              'Cancel',
                                                                                              style: MyTextStyle.f14(
                                                                                                blackColor,
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                          SizedBox(
                                                                                            width: 8,
                                                                                          ),
                                                                                          ElevatedButton(
                                                                                            onPressed: () {
                                                                                              final currentQtyInCart = getCurrentQuantity(
                                                                                                p.id.toString(),
                                                                                              );
                                                                                              bool canAdd;

                                                                                              if (p.isStock ==
                                                                                                  true) {
                                                                                                if ((widget.isEditingOrder ==
                                                                                                            true &&
                                                                                                        widget.existingOrder?.data?.orderStatus ==
                                                                                                            "COMPLETED") ||
                                                                                                    (widget.isEditingOrder ==
                                                                                                            true &&
                                                                                                        widget.existingOrder?.data?.orderStatus ==
                                                                                                            "WAITLIST")) {
                                                                                                  final paidQty =
                                                                                                      widget.existingOrder?.data?.items
                                                                                                          ?.firstWhereOrNull(
                                                                                                            (
                                                                                                              item,
                                                                                                            ) =>
                                                                                                                item.product?.id ==
                                                                                                                p.id,
                                                                                                          )
                                                                                                          ?.quantity ??
                                                                                                      0;
                                                                                                  canAdd =
                                                                                                      currentQtyInCart <
                                                                                                      ((p.availableQuantity ??
                                                                                                              0) +
                                                                                                          paidQty);
                                                                                                } else {
                                                                                                  canAdd =
                                                                                                      currentQtyInCart <
                                                                                                      (p.availableQuantity ??
                                                                                                          0);
                                                                                                }
                                                                                              } else {
                                                                                                canAdd = true;
                                                                                              }

                                                                                              if (!canAdd) {
                                                                                                showToast(
                                                                                                  "Cannot add more items. Stock limit reached.",
                                                                                                  context,
                                                                                                  color: false,
                                                                                                );
                                                                                                return;
                                                                                              }

                                                                                              setState(
                                                                                                () {
                                                                                                  isSplitPayment = false;
                                                                                                  if (widget.isEditingOrder !=
                                                                                                      true) {
                                                                                                    selectedOrderType = OrderType.line;
                                                                                                  }
                                                                                                  final index = billingItems.indexWhere(
                                                                                                    (
                                                                                                      item,
                                                                                                    ) =>
                                                                                                        item['_id'] ==
                                                                                                        p.id,
                                                                                                  );
                                                                                                  if (index !=
                                                                                                      -1) {
                                                                                                    billingItems[index]['qty'] =
                                                                                                        billingItems[index]['qty'] +
                                                                                                        1;
                                                                                                    updateControllerText(
                                                                                                      p.id.toString(),
                                                                                                      billingItems[index]['qty'],
                                                                                                    );
                                                                                                  } else {
                                                                                                    billingItems.add(
                                                                                                      {
                                                                                                        "_id": p.id,
                                                                                                        "basePrice": p.basePrice,
                                                                                                        "image": p.image,
                                                                                                        "qty": 1,
                                                                                                        "name": p.name,
                                                                                                        "availableQuantity": p.availableQuantity,
                                                                                                        "selectedAddons": p.addons!
                                                                                                            .where(
                                                                                                              (
                                                                                                                addon,
                                                                                                              ) =>
                                                                                                                  addon.quantity >
                                                                                                                  0,
                                                                                                            )
                                                                                                            .map(
                                                                                                              (
                                                                                                                addon,
                                                                                                              ) => {
                                                                                                                "_id": addon.id,
                                                                                                                "price": addon.price,
                                                                                                                "quantity": addon.quantity,
                                                                                                                "name": addon.name,
                                                                                                                "isAvailable": addon.isAvailable,
                                                                                                                "maxQuantity": addon.maxQuantity,
                                                                                                                "isFree": addon.isFree,
                                                                                                              },
                                                                                                            )
                                                                                                            .toList(),
                                                                                                      },
                                                                                                    );
                                                                                                    updateControllerText(
                                                                                                      p.id.toString(),
                                                                                                      1,
                                                                                                    );
                                                                                                  }
                                                                                                  context
                                                                                                      .read<
                                                                                                        FoodCategoryBloc
                                                                                                      >()
                                                                                                      .add(
                                                                                                        AddToBilling(
                                                                                                          List.from(
                                                                                                            billingItems,
                                                                                                          ),
                                                                                                          isDiscountApplied,
                                                                                                          selectedOrderType,
                                                                                                        ),
                                                                                                      );

                                                                                                  setState(
                                                                                                    () {
                                                                                                      for (var addon in p.addons!) {
                                                                                                        addon.isSelected = false;
                                                                                                        addon.quantity = 0;
                                                                                                      }
                                                                                                    },
                                                                                                  );
                                                                                                  Navigator.of(
                                                                                                    context,
                                                                                                  ).pop();
                                                                                                },
                                                                                              );
                                                                                            },
                                                                                            style: ElevatedButton.styleFrom(
                                                                                              backgroundColor: appPrimaryColor,
                                                                                              minimumSize: Size(
                                                                                                80,
                                                                                                40,
                                                                                              ),
                                                                                              padding: EdgeInsets.all(
                                                                                                20,
                                                                                              ),
                                                                                              shape: RoundedRectangleBorder(
                                                                                                borderRadius: BorderRadius.circular(
                                                                                                  10,
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            child: Text(
                                                                                              'Add to Bill',
                                                                                              style: MyTextStyle.f14(
                                                                                                whiteColor,
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            );
                                                                          },
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            );
                                                          } else {
                                                            final currentQtyInCart =
                                                                getCurrentQuantity(
                                                                  p.id.toString(),
                                                                );
                                                            bool canAdd;

                                                            if (p.isStock ==
                                                                true) {
                                                              if ((widget.isEditingOrder ==
                                                                          true &&
                                                                      widget
                                                                              .existingOrder
                                                                              ?.data
                                                                              ?.orderStatus ==
                                                                          "COMPLETED") ||
                                                                  (widget.isEditingOrder ==
                                                                          true &&
                                                                      widget
                                                                              .existingOrder
                                                                              ?.data
                                                                              ?.orderStatus ==
                                                                          "WAITLIST")) {
                                                                final paidQty =
                                                                    widget
                                                                        .existingOrder
                                                                        ?.data
                                                                        ?.items
                                                                        ?.firstWhereOrNull(
                                                                          (
                                                                            item,
                                                                          ) =>
                                                                              item.product?.id ==
                                                                              p.id,
                                                                        )
                                                                        ?.quantity ??
                                                                    0;
                                                                canAdd =
                                                                    currentQtyInCart <
                                                                    ((p.availableQuantity ??
                                                                            0) +
                                                                        paidQty);
                                                              } else {
                                                                canAdd =
                                                                    currentQtyInCart <
                                                                    (p.availableQuantity ??
                                                                        0);
                                                              }
                                                            } else {
                                                              canAdd = true;
                                                            }

                                                            if (!canAdd) {
                                                              showToast(
                                                                "Cannot add more items. Stock limit reached.",
                                                                context,
                                                                color: false,
                                                              );
                                                              return;
                                                            }

                                                            setState(() {
                                                              isSplitPayment =
                                                                  false;
                                                              if (widget
                                                                      .isEditingOrder !=
                                                                  true) {
                                                                selectedOrderType =
                                                                    OrderType
                                                                        .line;
                                                              }
                                                              final index =
                                                                  billingItems
                                                                      .indexWhere(
                                                                        (
                                                                          item,
                                                                        ) =>
                                                                            item['_id'] ==
                                                                            p.id,
                                                                      );
                                                              if (index != -1) {
                                                                billingItems[index]['qty'] =
                                                                    billingItems[index]['qty'] +
                                                                    1;
                                                                updateControllerText(
                                                                  p.id.toString(),
                                                                  billingItems[index]['qty'],
                                                                );
                                                              } else {
                                                                billingItems.add({
                                                                  "_id": p.id,
                                                                  "basePrice": p
                                                                      .basePrice,
                                                                  "image":
                                                                      p.image,
                                                                  "qty": 1,
                                                                  "name":
                                                                      p.name,
                                                                  "availableQuantity":
                                                                      p.availableQuantity,
                                                                  "selectedAddons": p
                                                                      .addons!
                                                                      .where(
                                                                        (
                                                                          addon,
                                                                        ) =>
                                                                            addon.quantity >
                                                                            0,
                                                                      )
                                                                      .map(
                                                                        (
                                                                          addon,
                                                                        ) => {
                                                                          "_id":
                                                                              addon.id,
                                                                          "price":
                                                                              addon.price,
                                                                          "quantity":
                                                                              addon.quantity,
                                                                          "name":
                                                                              addon.name,
                                                                          "isAvailable":
                                                                              addon.isAvailable,
                                                                          "maxQuantity":
                                                                              addon.maxQuantity,
                                                                          "isFree":
                                                                              addon.isFree,
                                                                        },
                                                                      )
                                                                      .toList(),
                                                                });
                                                                updateControllerText(
                                                                  p.id.toString(),
                                                                  1,
                                                                );
                                                              }
                                                              context
                                                                  .read<
                                                                    FoodCategoryBloc
                                                                  >()
                                                                  .add(
                                                                    AddToBilling(
                                                                      List.from(
                                                                        billingItems,
                                                                      ),
                                                                      isDiscountApplied,
                                                                      selectedOrderType,
                                                                    ),
                                                                  );
                                                            });
                                                          }
                                                        });
                                                      },
                                                      child: Opacity(
                                                        opacity:
                                                            (p.availableQuantity ??
                                                                        0) >
                                                                    0 ||
                                                                p.isStock ==
                                                                    false
                                                            ? 1.0
                                                            : 0.5,
                                                        child: Card(
                                                          color: whiteColor,
                                                          elevation: 6,
                                                          shadowColor:
                                                              greyColor,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              SizedBox(
                                                                height:
                                                                    size.height *
                                                                    0.16,
                                                                child: ClipRRect(
                                                                  borderRadius: const BorderRadius.only(
                                                                    topLeft:
                                                                        Radius.circular(
                                                                          15.0,
                                                                        ),
                                                                    topRight:
                                                                        Radius.circular(
                                                                          15.0,
                                                                        ),
                                                                  ),
                                                                  child: CachedNetworkImage(
                                                                    imageUrl:
                                                                        p.image ??
                                                                        "",
                                                                    width:
                                                                        size.width *
                                                                        0.5,
                                                                    height:
                                                                        size.height *
                                                                        0.15,
                                                                    fit: BoxFit
                                                                        .cover,
                                                                    errorWidget:
                                                                        (
                                                                          context,
                                                                          url,
                                                                          error,
                                                                        ) {
                                                                          return const Icon(
                                                                            Icons.error,
                                                                            size:
                                                                                30,
                                                                            color:
                                                                                appHomeTextColor,
                                                                          );
                                                                        },
                                                                    progressIndicatorBuilder:
                                                                        (
                                                                          context,
                                                                          url,
                                                                          downloadProgress,
                                                                        ) => const SpinKitCircle(
                                                                          color:
                                                                              appPrimaryColor,
                                                                          size:
                                                                              30,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ),
                                                              verticalSpace(
                                                                height: 5,
                                                              ),
                                                              SizedBox(
                                                                width:
                                                                    size.width *
                                                                    0.25,
                                                                child: Text(
                                                                  p.name ?? '',
                                                                  style: MyTextStyle.f13(
                                                                    blackColor,
                                                                    weight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                  maxLines: 3,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                ),
                                                              ),
                                                              verticalSpace(
                                                                height: 5,
                                                              ),
                                                              if (p.isStock ==
                                                                  true)
                                                                SizedBox(
                                                                  width:
                                                                      size.width *
                                                                      0.25,
                                                                  child: FittedBox(
                                                                    fit: BoxFit
                                                                        .scaleDown,
                                                                    child: Row(
                                                                      children: [
                                                                        Text(
                                                                          'Available: ',
                                                                          style: MyTextStyle.f12(
                                                                            greyColor,
                                                                            weight:
                                                                                FontWeight.w500,
                                                                          ),
                                                                          maxLines:
                                                                              1,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                        ),
                                                                        Text(
                                                                          '${p.availableQuantity ?? 0}',
                                                                          style: MyTextStyle.f12(
                                                                            (p.availableQuantity ??
                                                                                        0) >
                                                                                    0
                                                                                ? greyColor
                                                                                : redColor,
                                                                            weight:
                                                                                FontWeight.w500,
                                                                          ),
                                                                          maxLines:
                                                                              1,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              if ((p.availableQuantity ??
                                                                          0) <=
                                                                      0 &&
                                                                  p.isStock ==
                                                                      true) ...[
                                                                verticalSpace(
                                                                  height: 5,
                                                                ),
                                                                Container(
                                                                  padding:
                                                                      EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            8,
                                                                        vertical:
                                                                            4,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color: redColor
                                                                        .withOpacity(
                                                                          0.1,
                                                                        ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          4,
                                                                        ),
                                                                  ),
                                                                  child: Text(
                                                                    'Out of Stock',
                                                                    style: MyTextStyle.f12(
                                                                      redColor,
                                                                      weight: FontWeight
                                                                          .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                              if (currentQuantity ==
                                                                          0 &&
                                                                      (p.availableQuantity ??
                                                                              0) >
                                                                          0 ||
                                                                  (currentQuantity ==
                                                                          0 &&
                                                                      p.isStock ==
                                                                          false))
                                                                verticalSpace(
                                                                  height: 5,
                                                                ),
                                                              if (currentQuantity ==
                                                                          0 &&
                                                                      (p.availableQuantity ??
                                                                              0) >
                                                                          0 ||
                                                                  (currentQuantity ==
                                                                          0 &&
                                                                      p.isStock ==
                                                                          false))
                                                                SizedBox(
                                                                  width:
                                                                      size.width *
                                                                      0.25,
                                                                  child: FittedBox(
                                                                    fit: BoxFit
                                                                        .scaleDown,
                                                                    child: Text(
                                                                      '₹ ${p.basePrice}',
                                                                      style: MyTextStyle.f14(
                                                                        blackColor,
                                                                        weight:
                                                                            FontWeight.w600,
                                                                      ),
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                ),
                                                              if (currentQuantity !=
                                                                      0 &&
                                                                  (p.availableQuantity ??
                                                                          0) >
                                                                      0)
                                                                verticalSpace(
                                                                  height: 10,
                                                                ),
                                                              if (currentQuantity !=
                                                                      0 &&
                                                                  (p.availableQuantity ??
                                                                          0) >
                                                                      0)
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets.only(
                                                                        left:
                                                                            5.0,
                                                                        right:
                                                                            5.0,
                                                                      ),
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Expanded(
                                                                        child: Text(
                                                                          '₹ ${p.basePrice}',
                                                                          style: MyTextStyle.f14(
                                                                            blackColor,
                                                                            weight:
                                                                                FontWeight.w600,
                                                                          ),
                                                                          maxLines:
                                                                              1,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                      horizontalSpace(
                                                                        width:
                                                                            5,
                                                                      ),
                                                                      CircleAvatar(
                                                                        radius:
                                                                            15,
                                                                        backgroundColor:
                                                                            greyColor200,
                                                                        child: IconButton(
                                                                          icon: const Icon(
                                                                            Icons.remove,
                                                                            size:
                                                                                15,
                                                                            color:
                                                                                blackColor,
                                                                          ),
                                                                          onPressed: () {
                                                                            setState(() {
                                                                              isSplitPayment = false;
                                                                              if (widget.isEditingOrder !=
                                                                                  true) {
                                                                                selectedOrderType = OrderType.line;
                                                                              }
                                                                              final index = billingItems.indexWhere(
                                                                                (
                                                                                  item,
                                                                                ) =>
                                                                                    item['_id'] ==
                                                                                    p.id,
                                                                              );
                                                                              if (index !=
                                                                                      -1 &&
                                                                                  billingItems[index]['qty'] >
                                                                                      1) {
                                                                                billingItems[index]['qty'] =
                                                                                    billingItems[index]['qty'] -
                                                                                    1;
                                                                                updateControllerText(
                                                                                  p.id.toString(),
                                                                                  billingItems[index]['qty'],
                                                                                );
                                                                              } else {
                                                                                billingItems.removeWhere(
                                                                                  (
                                                                                    item,
                                                                                  ) =>
                                                                                      item['_id'] ==
                                                                                      p.id,
                                                                                );
                                                                                quantityControllers.remove(
                                                                                  p.id,
                                                                                );
                                                                                if (billingItems.isEmpty ||
                                                                                    billingItems ==
                                                                                        []) {
                                                                                  isDiscountApplied = false;
                                                                                  widget.isEditingOrder = false;
                                                                                  tableId = null;
                                                                                  waiterId = null;
                                                                                  selectedValue = null;
                                                                                  selectedValueWaiter = null;
                                                                                }
                                                                              }
                                                                              context
                                                                                  .read<
                                                                                    FoodCategoryBloc
                                                                                  >()
                                                                                  .add(
                                                                                    AddToBilling(
                                                                                      List.from(
                                                                                        billingItems,
                                                                                      ),
                                                                                      isDiscountApplied,
                                                                                      selectedOrderType,
                                                                                    ),
                                                                                  );
                                                                            });
                                                                          },
                                                                        ),
                                                                      ),
                                                                      Container(
                                                                        width:
                                                                            45,
                                                                        height:
                                                                            32,
                                                                        margin: const EdgeInsets.symmetric(
                                                                          horizontal:
                                                                              12,
                                                                        ),
                                                                        decoration: BoxDecoration(
                                                                          border: Border.all(
                                                                            color:
                                                                                greyColor,
                                                                          ),
                                                                          borderRadius:
                                                                              BorderRadius.circular(
                                                                                4,
                                                                              ),
                                                                        ),
                                                                        child: TextField(
                                                                          controller:
                                                                              currentController,
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                          keyboardType:
                                                                              TextInputType.number,
                                                                          style: MyTextStyle.f16(
                                                                            blackColor,
                                                                          ),
                                                                          decoration: const InputDecoration(
                                                                            border:
                                                                                InputBorder.none,
                                                                            isDense:
                                                                                true,
                                                                            contentPadding: EdgeInsets.all(
                                                                              8,
                                                                            ),
                                                                          ),
                                                                          onChanged:
                                                                              (
                                                                                value,
                                                                              ) {
                                                                                final newQty = int.tryParse(
                                                                                  value,
                                                                                );
                                                                                if (newQty !=
                                                                                        null &&
                                                                                    newQty >
                                                                                        0) {
                                                                                  bool canSetQuantity;
                                                                                  if (p.isStock ==
                                                                                      true) {
                                                                                    if ((widget.isEditingOrder ==
                                                                                                true &&
                                                                                            widget.existingOrder?.data?.orderStatus ==
                                                                                                "COMPLETED") ||
                                                                                        (widget.isEditingOrder ==
                                                                                                true &&
                                                                                            widget.existingOrder?.data?.orderStatus ==
                                                                                                "WAITLIST")) {
                                                                                      final paidQty =
                                                                                          widget.existingOrder?.data?.items
                                                                                              ?.firstWhereOrNull(
                                                                                                (
                                                                                                  item,
                                                                                                ) =>
                                                                                                    item.product?.id ==
                                                                                                    p.id,
                                                                                              )
                                                                                              ?.quantity ??
                                                                                          0;
                                                                                      canSetQuantity =
                                                                                          newQty <=
                                                                                          ((p.availableQuantity ??
                                                                                                  0) +
                                                                                              paidQty);
                                                                                    } else {
                                                                                      canSetQuantity =
                                                                                          newQty <=
                                                                                          (p.availableQuantity ??
                                                                                              0);
                                                                                    }
                                                                                  } else {
                                                                                    canSetQuantity = true;
                                                                                  }

                                                                                  if (canSetQuantity) {
                                                                                    setState(
                                                                                      () {
                                                                                        isSplitPayment = false;
                                                                                        if (widget.isEditingOrder !=
                                                                                            true) {
                                                                                          selectedOrderType = OrderType.line;
                                                                                        }

                                                                                        final index = billingItems.indexWhere(
                                                                                          (
                                                                                            item,
                                                                                          ) =>
                                                                                              item['_id'] ==
                                                                                              p.id,
                                                                                        );
                                                                                        if (index !=
                                                                                            -1) {
                                                                                          billingItems[index]['qty'] = newQty;
                                                                                        } else {
                                                                                          billingItems.add(
                                                                                            {
                                                                                              "_id": p.id,
                                                                                              "basePrice": p.basePrice,
                                                                                              "image": p.image,
                                                                                              "qty": newQty,
                                                                                              "name": p.name,
                                                                                              "availableQuantity": p.availableQuantity,
                                                                                              "selectedAddons": p.addons!
                                                                                                  .where(
                                                                                                    (
                                                                                                      addon,
                                                                                                    ) =>
                                                                                                        addon.quantity >
                                                                                                        0,
                                                                                                  )
                                                                                                  .map(
                                                                                                    (
                                                                                                      addon,
                                                                                                    ) => {
                                                                                                      "_id": addon.id,
                                                                                                      "price": addon.price,
                                                                                                      "quantity": addon.quantity,
                                                                                                      "name": addon.name,
                                                                                                      "isAvailable": addon.isAvailable,
                                                                                                      "maxQuantity": addon.maxQuantity,
                                                                                                      "isFree": addon.isFree,
                                                                                                    },
                                                                                                  )
                                                                                                  .toList(),
                                                                                            },
                                                                                          );
                                                                                        }
                                                                                        context
                                                                                            .read<
                                                                                              FoodCategoryBloc
                                                                                            >()
                                                                                            .add(
                                                                                              AddToBilling(
                                                                                                List.from(
                                                                                                  billingItems,
                                                                                                ),
                                                                                                isDiscountApplied,
                                                                                                selectedOrderType,
                                                                                              ),
                                                                                            );
                                                                                      },
                                                                                    );
                                                                                  } else {
                                                                                    currentController.text = getCurrentQuantity(
                                                                                      p.id.toString(),
                                                                                    ).toString();
                                                                                    ScaffoldMessenger.of(
                                                                                      context,
                                                                                    ).showSnackBar(
                                                                                      SnackBar(
                                                                                        content: Text(
                                                                                          "Maximum available quantity is ${p.availableQuantity ?? 0}",
                                                                                        ),
                                                                                      ),
                                                                                    );
                                                                                  }
                                                                                } else if (newQty ==
                                                                                        0 ||
                                                                                    value.isEmpty) {
                                                                                  setState(
                                                                                    () {
                                                                                      billingItems.removeWhere(
                                                                                        (
                                                                                          item,
                                                                                        ) =>
                                                                                            item['_id'] ==
                                                                                            p.id,
                                                                                      );
                                                                                      quantityControllers.remove(
                                                                                        p.id,
                                                                                      );
                                                                                      if (billingItems.isEmpty ||
                                                                                          billingItems ==
                                                                                              []) {
                                                                                        isDiscountApplied = false;
                                                                                        widget.isEditingOrder = false;
                                                                                        tableId = null;
                                                                                        waiterId = null;
                                                                                        selectedValue = null;
                                                                                        selectedValueWaiter = null;
                                                                                      }
                                                                                      context
                                                                                          .read<
                                                                                            FoodCategoryBloc
                                                                                          >()
                                                                                          .add(
                                                                                            AddToBilling(
                                                                                              List.from(
                                                                                                billingItems,
                                                                                              ),
                                                                                              isDiscountApplied,
                                                                                              selectedOrderType,
                                                                                            ),
                                                                                          );
                                                                                    },
                                                                                  );
                                                                                }
                                                                              },
                                                                          onTap: () {
                                                                            currentController.selection = TextSelection(
                                                                              baseOffset: 0,
                                                                              extentOffset: currentController.text.length,
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                      Builder(
                                                                        builder:
                                                                            (
                                                                              context,
                                                                            ) {
                                                                              final currentQtyInCart = getCurrentQuantity(
                                                                                p.id.toString(),
                                                                              );
                                                                              bool
                                                                              canAddMore;
                                                                              if (p.isStock ==
                                                                                  true) {
                                                                                if ((widget.isEditingOrder ==
                                                                                            true &&
                                                                                        widget.existingOrder?.data?.orderStatus ==
                                                                                            "COMPLETED") ||
                                                                                    (widget.isEditingOrder ==
                                                                                            true &&
                                                                                        widget.existingOrder?.data?.orderStatus ==
                                                                                            "WAITLIST")) {
                                                                                  final paidQty =
                                                                                      widget.existingOrder?.data?.items
                                                                                          ?.firstWhereOrNull(
                                                                                            (
                                                                                              item,
                                                                                            ) =>
                                                                                                item.product?.id ==
                                                                                                p.id,
                                                                                          )
                                                                                          ?.quantity ??
                                                                                      0;
                                                                                  canAddMore =
                                                                                      currentQtyInCart <
                                                                                      ((p.availableQuantity ??
                                                                                              0) +
                                                                                          paidQty);
                                                                                } else {
                                                                                  canAddMore =
                                                                                      (p.availableQuantity ??
                                                                                              0) >
                                                                                          0 &&
                                                                                      currentQtyInCart <
                                                                                          (p.availableQuantity ??
                                                                                              0);
                                                                                }
                                                                              } else {
                                                                                canAddMore = true;
                                                                              }

                                                                              return CircleAvatar(
                                                                                radius: 15,
                                                                                backgroundColor: canAddMore
                                                                                    ? appPrimaryColor
                                                                                    : greyColor,
                                                                                child: IconButton(
                                                                                  icon: Icon(
                                                                                    Icons.add,
                                                                                    size: 16,
                                                                                    color: canAddMore
                                                                                        ? whiteColor
                                                                                        : blackColor,
                                                                                  ),
                                                                                  onPressed: canAddMore
                                                                                      ? () {
                                                                                          setState(
                                                                                            () {
                                                                                              isSplitPayment = false;
                                                                                              if (widget.isEditingOrder !=
                                                                                                  true) {
                                                                                                selectedOrderType = OrderType.line;
                                                                                              }
                                                                                              final index = billingItems.indexWhere(
                                                                                                (
                                                                                                  item,
                                                                                                ) =>
                                                                                                    item['_id'] ==
                                                                                                    p.id,
                                                                                              );
                                                                                              if (index !=
                                                                                                  -1) {
                                                                                                billingItems[index]['qty'] =
                                                                                                    billingItems[index]['qty'] +
                                                                                                    1;
                                                                                                updateControllerText(
                                                                                                  p.id.toString(),
                                                                                                  billingItems[index]['qty'],
                                                                                                );
                                                                                              } else {
                                                                                                billingItems.add(
                                                                                                  {
                                                                                                    "_id": p.id,
                                                                                                    "basePrice": p.basePrice,
                                                                                                    "image": p.image,
                                                                                                    "qty": 1,
                                                                                                    "name": p.name,
                                                                                                    "availableQuantity": p.availableQuantity,
                                                                                                    "selectedAddons": p.addons!
                                                                                                        .where(
                                                                                                          (
                                                                                                            addon,
                                                                                                          ) =>
                                                                                                              addon.quantity >
                                                                                                              0,
                                                                                                        )
                                                                                                        .map(
                                                                                                          (
                                                                                                            addon,
                                                                                                          ) => {
                                                                                                            "_id": addon.id,
                                                                                                            "price": addon.price,
                                                                                                            "quantity": addon.quantity,
                                                                                                            "name": addon.name,
                                                                                                            "isAvailable": addon.isAvailable,
                                                                                                            "maxQuantity": addon.maxQuantity,
                                                                                                            "isFree": addon.isFree,
                                                                                                          },
                                                                                                        )
                                                                                                        .toList(),
                                                                                                  },
                                                                                                );
                                                                                                updateControllerText(
                                                                                                  p.id.toString(),
                                                                                                  1,
                                                                                                );
                                                                                              }
                                                                                              context
                                                                                                  .read<
                                                                                                    FoodCategoryBloc
                                                                                                  >()
                                                                                                  .add(
                                                                                                    AddToBilling(
                                                                                                      List.from(
                                                                                                        billingItems,
                                                                                                      ),
                                                                                                      isDiscountApplied,
                                                                                                      selectedOrderType,
                                                                                                    ),
                                                                                                  );
                                                                                            },
                                                                                          );
                                                                                        }
                                                                                      : () {
                                                                                          if (p.isStock ==
                                                                                                  true &&
                                                                                              (p.availableQuantity ??
                                                                                                      0) ==
                                                                                                  0) {
                                                                                            ScaffoldMessenger.of(
                                                                                              context,
                                                                                            ).showSnackBar(
                                                                                              const SnackBar(
                                                                                                content: Text(
                                                                                                  "Out of stock",
                                                                                                ),
                                                                                              ),
                                                                                            );
                                                                                          }
                                                                                        },
                                                                                ),
                                                                              );
                                                                            },
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              if (currentQuantity !=
                                                                      0 &&
                                                                  p.isStock ==
                                                                      false)
                                                                verticalSpace(
                                                                  height: 10,
                                                                ),
                                                              if (currentQuantity !=
                                                                      0 &&
                                                                  p.isStock ==
                                                                      false)
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets.only(
                                                                        left:
                                                                            5.0,
                                                                        right:
                                                                            5.0,
                                                                      ),
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Expanded(
                                                                        child: Text(
                                                                          '₹ ${p.basePrice}',
                                                                          style: MyTextStyle.f14(
                                                                            blackColor,
                                                                            weight:
                                                                                FontWeight.w600,
                                                                          ),
                                                                          maxLines:
                                                                              1,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                      horizontalSpace(
                                                                        width:
                                                                            5,
                                                                      ),
                                                                      CircleAvatar(
                                                                        radius:
                                                                            15,
                                                                        backgroundColor:
                                                                            greyColor200,
                                                                        child: IconButton(
                                                                          icon: const Icon(
                                                                            Icons.remove,
                                                                            size:
                                                                                15,
                                                                            color:
                                                                                blackColor,
                                                                          ),
                                                                          onPressed: () {
                                                                            setState(() {
                                                                              isSplitPayment = false;
                                                                              if (widget.isEditingOrder !=
                                                                                  true) {
                                                                                selectedOrderType = OrderType.line;
                                                                              }
                                                                              final index = billingItems.indexWhere(
                                                                                (
                                                                                  item,
                                                                                ) =>
                                                                                    item['_id'] ==
                                                                                    p.id,
                                                                              );
                                                                              if (index !=
                                                                                      -1 &&
                                                                                  billingItems[index]['qty'] >
                                                                                      1) {
                                                                                billingItems[index]['qty'] =
                                                                                    billingItems[index]['qty'] -
                                                                                    1;
                                                                                updateControllerText(
                                                                                  p.id.toString(),
                                                                                  billingItems[index]['qty'],
                                                                                );
                                                                              } else {
                                                                                billingItems.removeWhere(
                                                                                  (
                                                                                    item,
                                                                                  ) =>
                                                                                      item['_id'] ==
                                                                                      p.id,
                                                                                );
                                                                                quantityControllers.remove(
                                                                                  p.id,
                                                                                );
                                                                                if (billingItems.isEmpty ||
                                                                                    billingItems ==
                                                                                        []) {
                                                                                  isDiscountApplied = false;
                                                                                  widget.isEditingOrder = false;
                                                                                  tableId = null;
                                                                                  waiterId = null;
                                                                                  selectedValue = null;
                                                                                  selectedValueWaiter = null;
                                                                                }
                                                                              }
                                                                              context
                                                                                  .read<
                                                                                    FoodCategoryBloc
                                                                                  >()
                                                                                  .add(
                                                                                    AddToBilling(
                                                                                      List.from(
                                                                                        billingItems,
                                                                                      ),
                                                                                      isDiscountApplied,
                                                                                      selectedOrderType,
                                                                                    ),
                                                                                  );
                                                                            });
                                                                          },
                                                                        ),
                                                                      ),
                                                                      Container(
                                                                        width:
                                                                            45,
                                                                        height:
                                                                            32,
                                                                        margin: const EdgeInsets.symmetric(
                                                                          horizontal:
                                                                              12,
                                                                        ),
                                                                        decoration: BoxDecoration(
                                                                          border: Border.all(
                                                                            color:
                                                                                greyColor,
                                                                          ),
                                                                          borderRadius:
                                                                              BorderRadius.circular(
                                                                                4,
                                                                              ),
                                                                        ),
                                                                        child: TextField(
                                                                          controller:
                                                                              currentController,
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                          keyboardType:
                                                                              TextInputType.number,
                                                                          style: MyTextStyle.f16(
                                                                            blackColor,
                                                                          ),
                                                                          decoration: const InputDecoration(
                                                                            border:
                                                                                InputBorder.none,
                                                                            isDense:
                                                                                true,
                                                                            contentPadding: EdgeInsets.all(
                                                                              8,
                                                                            ),
                                                                          ),
                                                                          onChanged:
                                                                              (
                                                                                value,
                                                                              ) {
                                                                                final newQty = int.tryParse(
                                                                                  value,
                                                                                );
                                                                                if (newQty !=
                                                                                        null &&
                                                                                    newQty >
                                                                                        0) {
                                                                                  bool canSetQuantity;
                                                                                  if (p.isStock ==
                                                                                      true) {
                                                                                    if ((widget.isEditingOrder ==
                                                                                                true &&
                                                                                            widget.existingOrder?.data?.orderStatus ==
                                                                                                "COMPLETED") ||
                                                                                        (widget.isEditingOrder ==
                                                                                                true &&
                                                                                            widget.existingOrder?.data?.orderStatus ==
                                                                                                "WAITLIST")) {
                                                                                      final paidQty =
                                                                                          widget.existingOrder?.data?.items
                                                                                              ?.firstWhereOrNull(
                                                                                                (
                                                                                                  item,
                                                                                                ) =>
                                                                                                    item.product?.id ==
                                                                                                    p.id,
                                                                                              )
                                                                                              ?.quantity ??
                                                                                          0;
                                                                                      canSetQuantity =
                                                                                          newQty <=
                                                                                          ((p.availableQuantity ??
                                                                                                  0) +
                                                                                              paidQty);
                                                                                    } else {
                                                                                      canSetQuantity =
                                                                                          newQty <=
                                                                                          (p.availableQuantity ??
                                                                                              0);
                                                                                    }
                                                                                  } else {
                                                                                    canSetQuantity = true;
                                                                                  }

                                                                                  if (canSetQuantity) {
                                                                                    setState(
                                                                                      () {
                                                                                        isSplitPayment = false;
                                                                                        if (widget.isEditingOrder !=
                                                                                            true) {
                                                                                          selectedOrderType = OrderType.line;
                                                                                        }

                                                                                        final index = billingItems.indexWhere(
                                                                                          (
                                                                                            item,
                                                                                          ) =>
                                                                                              item['_id'] ==
                                                                                              p.id,
                                                                                        );
                                                                                        if (index !=
                                                                                            -1) {
                                                                                          billingItems[index]['qty'] = newQty;
                                                                                        } else {
                                                                                          billingItems.add(
                                                                                            {
                                                                                              "_id": p.id,
                                                                                              "basePrice": p.basePrice,
                                                                                              "image": p.image,
                                                                                              "qty": newQty,
                                                                                              "name": p.name,
                                                                                              "availableQuantity": p.availableQuantity,
                                                                                              "selectedAddons": p.addons!
                                                                                                  .where(
                                                                                                    (
                                                                                                      addon,
                                                                                                    ) =>
                                                                                                        addon.quantity >
                                                                                                        0,
                                                                                                  )
                                                                                                  .map(
                                                                                                    (
                                                                                                      addon,
                                                                                                    ) => {
                                                                                                      "_id": addon.id,
                                                                                                      "price": addon.price,
                                                                                                      "quantity": addon.quantity,
                                                                                                      "name": addon.name,
                                                                                                      "isAvailable": addon.isAvailable,
                                                                                                      "maxQuantity": addon.maxQuantity,
                                                                                                      "isFree": addon.isFree,
                                                                                                    },
                                                                                                  )
                                                                                                  .toList(),
                                                                                            },
                                                                                          );
                                                                                        }
                                                                                        context
                                                                                            .read<
                                                                                              FoodCategoryBloc
                                                                                            >()
                                                                                            .add(
                                                                                              AddToBilling(
                                                                                                List.from(
                                                                                                  billingItems,
                                                                                                ),
                                                                                                isDiscountApplied,
                                                                                                selectedOrderType,
                                                                                              ),
                                                                                            );
                                                                                      },
                                                                                    );
                                                                                  } else {
                                                                                    currentController.text = getCurrentQuantity(
                                                                                      p.id.toString(),
                                                                                    ).toString();
                                                                                    ScaffoldMessenger.of(
                                                                                      context,
                                                                                    ).showSnackBar(
                                                                                      SnackBar(
                                                                                        content: Text(
                                                                                          "Maximum available quantity is ${p.availableQuantity ?? 0}",
                                                                                        ),
                                                                                      ),
                                                                                    );
                                                                                  }
                                                                                } else if (newQty ==
                                                                                        0 ||
                                                                                    value.isEmpty) {
                                                                                  setState(
                                                                                    () {
                                                                                      billingItems.removeWhere(
                                                                                        (
                                                                                          item,
                                                                                        ) =>
                                                                                            item['_id'] ==
                                                                                            p.id,
                                                                                      );
                                                                                      quantityControllers.remove(
                                                                                        p.id,
                                                                                      );
                                                                                      if (billingItems.isEmpty ||
                                                                                          billingItems ==
                                                                                              []) {
                                                                                        isDiscountApplied = false;
                                                                                        widget.isEditingOrder = false;
                                                                                        tableId = null;
                                                                                        waiterId = null;
                                                                                        selectedValue = null;
                                                                                        selectedValueWaiter = null;
                                                                                      }
                                                                                      context
                                                                                          .read<
                                                                                            FoodCategoryBloc
                                                                                          >()
                                                                                          .add(
                                                                                            AddToBilling(
                                                                                              List.from(
                                                                                                billingItems,
                                                                                              ),
                                                                                              isDiscountApplied,
                                                                                              selectedOrderType,
                                                                                            ),
                                                                                          );
                                                                                    },
                                                                                  );
                                                                                }
                                                                              },
                                                                          onTap: () {
                                                                            currentController.selection = TextSelection(
                                                                              baseOffset: 0,
                                                                              extentOffset: currentController.text.length,
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                      Builder(
                                                                        builder:
                                                                            (
                                                                              context,
                                                                            ) {
                                                                              final currentQtyInCart = getCurrentQuantity(
                                                                                p.id.toString(),
                                                                              );
                                                                              bool
                                                                              canAddMore;
                                                                              if (p.isStock ==
                                                                                  true) {
                                                                                if ((widget.isEditingOrder ==
                                                                                            true &&
                                                                                        widget.existingOrder?.data?.orderStatus ==
                                                                                            "COMPLETED") ||
                                                                                    (widget.isEditingOrder ==
                                                                                            true &&
                                                                                        widget.existingOrder?.data?.orderStatus ==
                                                                                            "WAITLIST")) {
                                                                                  final paidQty =
                                                                                      widget.existingOrder?.data?.items
                                                                                          ?.firstWhereOrNull(
                                                                                            (
                                                                                              item,
                                                                                            ) =>
                                                                                                item.product?.id ==
                                                                                                p.id,
                                                                                          )
                                                                                          ?.quantity ??
                                                                                      0;
                                                                                  canAddMore =
                                                                                      currentQtyInCart <
                                                                                      ((p.availableQuantity ??
                                                                                              0) +
                                                                                          paidQty);
                                                                                } else {
                                                                                  canAddMore =
                                                                                      (p.availableQuantity ??
                                                                                              0) >
                                                                                          0 &&
                                                                                      currentQtyInCart <
                                                                                          (p.availableQuantity ??
                                                                                              0);
                                                                                }
                                                                              } else {
                                                                                canAddMore = true;
                                                                              }

                                                                              return CircleAvatar(
                                                                                radius: 15,
                                                                                backgroundColor: canAddMore
                                                                                    ? appPrimaryColor
                                                                                    : greyColor,
                                                                                child: IconButton(
                                                                                  icon: Icon(
                                                                                    Icons.add,
                                                                                    size: 15,
                                                                                    color: canAddMore
                                                                                        ? whiteColor
                                                                                        : blackColor,
                                                                                  ),
                                                                                  onPressed: canAddMore
                                                                                      ? () {
                                                                                          setState(
                                                                                            () {
                                                                                              isSplitPayment = false;
                                                                                              if (widget.isEditingOrder !=
                                                                                                  true) {
                                                                                                selectedOrderType = OrderType.line;
                                                                                              }
                                                                                              final index = billingItems.indexWhere(
                                                                                                (
                                                                                                  item,
                                                                                                ) =>
                                                                                                    item['_id'] ==
                                                                                                    p.id,
                                                                                              );
                                                                                              if (index !=
                                                                                                  -1) {
                                                                                                billingItems[index]['qty'] =
                                                                                                    billingItems[index]['qty'] +
                                                                                                    1;
                                                                                                updateControllerText(
                                                                                                  p.id.toString(),
                                                                                                  billingItems[index]['qty'],
                                                                                                );
                                                                                              } else {
                                                                                                billingItems.add(
                                                                                                  {
                                                                                                    "_id": p.id,
                                                                                                    "basePrice": p.basePrice,
                                                                                                    "image": p.image,
                                                                                                    "qty": 1,
                                                                                                    "name": p.name,
                                                                                                    "availableQuantity": p.availableQuantity,
                                                                                                    "selectedAddons": p.addons!
                                                                                                        .where(
                                                                                                          (
                                                                                                            addon,
                                                                                                          ) =>
                                                                                                              addon.quantity >
                                                                                                              0,
                                                                                                        )
                                                                                                        .map(
                                                                                                          (
                                                                                                            addon,
                                                                                                          ) => {
                                                                                                            "_id": addon.id,
                                                                                                            "price": addon.price,
                                                                                                            "quantity": addon.quantity,
                                                                                                            "name": addon.name,
                                                                                                            "isAvailable": addon.isAvailable,
                                                                                                            "maxQuantity": addon.maxQuantity,
                                                                                                            "isFree": addon.isFree,
                                                                                                          },
                                                                                                        )
                                                                                                        .toList(),
                                                                                                  },
                                                                                                );
                                                                                                updateControllerText(
                                                                                                  p.id.toString(),
                                                                                                  1,
                                                                                                );
                                                                                              }
                                                                                              context
                                                                                                  .read<
                                                                                                    FoodCategoryBloc
                                                                                                  >()
                                                                                                  .add(
                                                                                                    AddToBilling(
                                                                                                      List.from(
                                                                                                        billingItems,
                                                                                                      ),
                                                                                                      isDiscountApplied,
                                                                                                      selectedOrderType,
                                                                                                    ),
                                                                                                  );
                                                                                            },
                                                                                          );
                                                                                        }
                                                                                      : () {
                                                                                          if (p.isStock ==
                                                                                                  true &&
                                                                                              (p.availableQuantity ??
                                                                                                      0) ==
                                                                                                  0) {
                                                                                            ScaffoldMessenger.of(
                                                                                              context,
                                                                                            ).showSnackBar(
                                                                                              const SnackBar(
                                                                                                content: Text(
                                                                                                  "Out of stock",
                                                                                                ),
                                                                                              ),
                                                                                            );
                                                                                          }
                                                                                        },
                                                                                ),
                                                                              );
                                                                            },
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                          // ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                          /// cart tab
                          SizedBox(
                            width: size.width * 0.5,
                            child: SingleChildScrollView(
                              child:
                                  postAddToBillingModel.items == null ||
                                      postAddToBillingModel.items!.isEmpty ||
                                      postAddToBillingModel.items == []
                                  ? SingleChildScrollView(
                                      child: Container(
                                        margin: EdgeInsets.only(top: 30),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: InkWell(
                                                    onTap: () {},
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: appPrimaryColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              30,
                                                            ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          "Line",
                                                          style:
                                                              MyTextStyle.f12(
                                                                whiteColor,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: InkWell(
                                                    onTap: () {},
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 8,
                                                          ),
                                                      constraints:
                                                          const BoxConstraints(
                                                            minWidth: 70,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: whiteColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              30,
                                                            ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          "Parcel",
                                                          style:
                                                              MyTextStyle.f12(
                                                                blackColor,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 2),
                                                Expanded(
                                                  child: InkWell(
                                                    onTap: () {},
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 8,
                                                          ),
                                                      constraints:
                                                          const BoxConstraints(
                                                            minWidth: 70,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: whiteColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              30,
                                                            ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          "AC",
                                                          style:
                                                              MyTextStyle.f12(
                                                                blackColor,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: InkWell(
                                                    onTap: () {},
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 8,
                                                          ),
                                                      constraints:
                                                          const BoxConstraints(
                                                            minWidth: 70,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: whiteColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              30,
                                                            ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          "HD",
                                                          style:
                                                              MyTextStyle.f12(
                                                                blackColor,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: InkWell(
                                                    onTap: () {},
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 8,
                                                          ),
                                                      constraints:
                                                          const BoxConstraints(
                                                            minWidth: 70,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: whiteColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              30,
                                                            ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          "SWIGGY",
                                                          style:
                                                              MyTextStyle.f12(
                                                                blackColor,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  "Bills",
                                                  style: MyTextStyle.f14(
                                                    blackColor,
                                                    weight: FontWeight.bold,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      billingItems.clear();
                                                      selectedValue = null;
                                                      selectedValueWaiter =
                                                          null;
                                                      tableId = null;
                                                      waiterId = null;
                                                      selectedOrderType =
                                                          OrderType.line;
                                                      isCompleteOrder = false;
                                                      isSplitPayment = false;
                                                      selectedFullPaymentMethod =
                                                          "";
                                                      widget.isEditingOrder =
                                                          false;
                                                      balance = 0;
                                                      if (billingItems
                                                          .isEmpty) {
                                                        isDiscountApplied =
                                                            false;
                                                      }
                                                    });
                                                    context
                                                        .read<
                                                          FoodCategoryBloc
                                                        >()
                                                        .add(
                                                          AddToBilling(
                                                            List.from(
                                                              billingItems,
                                                            ),
                                                            isDiscountApplied,
                                                            selectedOrderType,
                                                          ),
                                                        );
                                                  },
                                                  icon: const Icon(
                                                    Icons.refresh,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 25),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "No.items in bill",
                                                  style: MyTextStyle.f14(
                                                    greyColor,
                                                    weight: FontWeight.w400,
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Text("₹ 0.00"),
                                              ],
                                            ),
                                            Divider(),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Subtotal",
                                                  style: MyTextStyle.f14(
                                                    greyColor,
                                                    weight: FontWeight.w400,
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Text("₹ 0.00"),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Total Tax",
                                                  style: MyTextStyle.f14(
                                                    greyColor,
                                                    weight: FontWeight.w400,
                                                  ),
                                                ),
                                                Text("₹ 0.00"),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Divider(),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Total",
                                                  style: MyTextStyle.f14(
                                                    blackColor,
                                                    weight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  "₹ 0.00",
                                                  style: MyTextStyle.f18(
                                                    blackColor,
                                                    weight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Current Payment Amount",
                                                  style: MyTextStyle.f14(
                                                    blackColor,
                                                    weight: FontWeight.w400,
                                                  ),
                                                ),
                                                Text(
                                                  "₹ 0.00",
                                                  style: MyTextStyle.f14(
                                                    blackColor,
                                                    weight: FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 12),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: greyColor200,
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            vertical: 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: appPrimaryColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              30,
                                                            ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          "Full Payment",
                                                          style:
                                                              MyTextStyle.f12(
                                                                whiteColor,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            vertical: 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: greyColor200,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              30,
                                                            ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          "Split Payment",
                                                          style:
                                                              MyTextStyle.f12(
                                                                blackColor,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 12),
                                            Text(
                                              "Payment Method",
                                              style: MyTextStyle.f12(
                                                blackColor,
                                                weight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 12),
                                            SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Wrap(
                                                spacing: 12,
                                                runSpacing: 12,
                                                children: [
                                                  PaymentOption(
                                                    icon: Icons.money,
                                                    label: "Cash",
                                                    selected: false,
                                                  ),
                                                  PaymentOption(
                                                    icon: Icons.credit_card,
                                                    label: "Card",
                                                    selected: false,
                                                  ),
                                                  PaymentOption(
                                                    icon: Icons.qr_code,
                                                    label: "UPI",
                                                    selected: false,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        if (billingItems ==
                                                                [] ||
                                                            billingItems
                                                                .isEmpty) {
                                                          showToast(
                                                            "No items in the bill to save or complete.",
                                                            context,
                                                            color: false,
                                                          );
                                                        }
                                                      });
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          appGreyColor,
                                                      minimumSize: const Size(
                                                        0,
                                                        50,
                                                      ), // Height only
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              30,
                                                            ),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      "Save Order",
                                                      style: TextStyle(
                                                        color: blackColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 10,
                                                ), // Space between buttons
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        if (billingItems ==
                                                                [] ||
                                                            billingItems
                                                                .isEmpty) {
                                                          showToast(
                                                            "No items in the bill to save or complete.",
                                                            context,
                                                            color: false,
                                                          );
                                                        }
                                                      });
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          appGreyColor,
                                                      minimumSize: const Size(
                                                        0,
                                                        50,
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              30,
                                                            ),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      "Complete Order",
                                                      style: TextStyle(
                                                        color: blackColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Container(
                                      margin: EdgeInsets.only(top: 35),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      selectedOrderType =
                                                          OrderType.line;
                                                      if (widget
                                                              .isEditingOrder !=
                                                          true) {
                                                        selectedValue = null;
                                                        selectedValueWaiter =
                                                            null;
                                                        tableId = null;
                                                        waiterId = null;
                                                      }
                                                      isSplitPayment = false;
                                                      context
                                                          .read<
                                                            FoodCategoryBloc
                                                          >()
                                                          .add(
                                                            AddToBilling(
                                                              List.from(
                                                                billingItems,
                                                              ),
                                                              isDiscountApplied,
                                                              selectedOrderType,
                                                            ),
                                                          );
                                                    });
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 8,
                                                        ),
                                                    constraints:
                                                        const BoxConstraints(
                                                          minWidth: 70,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          selectedOrderType ==
                                                              OrderType.line
                                                          ? appPrimaryColor
                                                          : whiteColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            30,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        "Line",
                                                        style: MyTextStyle.f12(
                                                          selectedOrderType ==
                                                                  OrderType.line
                                                              ? whiteColor
                                                              : blackColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      selectedOrderType =
                                                          OrderType.parcel;
                                                      if (widget
                                                              .isEditingOrder !=
                                                          true) {
                                                        selectedValue = null;
                                                        selectedValueWaiter =
                                                            null;
                                                        tableId = null;
                                                        waiterId = null;
                                                      }
                                                      isSplitPayment = false;
                                                      context
                                                          .read<
                                                            FoodCategoryBloc
                                                          >()
                                                          .add(
                                                            AddToBilling(
                                                              List.from(
                                                                billingItems,
                                                              ),
                                                              isDiscountApplied,
                                                              selectedOrderType,
                                                            ),
                                                          );
                                                    });
                                                  },
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 8,
                                                        ),
                                                    constraints:
                                                        const BoxConstraints(
                                                          minWidth: 70,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          selectedOrderType ==
                                                              OrderType.parcel
                                                          ? appPrimaryColor
                                                          : whiteColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            30,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        "Parcel",
                                                        style: MyTextStyle.f12(
                                                          selectedOrderType ==
                                                                  OrderType
                                                                      .parcel
                                                              ? whiteColor
                                                              : blackColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      selectedOrderType =
                                                          OrderType.ac;
                                                      if (widget
                                                              .isEditingOrder !=
                                                          true) {
                                                        selectedValue = null;
                                                        selectedValueWaiter =
                                                            null;
                                                        tableId = null;
                                                        waiterId = null;
                                                      }
                                                      isSplitPayment = false;
                                                      context
                                                          .read<
                                                            FoodCategoryBloc
                                                          >()
                                                          .add(
                                                            AddToBilling(
                                                              List.from(
                                                                billingItems,
                                                              ),
                                                              isDiscountApplied,
                                                              selectedOrderType,
                                                            ),
                                                          );
                                                    });
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 8,
                                                        ),
                                                    constraints:
                                                        const BoxConstraints(
                                                          minWidth: 70,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          selectedOrderType ==
                                                              OrderType.ac
                                                          ? appPrimaryColor
                                                          : whiteColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            30,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        "AC",
                                                        style: MyTextStyle.f12(
                                                          selectedOrderType ==
                                                                  OrderType.ac
                                                              ? whiteColor
                                                              : blackColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      selectedOrderType =
                                                          OrderType.hd;
                                                      if (widget
                                                              .isEditingOrder !=
                                                          true) {
                                                        selectedValue = null;
                                                        selectedValueWaiter =
                                                            null;
                                                        tableId = null;
                                                        waiterId = null;
                                                      }
                                                      isSplitPayment = false;
                                                      context
                                                          .read<
                                                            FoodCategoryBloc
                                                          >()
                                                          .add(
                                                            AddToBilling(
                                                              List.from(
                                                                billingItems,
                                                              ),
                                                              isDiscountApplied,
                                                              selectedOrderType,
                                                            ),
                                                          );
                                                    });
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 8,
                                                        ),
                                                    constraints:
                                                        const BoxConstraints(
                                                          minWidth: 70,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          selectedOrderType ==
                                                              OrderType.hd
                                                          ? appPrimaryColor
                                                          : whiteColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            30,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        "HD",
                                                        style: MyTextStyle.f12(
                                                          selectedOrderType ==
                                                                  OrderType.hd
                                                              ? whiteColor
                                                              : blackColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      selectedOrderType =
                                                          OrderType.swiggy;
                                                      if (widget
                                                              .isEditingOrder !=
                                                          true) {
                                                        selectedValue = null;
                                                        selectedValueWaiter =
                                                            null;
                                                        tableId = null;
                                                        waiterId = null;
                                                      }
                                                      isSplitPayment = false;
                                                      context
                                                          .read<
                                                            FoodCategoryBloc
                                                          >()
                                                          .add(
                                                            AddToBilling(
                                                              List.from(
                                                                billingItems,
                                                              ),
                                                              isDiscountApplied,
                                                              selectedOrderType,
                                                            ),
                                                          );
                                                    });
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 8,
                                                        ),
                                                    constraints:
                                                        const BoxConstraints(
                                                          minWidth: 70,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          selectedOrderType ==
                                                              OrderType.swiggy
                                                          ? appPrimaryColor
                                                          : whiteColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            30,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        "Swiggy",
                                                        style: MyTextStyle.f12(
                                                          selectedOrderType ==
                                                                  OrderType
                                                                      .swiggy
                                                              ? whiteColor
                                                              : blackColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Bills",
                                                style: MyTextStyle.f13(
                                                  blackColor,
                                                  weight: FontWeight.bold,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    billingItems.clear();
                                                    selectedValue = null;
                                                    selectedValueWaiter = null;
                                                    tableId = null;
                                                    waiterId = null;
                                                    selectedOrderType =
                                                        OrderType.line;
                                                    isCompleteOrder = false;
                                                    isSplitPayment = false;
                                                    selectedFullPaymentMethod =
                                                        "";
                                                    widget.isEditingOrder =
                                                        false;
                                                    balance = 0;
                                                    if (billingItems.isEmpty) {
                                                      isDiscountApplied = false;
                                                    }
                                                  });
                                                  context
                                                      .read<FoodCategoryBloc>()
                                                      .add(
                                                        AddToBilling(
                                                          List.from(
                                                            billingItems,
                                                          ),
                                                          isDiscountApplied,
                                                          selectedOrderType,
                                                        ),
                                                      );
                                                },
                                                icon: const Icon(Icons.refresh),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          if (selectedOrderType ==
                                                  OrderType.line ||
                                              selectedOrderType == OrderType.ac)
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          5.0,
                                                        ),
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
                                                    padding:
                                                        const EdgeInsets.all(
                                                          5.0,
                                                        ),
                                                    child: Text(
                                                      'Select Waiter',
                                                      style: MyTextStyle.f14(
                                                        blackColor,
                                                        weight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          if (selectedOrderType ==
                                                  OrderType.line ||
                                              selectedOrderType == OrderType.ac)
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    margin:
                                                        const EdgeInsets.all(5),
                                                    child: DropdownButtonFormField<String>(
                                                      value:
                                                          (getTableModel.data?.any(
                                                                (item) =>
                                                                    item.name ==
                                                                    selectedValue,
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
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          borderSide:
                                                              const BorderSide(
                                                                color:
                                                                    appPrimaryColor,
                                                              ),
                                                        ),
                                                      ),
                                                      items: getTableModel.data?.map((
                                                        item,
                                                      ) {
                                                        return DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: item.name,
                                                          child: Text(
                                                            "Table ${item.name}",
                                                            style:
                                                                MyTextStyle.f14(
                                                                  blackColor,
                                                                  weight:
                                                                      FontWeight
                                                                          .normal,
                                                                ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                      onChanged: (String? newValue) {
                                                        if (newValue != null) {
                                                          setState(() {
                                                            selectedValue =
                                                                newValue;
                                                            final selectedItem =
                                                                getTableModel
                                                                    .data
                                                                    ?.firstWhere(
                                                                      (item) =>
                                                                          item.name ==
                                                                          newValue,
                                                                    );
                                                            tableId =
                                                                selectedItem?.id
                                                                    .toString();
                                                          });
                                                        }
                                                      },
                                                      hint: Text(
                                                        '-- Select Table --',
                                                        style: MyTextStyle.f14(
                                                          blackColor,
                                                          weight:
                                                              FontWeight.normal,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Container(
                                                    margin:
                                                        const EdgeInsets.all(5),
                                                    child: DropdownButtonFormField<String>(
                                                      value:
                                                          (getWaiterModel.data?.any(
                                                                (item) =>
                                                                    item.name ==
                                                                    selectedValueWaiter,
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
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          borderSide:
                                                              const BorderSide(
                                                                color:
                                                                    appPrimaryColor,
                                                              ),
                                                        ),
                                                      ),
                                                      items: getWaiterModel.data?.map((
                                                        item,
                                                      ) {
                                                        return DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: item.name,
                                                          child: Text(
                                                            "${item.name}",
                                                            style:
                                                                MyTextStyle.f14(
                                                                  blackColor,
                                                                  weight:
                                                                      FontWeight
                                                                          .normal,
                                                                ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                      onChanged: (String? newValue) {
                                                        if (newValue != null) {
                                                          setState(() {
                                                            selectedValueWaiter =
                                                                newValue;
                                                            final selectedItem =
                                                                getWaiterModel
                                                                    .data
                                                                    ?.firstWhere(
                                                                      (item) =>
                                                                          item.name ==
                                                                          newValue,
                                                                    );
                                                            waiterId =
                                                                selectedItem?.id
                                                                    .toString();
                                                            debugPrint(
                                                              "waitername:$selectedValueWaiter",
                                                            );
                                                            debugPrint(
                                                              "waiterId:$waiterId",
                                                            );
                                                          });
                                                        }
                                                      },
                                                      hint: Text(
                                                        '-- Select Waiter --',
                                                        style: MyTextStyle.f14(
                                                          blackColor,
                                                          weight:
                                                              FontWeight.normal,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          Divider(),
                                          Column(
                                            children: postAddToBillingModel.items!.map((
                                              e,
                                            ) {
                                              final paidQty =
                                                  widget
                                                      .existingOrder
                                                      ?.data
                                                      ?.items
                                                      ?.firstWhereOrNull(
                                                        (item) =>
                                                            item.product?.id ==
                                                            e.id,
                                                      )
                                                      ?.quantity ??
                                                  0;

                                              final currentQty =
                                                  billingItems.firstWhere(
                                                    (item) =>
                                                        item['_id'] == e.id,
                                                    orElse: () =>
                                                        <String, dynamic>{
                                                          'qty': 0,
                                                        },
                                                  )['qty'] ??
                                                  0;

                                              final availableQty =
                                                  e.availableQuantity ?? 0;

                                              bool canAddMore;

                                              if (e.isStock == true) {
                                                if ((widget.isEditingOrder ==
                                                            true &&
                                                        widget
                                                                .existingOrder
                                                                ?.data
                                                                ?.orderStatus ==
                                                            "COMPLETED") ||
                                                    (widget.isEditingOrder ==
                                                            true &&
                                                        widget
                                                                .existingOrder
                                                                ?.data
                                                                ?.orderStatus ==
                                                            "WAITLIST")) {
                                                  canAddMore =
                                                      currentQty <
                                                      (availableQty + paidQty);
                                                } else {
                                                  canAddMore =
                                                      currentQty < availableQty;
                                                }
                                              } else {
                                                canAddMore = true;
                                              }

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8.0,
                                                    ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10.0,
                                                          ),
                                                      child: CachedNetworkImage(
                                                        imageUrl: e.image ?? "",
                                                        width:
                                                            size.width * 0.15,
                                                        height:
                                                            size.height * 0.07,
                                                        fit: BoxFit.cover,
                                                        errorWidget:
                                                            (
                                                              context,
                                                              url,
                                                              error,
                                                            ) {
                                                              return const Icon(
                                                                Icons.error,
                                                                size: 30,
                                                                color:
                                                                    appHomeTextColor,
                                                              );
                                                            },
                                                        progressIndicatorBuilder:
                                                            (
                                                              context,
                                                              url,
                                                              downloadProgress,
                                                            ) => const SpinKitCircle(
                                                              color:
                                                                  appPrimaryColor,
                                                              size: 30,
                                                            ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      "${e.name}",
                                                                      style: MyTextStyle.f14(
                                                                        blackColor,
                                                                        weight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      "x ${e.qty}",
                                                                      style: MyTextStyle.f12(
                                                                        blackColor,
                                                                        weight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                    e.isStock ==
                                                                            true
                                                                        ? Text(
                                                                            (widget.isEditingOrder ==
                                                                                        true &&
                                                                                    widget.existingOrder?.data?.orderStatus ==
                                                                                        "COMPLETED")
                                                                                ? "Available: $availableQty (+ $paidQty paid)"
                                                                                : "Available: $availableQty",
                                                                            style: MyTextStyle.f10(
                                                                              availableQty >
                                                                                      0
                                                                                  ? greyColor
                                                                                  : redColor,
                                                                              weight: FontWeight.w400,
                                                                            ),
                                                                          )
                                                                        : const SizedBox.shrink(),
                                                                  ],
                                                                ),
                                                              ),
                                                              Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  // Decrease button
                                                                  CircleAvatar(
                                                                    radius: 15,
                                                                    backgroundColor:
                                                                        greyColor200,
                                                                    child: IconButton(
                                                                      icon: const Icon(
                                                                        Icons
                                                                            .remove,
                                                                        size:
                                                                            15,
                                                                        color:
                                                                            blackColor,
                                                                      ),
                                                                      padding:
                                                                          EdgeInsets
                                                                              .zero,
                                                                      constraints:
                                                                          BoxConstraints(),
                                                                      onPressed: () {
                                                                        setState(() {
                                                                          isSplitPayment =
                                                                              false;
                                                                          if (widget.isEditingOrder !=
                                                                              true) {
                                                                            selectedOrderType =
                                                                                OrderType.line;
                                                                          }
                                                                          final index = billingItems.indexWhere(
                                                                            (
                                                                              item,
                                                                            ) =>
                                                                                item['_id'] ==
                                                                                e.id,
                                                                          );
                                                                          if (index !=
                                                                                  -1 &&
                                                                              billingItems[index]['qty'] >
                                                                                  1) {
                                                                            billingItems[index]['qty'] =
                                                                                billingItems[index]['qty'] -
                                                                                1;
                                                                            updateControllerText(
                                                                              e.id.toString(),
                                                                              billingItems[index]['qty'],
                                                                            );
                                                                          } else {
                                                                            billingItems.removeWhere(
                                                                              (
                                                                                item,
                                                                              ) =>
                                                                                  item['_id'] ==
                                                                                  e.id,
                                                                            );
                                                                            quantityControllers.remove(
                                                                              e.id.toString(),
                                                                            );
                                                                            if (billingItems.isEmpty ||
                                                                                billingItems ==
                                                                                    []) {
                                                                              isDiscountApplied = false;
                                                                              widget.isEditingOrder = false;
                                                                              tableId = null;
                                                                              waiterId = null;
                                                                              selectedValue = null;
                                                                              selectedValueWaiter = null;
                                                                            }
                                                                          }
                                                                          context
                                                                              .read<
                                                                                FoodCategoryBloc
                                                                              >()
                                                                              .add(
                                                                                AddToBilling(
                                                                                  List.from(
                                                                                    billingItems,
                                                                                  ),
                                                                                  isDiscountApplied,
                                                                                  selectedOrderType,
                                                                                ),
                                                                              );
                                                                        });
                                                                      },
                                                                    ),
                                                                  ),

                                                                  // TextField for quantity input
                                                                  Container(
                                                                    width: 45,
                                                                    height: 32,
                                                                    margin: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      border: Border.all(
                                                                        color:
                                                                            greyColor,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            4,
                                                                          ),
                                                                    ),
                                                                    child: TextField(
                                                                      controller: getOrCreateController(
                                                                        e.id.toString(),
                                                                        e.qty?.toInt() ??
                                                                            0,
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      keyboardType:
                                                                          TextInputType
                                                                              .number,
                                                                      style: MyTextStyle.f16(
                                                                        blackColor,
                                                                      ),
                                                                      decoration: const InputDecoration(
                                                                        border:
                                                                            InputBorder.none,
                                                                        isDense:
                                                                            true,
                                                                        contentPadding:
                                                                            EdgeInsets.all(
                                                                              8,
                                                                            ),
                                                                      ),
                                                                      onChanged: (value) {
                                                                        final newQty =
                                                                            int.tryParse(
                                                                              value,
                                                                            );
                                                                        if (newQty !=
                                                                                null &&
                                                                            newQty >
                                                                                0) {
                                                                          bool
                                                                          canSetQuantity;
                                                                          if (e.isStock ==
                                                                              true) {
                                                                            if ((widget.isEditingOrder ==
                                                                                        true &&
                                                                                    widget.existingOrder?.data?.orderStatus ==
                                                                                        "COMPLETED") ||
                                                                                (widget.isEditingOrder ==
                                                                                        true &&
                                                                                    widget.existingOrder?.data?.orderStatus ==
                                                                                        "WAITLIST")) {
                                                                              final paidQty =
                                                                                  widget.existingOrder?.data?.items
                                                                                      ?.firstWhereOrNull(
                                                                                        (
                                                                                          item,
                                                                                        ) =>
                                                                                            item.product?.id ==
                                                                                            e.id,
                                                                                      )
                                                                                      ?.quantity ??
                                                                                  0;
                                                                              canSetQuantity =
                                                                                  newQty <=
                                                                                  ((availableQty) +
                                                                                      paidQty);
                                                                            } else {
                                                                              canSetQuantity =
                                                                                  newQty <=
                                                                                  availableQty;
                                                                            }
                                                                          } else {
                                                                            canSetQuantity =
                                                                                true;
                                                                          }

                                                                          if (canSetQuantity) {
                                                                            setState(() {
                                                                              isSplitPayment = false;
                                                                              if (widget.isEditingOrder !=
                                                                                  true) {
                                                                                selectedOrderType = OrderType.line;
                                                                              }

                                                                              final index = billingItems.indexWhere(
                                                                                (
                                                                                  item,
                                                                                ) =>
                                                                                    item['_id'] ==
                                                                                    e.id,
                                                                              );
                                                                              if (index !=
                                                                                  -1) {
                                                                                billingItems[index]['qty'] = newQty;
                                                                              } else {
                                                                                // This shouldn't happen in cart, but keeping for safety
                                                                                billingItems.add(
                                                                                  {
                                                                                    "_id": e.id,
                                                                                    "basePrice": e.basePrice,
                                                                                    "image": e.image,
                                                                                    "qty": newQty,
                                                                                    "name": e.name,
                                                                                    "availableQuantity": e.availableQuantity,
                                                                                    "selectedAddons":
                                                                                        (e.selectedAddons !=
                                                                                            null)
                                                                                        ? e.selectedAddons!
                                                                                              .where(
                                                                                                (
                                                                                                  addon,
                                                                                                ) =>
                                                                                                    (addon.quantity ??
                                                                                                        0) >
                                                                                                    0,
                                                                                              )
                                                                                              .map(
                                                                                                (
                                                                                                  addon,
                                                                                                ) => {
                                                                                                  "_id": addon.id,
                                                                                                  "price":
                                                                                                      addon.price ??
                                                                                                      0,
                                                                                                  "quantity":
                                                                                                      addon.quantity ??
                                                                                                      0,
                                                                                                  "name": addon.name,
                                                                                                  "isAvailable": addon.isAvailable,
                                                                                                  "maxQuantity": addon.quantity,
                                                                                                  "isFree": addon.isFree,
                                                                                                },
                                                                                              )
                                                                                              .toList()
                                                                                        : [],
                                                                                  },
                                                                                );
                                                                              }
                                                                              context
                                                                                  .read<
                                                                                    FoodCategoryBloc
                                                                                  >()
                                                                                  .add(
                                                                                    AddToBilling(
                                                                                      List.from(
                                                                                        billingItems,
                                                                                      ),
                                                                                      isDiscountApplied,
                                                                                      selectedOrderType,
                                                                                    ),
                                                                                  );
                                                                            });
                                                                          } else {
                                                                            getOrCreateController(
                                                                              e.id.toString(),
                                                                              e.qty?.toInt() ??
                                                                                  0,
                                                                            ).text = getCurrentQuantity(
                                                                              e.id.toString(),
                                                                            ).toString();
                                                                            ScaffoldMessenger.of(
                                                                              context,
                                                                            ).showSnackBar(
                                                                              SnackBar(
                                                                                content: Text(
                                                                                  "Maximum available quantity is $availableQty",
                                                                                ),
                                                                              ),
                                                                            );
                                                                          }
                                                                        } else if (newQty ==
                                                                                0 ||
                                                                            value.isEmpty) {
                                                                          setState(() {
                                                                            billingItems.removeWhere(
                                                                              (
                                                                                item,
                                                                              ) =>
                                                                                  item['_id'] ==
                                                                                  e.id,
                                                                            );
                                                                            quantityControllers.remove(
                                                                              e.id.toString(),
                                                                            );
                                                                            if (billingItems.isEmpty ||
                                                                                billingItems ==
                                                                                    []) {
                                                                              isDiscountApplied = false;
                                                                              widget.isEditingOrder = false;
                                                                              tableId = null;
                                                                              waiterId = null;
                                                                              selectedValue = null;
                                                                              selectedValueWaiter = null;
                                                                            }
                                                                            context
                                                                                .read<
                                                                                  FoodCategoryBloc
                                                                                >()
                                                                                .add(
                                                                                  AddToBilling(
                                                                                    List.from(
                                                                                      billingItems,
                                                                                    ),
                                                                                    isDiscountApplied,
                                                                                    selectedOrderType,
                                                                                  ),
                                                                                );
                                                                          });
                                                                        }
                                                                      },
                                                                      onTap: () {
                                                                        final controller = getOrCreateController(
                                                                          e.id.toString(),
                                                                          e.qty?.toInt() ??
                                                                              0,
                                                                        );
                                                                        controller
                                                                            .selection = TextSelection(
                                                                          baseOffset:
                                                                              0,
                                                                          extentOffset: controller
                                                                              .text
                                                                              .length,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ),

                                                                  // Increase button
                                                                  Builder(
                                                                    builder: (context) {
                                                                      return CircleAvatar(
                                                                        radius:
                                                                            15,
                                                                        backgroundColor:
                                                                            canAddMore
                                                                            ? appPrimaryColor
                                                                            : greyColor,
                                                                        child: IconButton(
                                                                          icon: Icon(
                                                                            Icons.add,
                                                                            size:
                                                                                15,
                                                                            color:
                                                                                canAddMore
                                                                                ? whiteColor
                                                                                : blackColor,
                                                                          ),
                                                                          padding:
                                                                              EdgeInsets.zero,
                                                                          constraints:
                                                                              BoxConstraints(),
                                                                          onPressed:
                                                                              canAddMore
                                                                              ? () {
                                                                                  setState(
                                                                                    () {
                                                                                      final index = billingItems.indexWhere(
                                                                                        (
                                                                                          item,
                                                                                        ) =>
                                                                                            item['_id'] ==
                                                                                            e.id,
                                                                                      );
                                                                                      if (index !=
                                                                                          -1) {
                                                                                        billingItems[index]['qty'] =
                                                                                            billingItems[index]['qty'] +
                                                                                            1;
                                                                                        updateControllerText(
                                                                                          e.id.toString(),
                                                                                          billingItems[index]['qty'],
                                                                                        );
                                                                                      }
                                                                                      context
                                                                                          .read<
                                                                                            FoodCategoryBloc
                                                                                          >()
                                                                                          .add(
                                                                                            AddToBilling(
                                                                                              List.from(
                                                                                                billingItems,
                                                                                              ),
                                                                                              isDiscountApplied,
                                                                                              selectedOrderType,
                                                                                            ),
                                                                                          );
                                                                                    },
                                                                                  );
                                                                                }
                                                                              : () {
                                                                                  if (e.isStock ==
                                                                                          true &&
                                                                                      availableQty ==
                                                                                          0) {
                                                                                    ScaffoldMessenger.of(
                                                                                      context,
                                                                                    ).showSnackBar(
                                                                                      const SnackBar(
                                                                                        content: Text(
                                                                                          "Out of stock",
                                                                                        ),
                                                                                      ),
                                                                                    );
                                                                                  }
                                                                                },
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),

                                                                  // Keep your existing delete button
                                                                  IconButton(
                                                                    icon: Icon(
                                                                      Icons
                                                                          .delete,
                                                                      color:
                                                                          redColor,
                                                                      size: 20,
                                                                    ),
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                          4,
                                                                        ),
                                                                    constraints:
                                                                        BoxConstraints(),
                                                                    onPressed: () {
                                                                      setState(() {
                                                                        billingItems.removeWhere(
                                                                          (
                                                                            item,
                                                                          ) =>
                                                                              item['_id'] ==
                                                                              e.id,
                                                                        );
                                                                        quantityControllers.remove(
                                                                          e.id.toString(),
                                                                        );
                                                                        if (billingItems.isEmpty ||
                                                                            billingItems ==
                                                                                []) {
                                                                          isDiscountApplied =
                                                                              false;
                                                                          widget.isEditingOrder =
                                                                              false;
                                                                          tableId =
                                                                              null;
                                                                          waiterId =
                                                                              null;
                                                                          selectedValue =
                                                                              null;
                                                                          selectedValueWaiter =
                                                                              null;
                                                                        }
                                                                        context
                                                                            .read<
                                                                              FoodCategoryBloc
                                                                            >()
                                                                            .add(
                                                                              AddToBilling(
                                                                                List.from(
                                                                                  billingItems,
                                                                                ),
                                                                                isDiscountApplied,
                                                                                selectedOrderType,
                                                                              ),
                                                                            );
                                                                      });
                                                                    },
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                          if (!canAddMore) ...[
                                                            Container(
                                                              margin:
                                                                  EdgeInsets.only(
                                                                    top: 4,
                                                                  ),
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical: 4,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .orange
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      4,
                                                                    ),
                                                              ),
                                                              child:
                                                                  (widget.isEditingOrder ==
                                                                          true &&
                                                                      widget
                                                                              .existingOrder
                                                                              ?.data
                                                                              ?.orderStatus ==
                                                                          "WAITLIST")
                                                                  ? Text(
                                                                      'Maximum stock limit reached',
                                                                      style: MyTextStyle.f10(
                                                                        orangeColor,
                                                                        weight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    )
                                                                  : Text(
                                                                      ((widget.isEditingOrder ==
                                                                                  true &&
                                                                              widget.existingOrder?.data?.orderStatus ==
                                                                                  "COMPLETED"))
                                                                          ? 'Maximum limit reached (Available: $availableQty + Paid: $paidQty)'
                                                                          : 'Maximum stock limit reached',
                                                                      style: MyTextStyle.f10(
                                                                        orangeColor,
                                                                        weight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                            ),
                                                          ],
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              if (e.selectedAddons !=
                                                                      null &&
                                                                  e
                                                                      .selectedAddons!
                                                                      .isNotEmpty)
                                                                ...e.selectedAddons!
                                                                    .where(
                                                                      (addon) =>
                                                                          addon.quantity !=
                                                                              null &&
                                                                          addon.quantity! >
                                                                              0,
                                                                    )
                                                                    .map((
                                                                      addon,
                                                                    ) {
                                                                      return Padding(
                                                                        padding: const EdgeInsets.symmetric(
                                                                          vertical:
                                                                              3,
                                                                        ),
                                                                        child: Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            Expanded(
                                                                              child: Text(
                                                                                "${addon.name} ${addon.isFree == true ? ' (Free)' : ' ₹${addon.price}'}",
                                                                                style: TextStyle(
                                                                                  fontSize: 12,
                                                                                  color: greyColor,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            Row(
                                                                              children: [
                                                                                IconButton(
                                                                                  icon: Icon(
                                                                                    Icons.remove_circle_outline,
                                                                                  ),
                                                                                  onPressed: () {
                                                                                    final currentItem = billingItems.firstWhere(
                                                                                      (
                                                                                        item,
                                                                                      ) =>
                                                                                          item['_id'] ==
                                                                                          e.id,
                                                                                    );
                                                                                    final addonsList =
                                                                                        currentItem['selectedAddons']
                                                                                            as List;
                                                                                    final addonIndex = addonsList.indexWhere(
                                                                                      (
                                                                                        a,
                                                                                      ) =>
                                                                                          a['_id'] ==
                                                                                          addon.id,
                                                                                    );

                                                                                    if (addonsList[addonIndex]['quantity'] >
                                                                                        1) {
                                                                                      setState(
                                                                                        () {
                                                                                          addonsList[addonIndex]['quantity'] =
                                                                                              addonsList[addonIndex]['quantity'] -
                                                                                              1;
                                                                                          if (billingItems.isEmpty ||
                                                                                              billingItems ==
                                                                                                  []) {
                                                                                            isDiscountApplied = false;
                                                                                            widget.isEditingOrder = false;
                                                                                            tableId = null;
                                                                                            waiterId = null;
                                                                                            selectedValue = null;
                                                                                            selectedValueWaiter = null;
                                                                                          }
                                                                                          context
                                                                                              .read<
                                                                                                FoodCategoryBloc
                                                                                              >()
                                                                                              .add(
                                                                                                AddToBilling(
                                                                                                  List.from(
                                                                                                    billingItems,
                                                                                                  ),
                                                                                                  isDiscountApplied,
                                                                                                  selectedOrderType,
                                                                                                ),
                                                                                              );
                                                                                        },
                                                                                      );
                                                                                    } else {
                                                                                      setState(
                                                                                        () {
                                                                                          addonsList.removeAt(
                                                                                            addonIndex,
                                                                                          );
                                                                                          if (billingItems.isEmpty ||
                                                                                              billingItems ==
                                                                                                  []) {
                                                                                            isDiscountApplied = false;
                                                                                            widget.isEditingOrder = false;
                                                                                            tableId = null;
                                                                                            waiterId = null;
                                                                                            selectedValue = null;
                                                                                            selectedValueWaiter = null;
                                                                                          }
                                                                                          context
                                                                                              .read<
                                                                                                FoodCategoryBloc
                                                                                              >()
                                                                                              .add(
                                                                                                AddToBilling(
                                                                                                  List.from(
                                                                                                    billingItems,
                                                                                                  ),
                                                                                                  isDiscountApplied,
                                                                                                  selectedOrderType,
                                                                                                ),
                                                                                              );
                                                                                        },
                                                                                      );
                                                                                    }
                                                                                  },
                                                                                ),
                                                                                Text(
                                                                                  '${addon.quantity}',
                                                                                  style: TextStyle(
                                                                                    fontSize: 14,
                                                                                  ),
                                                                                ),
                                                                                IconButton(
                                                                                  icon: Icon(
                                                                                    Icons.add_circle_outline,
                                                                                  ),
                                                                                  onPressed: () {
                                                                                    final currentItem = billingItems.firstWhere(
                                                                                      (
                                                                                        item,
                                                                                      ) =>
                                                                                          item['_id'] ==
                                                                                          e.id,
                                                                                    );
                                                                                    final addonsList =
                                                                                        currentItem['selectedAddons']
                                                                                            as List;
                                                                                    final addonIndex = addonsList.indexWhere(
                                                                                      (
                                                                                        a,
                                                                                      ) =>
                                                                                          a['_id'] ==
                                                                                          addon.id,
                                                                                    );

                                                                                    setState(
                                                                                      () {
                                                                                        addonsList[addonIndex]['quantity'] =
                                                                                            addonsList[addonIndex]['quantity'] +
                                                                                            1;
                                                                                        context
                                                                                            .read<
                                                                                              FoodCategoryBloc
                                                                                            >()
                                                                                            .add(
                                                                                              AddToBilling(
                                                                                                List.from(
                                                                                                  billingItems,
                                                                                                ),
                                                                                                isDiscountApplied,
                                                                                                selectedOrderType,
                                                                                              ),
                                                                                            );
                                                                                      },
                                                                                    );
                                                                                  },
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      );
                                                                    }),
                                                              price(
                                                                "Base Price",
                                                                isBold: true,
                                                                "₹ ${(e.basePrice! * e.qty!).toStringAsFixed(2)}",
                                                              ),
                                                              if (e.addonTotal !=
                                                                  0)
                                                                price(
                                                                  'Addons Total',
                                                                  isBold: true,
                                                                  "₹ ${e.addonTotal!.toStringAsFixed(2)}",
                                                                ),
                                                              price(
                                                                "Item Total",
                                                                "₹ ${(e.basePrice! * e.qty! + (e.addonTotal ?? 0)).toStringAsFixed(2)}",
                                                                isBold: true,
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                          Divider(
                                            color: greyColor200,
                                            thickness: 2,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Subtotal",
                                                style: MyTextStyle.f14(
                                                  greyColor,
                                                  weight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                "₹ ${postAddToBillingModel.subtotal}",
                                                style: MyTextStyle.f14(
                                                  greyColor,
                                                  weight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Total Tax",
                                                style: MyTextStyle.f14(
                                                  greyColor,
                                                ),
                                              ),
                                              Text(
                                                "₹ ${postAddToBillingModel.totalTax}",
                                                style: MyTextStyle.f14(
                                                  greyColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          const Divider(thickness: 1),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Total",
                                                style: MyTextStyle.f18(
                                                  blackColor,
                                                  weight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                "₹ ${postAddToBillingModel.total!.toStringAsFixed(2)}",
                                                style: MyTextStyle.f18(
                                                  blackColor,
                                                  weight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(thickness: 1),
                                          SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Current Payment Amount",
                                                style: MyTextStyle.f14(
                                                  blackColor,
                                                  weight: FontWeight.w400,
                                                ),
                                              ),
                                              Text(
                                                "₹ ${postAddToBillingModel.total!.toStringAsFixed(2)}",
                                                style: MyTextStyle.f14(
                                                  blackColor,
                                                  weight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (isCompleteOrder == false)
                                            SizedBox(height: 12),
                                          if (isCompleteOrder == false &&
                                              (widget.isEditingOrder == null ||
                                                  widget.isEditingOrder ==
                                                      false))
                                            Text(
                                              "Save order to waitlist or complete with payment.",
                                              style: MyTextStyle.f14(
                                                greyColor,
                                                weight: FontWeight.w400,
                                              ),
                                            ),
                                          if (widget.isEditingOrder == true &&
                                              widget
                                                      .existingOrder
                                                      ?.data
                                                      ?.orderStatus ==
                                                  "COMPLETED") ...[
                                            if (balance > 0) ...[
                                              Text(
                                                "Additional payment of ₹${balance.toStringAsFixed(2)} required.",
                                                style: MyTextStyle.f14(
                                                  redColor,
                                                  weight: FontWeight.bold,
                                                ),
                                              ),
                                            ] else if (balance < 0) ...[
                                              Text(
                                                "₹${(balance * -1).toStringAsFixed(2)} will be refunded or adjusted.",
                                                style: MyTextStyle.f14(
                                                  Colors.green,
                                                  weight: FontWeight.bold,
                                                ),
                                              ),
                                            ] else ...[
                                              Text(
                                                "Order already paid. No additional payment required unless items are added",
                                                style: MyTextStyle.f14(
                                                  greyColor,
                                                  weight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ],
                                          if ((isCompleteOrder == true &&
                                                  postAddToBillingModel.total !=
                                                      widget
                                                          .existingOrder
                                                          ?.data!
                                                          .total &&
                                                  widget.isEditingOrder ==
                                                      true &&
                                                  widget
                                                          .existingOrder
                                                          ?.data!
                                                          .orderStatus ==
                                                      "COMPLETED") ||
                                              ((widget.isEditingOrder ==
                                                          false ||
                                                      widget.isEditingOrder ==
                                                          null) &&
                                                  isCompleteOrder == true) ||
                                              (isCompleteOrder == true &&
                                                  widget.isEditingOrder ==
                                                      true &&
                                                  widget
                                                          .existingOrder
                                                          ?.data!
                                                          .orderStatus ==
                                                      "WAITLIST"))
                                            Container(
                                              margin: const EdgeInsets.only(
                                                top: 15,
                                              ),
                                              decoration: BoxDecoration(
                                                color: greyColor200,
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          splitChange = false;
                                                          isSplitPayment =
                                                              false;
                                                        });
                                                      },
                                                      child: Container(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              vertical: 8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: isSplitPayment
                                                              ? greyColor200
                                                              : appPrimaryColor,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                30,
                                                              ),
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            "Full Payment",
                                                            style: MyTextStyle.f12(
                                                              isSplitPayment
                                                                  ? blackColor
                                                                  : whiteColor,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          isSplitPayment = true;
                                                          selectedFullPaymentMethod =
                                                              "";
                                                          _paymentFieldCount =
                                                              1;
                                                          splitAmountControllers = [
                                                            TextEditingController(),
                                                          ];
                                                          selectedPaymentMethods =
                                                              [null];
                                                          totalSplit = 0.0;
                                                        });
                                                      },
                                                      child: Container(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              vertical: 8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: isSplitPayment
                                                              ? appPrimaryColor
                                                              : greyColor200,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                30,
                                                              ),
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            "Split Payment",
                                                            style: MyTextStyle.f12(
                                                              isSplitPayment
                                                                  ? whiteColor
                                                                  : blackColor,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          if ((isCompleteOrder == true &&
                                                  postAddToBillingModel.total !=
                                                      widget
                                                          .existingOrder
                                                          ?.data!
                                                          .total &&
                                                  widget.isEditingOrder ==
                                                      true &&
                                                  widget
                                                          .existingOrder
                                                          ?.data!
                                                          .orderStatus ==
                                                      "COMPLETED") ||
                                              ((widget.isEditingOrder ==
                                                          false ||
                                                      widget.isEditingOrder ==
                                                          null) &&
                                                  isCompleteOrder == true) ||
                                              (isCompleteOrder == true &&
                                                  widget.isEditingOrder ==
                                                      true &&
                                                  widget
                                                          .existingOrder
                                                          ?.data!
                                                          .orderStatus ==
                                                      "WAITLIST"))
                                            !isSplitPayment
                                                ? Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      SizedBox(height: 12),
                                                      Text(
                                                        "Payment Method",
                                                        style: MyTextStyle.f14(
                                                          blackColor,
                                                          weight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      SizedBox(height: 12),
                                                      SingleChildScrollView(
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        child: Wrap(
                                                          spacing: 12,
                                                          runSpacing: 12,
                                                          children: [
                                                            GestureDetector(
                                                              onTap: () {
                                                                setState(() {
                                                                  selectedFullPaymentMethod =
                                                                      "Cash";
                                                                });
                                                              },
                                                              child: PaymentOption(
                                                                icon:
                                                                    Icons.money,
                                                                label: "Cash",
                                                                selected:
                                                                    selectedFullPaymentMethod ==
                                                                    "Cash",
                                                              ),
                                                            ),
                                                            GestureDetector(
                                                              onTap: () {
                                                                setState(() {
                                                                  selectedFullPaymentMethod =
                                                                      "Card";
                                                                });
                                                              },
                                                              child: PaymentOption(
                                                                icon: Icons
                                                                    .credit_card,
                                                                label: "Card",
                                                                selected:
                                                                    selectedFullPaymentMethod ==
                                                                    "Card",
                                                              ),
                                                            ),
                                                            GestureDetector(
                                                              onTap: () {
                                                                setState(() {
                                                                  selectedFullPaymentMethod =
                                                                      "UPI";
                                                                });

                                                                if (getStockMaintanencesModel
                                                                            .data
                                                                            ?.image !=
                                                                        null &&
                                                                    getStockMaintanencesModel
                                                                        .data!
                                                                        .image!
                                                                        .isNotEmpty) {
                                                                  showDialog(
                                                                    context:
                                                                        context,
                                                                    builder: (context) {
                                                                      return AlertDialog(
                                                                        shape: RoundedRectangleBorder(
                                                                          borderRadius: BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                        ),
                                                                        title: const Text(
                                                                          "Scan to Pay",
                                                                        ),
                                                                        content: SizedBox(
                                                                          width:
                                                                              250,
                                                                          height:
                                                                              250,
                                                                          child: Image.network(
                                                                            getStockMaintanencesModel.data!.image!,
                                                                            fit:
                                                                                BoxFit.contain,
                                                                            errorBuilder:
                                                                                (
                                                                                  context,
                                                                                  error,
                                                                                  stackTrace,
                                                                                ) => const Text(
                                                                                  "Failed to load QR",
                                                                                ),
                                                                          ),
                                                                        ),
                                                                        actions: [
                                                                          TextButton(
                                                                            onPressed: () => Navigator.pop(
                                                                              context,
                                                                            ),
                                                                            child: const Text(
                                                                              "Close",
                                                                              style: TextStyle(
                                                                                color: appPrimaryColor,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      );
                                                                    },
                                                                  );
                                                                } else {
                                                                  showToast(
                                                                    "QR code not available",
                                                                    context,
                                                                    color:
                                                                        false,
                                                                  );
                                                                }
                                                              },
                                                              child: PaymentOption(
                                                                icon: Icons
                                                                    .qr_code,
                                                                label: "UPI",
                                                                selected:
                                                                    selectedFullPaymentMethod ==
                                                                    "UPI",
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : Container(),
                                          if ((isCompleteOrder == true &&
                                                  postAddToBillingModel.total !=
                                                      widget
                                                          .existingOrder
                                                          ?.data!
                                                          .total &&
                                                  widget.isEditingOrder ==
                                                      true &&
                                                  widget
                                                          .existingOrder
                                                          ?.data!
                                                          .orderStatus ==
                                                      "COMPLETED") ||
                                              ((widget.isEditingOrder ==
                                                          false ||
                                                      widget.isEditingOrder ==
                                                          null) &&
                                                  isCompleteOrder == true) ||
                                              (isCompleteOrder == true &&
                                                  widget.isEditingOrder ==
                                                      true &&
                                                  widget
                                                          .existingOrder
                                                          ?.data!
                                                          .orderStatus ==
                                                      "WAITLIST"))
                                            isSplitPayment
                                                ? Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      SizedBox(height: 20),
                                                      Text(
                                                        "Split Payment",
                                                        style: MyTextStyle.f20(
                                                          blackColor,
                                                          weight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      SizedBox(height: 20),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          for (
                                                            int i = 0;
                                                            i <
                                                                _paymentFieldCount;
                                                            i++
                                                          )
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical: 6,
                                                                  ),
                                                              child: Row(
                                                                children: [
                                                                  Expanded(
                                                                    child: DropdownButtonFormField<String>(
                                                                      value:
                                                                          selectedPaymentMethods[i],
                                                                      decoration: InputDecoration(
                                                                        labelText:
                                                                            "Select",
                                                                        labelStyle:
                                                                            MyTextStyle.f14(
                                                                              greyColor,
                                                                            ),
                                                                        filled:
                                                                            true,
                                                                        fillColor:
                                                                            whiteColor,
                                                                        enabledBorder: OutlineInputBorder(
                                                                          borderRadius: BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                          borderSide: BorderSide(
                                                                            color:
                                                                                appPrimaryColor,
                                                                            width:
                                                                                1.5,
                                                                          ),
                                                                        ),
                                                                        focusedBorder: OutlineInputBorder(
                                                                          borderRadius: BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                          borderSide: BorderSide(
                                                                            color:
                                                                                appPrimaryColor,
                                                                            width:
                                                                                2,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      dropdownColor:
                                                                          whiteColor,
                                                                      icon: Icon(
                                                                        Icons
                                                                            .keyboard_arrow_down_rounded,
                                                                        color:
                                                                            appPrimaryColor,
                                                                      ),
                                                                      style: MyTextStyle.f14(
                                                                        blackColor,
                                                                        weight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                      items: const [
                                                                        DropdownMenuItem(
                                                                          value:
                                                                              "Cash",
                                                                          child: Text(
                                                                            "Cash",
                                                                          ),
                                                                        ),
                                                                        DropdownMenuItem(
                                                                          value:
                                                                              "Card",
                                                                          child: Text(
                                                                            "Card",
                                                                          ),
                                                                        ),
                                                                        DropdownMenuItem(
                                                                          value:
                                                                              "UPI",
                                                                          child: Text(
                                                                            "UPI",
                                                                          ),
                                                                        ),
                                                                      ],
                                                                      onChanged: (value) {
                                                                        setState(() {
                                                                          selectedPaymentMethods[i] =
                                                                              value ??
                                                                              "";
                                                                        });
                                                                      },
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 10,
                                                                  ),
                                                                  Expanded(
                                                                    child: TextField(
                                                                      controller:
                                                                          splitAmountControllers[i],
                                                                      keyboardType:
                                                                          TextInputType
                                                                              .number,
                                                                      inputFormatters: [
                                                                        FilteringTextInputFormatter
                                                                            .digitsOnly,
                                                                      ],
                                                                      decoration: InputDecoration(
                                                                        hintText:
                                                                            "₹ Amount",
                                                                        filled:
                                                                            true,
                                                                        fillColor:
                                                                            whiteColor,
                                                                        enabledBorder: OutlineInputBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(
                                                                                8,
                                                                              ),
                                                                          borderSide: BorderSide(
                                                                            color:
                                                                                appPrimaryColor,
                                                                            width:
                                                                                1.5,
                                                                          ),
                                                                        ),
                                                                        focusedBorder: OutlineInputBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(
                                                                                8,
                                                                              ),
                                                                          borderSide: BorderSide(
                                                                            color:
                                                                                appPrimaryColor,
                                                                            width:
                                                                                2,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      onChanged: (value) {
                                                                        setState(() {
                                                                          splitChange =
                                                                              true;
                                                                          double
                                                                          total =
                                                                              0.0;
                                                                          for (var controller
                                                                              in splitAmountControllers) {
                                                                            total +=
                                                                                double.tryParse(
                                                                                  controller.text,
                                                                                ) ??
                                                                                0.0;
                                                                          }
                                                                          totalSplit =
                                                                              total;
                                                                        });
                                                                      },
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          Align(
                                                            alignment: Alignment
                                                                .centerLeft,
                                                            child: GestureDetector(
                                                              onTap:
                                                                  _paymentFieldCount <
                                                                      3
                                                                  ? addPaymentField
                                                                  : null,
                                                              child: Text(
                                                                _paymentFieldCount <
                                                                        3
                                                                    ? "+ Add Another Payment"
                                                                    : "",
                                                                style: TextStyle(
                                                                  decoration:
                                                                      _paymentFieldCount <
                                                                          3
                                                                      ? TextDecoration
                                                                            .underline
                                                                      : null,
                                                                  color:
                                                                      _paymentFieldCount <
                                                                          3
                                                                      ? appPrimaryColor
                                                                      : greyColor,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 12),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            "Total Split",
                                                            style:
                                                                MyTextStyle.f14(
                                                                  blackColor,
                                                                  weight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                          Text(
                                                            "₹ ${totalSplit.toStringAsFixed(2)}",
                                                            style:
                                                                MyTextStyle.f14(
                                                                  blackColor,
                                                                  weight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      if ((splitChange ==
                                                              true &&
                                                          totalSplit !=
                                                              postAddToBillingModel
                                                                  .total))
                                                        Text(
                                                          "Split payments must sum to ₹ ${widget.isEditingOrder == true && widget.existingOrder?.data!.orderStatus == "COMPLETED" ? (balance < 0 ? 0 : balance) : (postAddToBillingModel.total ?? 0).toDouble()}",
                                                          style:
                                                              MyTextStyle.f12(
                                                                redColor,
                                                                weight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                    ],
                                                  )
                                                : Container(),
                                          SizedBox(height: 12),
                                          !isSplitPayment
                                              ? Row(
                                                  children: [
                                                    selectedOrderType ==
                                                                OrderType
                                                                    .line ||
                                                            selectedOrderType ==
                                                                OrderType.ac
                                                        ? Expanded(
                                                            child: orderLoad
                                                                ? SpinKitCircle(
                                                                    color:
                                                                        appPrimaryColor,
                                                                    size: 30,
                                                                  )
                                                                : ElevatedButton(
                                                                    onPressed: () {
                                                                      if ((selectedValue ==
                                                                                  null &&
                                                                              selectedOrderType ==
                                                                                  OrderType.line) ||
                                                                          (selectedValue ==
                                                                                  null &&
                                                                              selectedOrderType ==
                                                                                  OrderType.ac)) {
                                                                        setState(() {
                                                                          isCompleteOrder =
                                                                              false;
                                                                        });
                                                                        showToast(
                                                                          "Table number is required for LINE/AC orders",
                                                                          context,
                                                                          color:
                                                                              false,
                                                                        );
                                                                        return;
                                                                      } else if ((selectedValueWaiter ==
                                                                                  null &&
                                                                              selectedOrderType ==
                                                                                  OrderType.line) ||
                                                                          (selectedValueWaiter ==
                                                                                  null &&
                                                                              selectedOrderType ==
                                                                                  OrderType.ac)) {
                                                                        setState(() {
                                                                          isCompleteOrder =
                                                                              false;
                                                                        });
                                                                        showToast(
                                                                          "Waiter name is required for LINE/AC orders",
                                                                          context,
                                                                          color:
                                                                              false,
                                                                        );
                                                                        return;
                                                                      } else if (((widget.isEditingOrder ==
                                                                                  null ||
                                                                              widget.isEditingOrder ==
                                                                                  false)) ||
                                                                          (widget.isEditingOrder ==
                                                                                  true &&
                                                                              (postAddToBillingModel.total !=
                                                                                      widget.existingOrder?.data!.total &&
                                                                                  widget.existingOrder?.data!.orderStatus ==
                                                                                      "WAITLIST"))) {
                                                                        setState(() {
                                                                          isCompleteOrder =
                                                                              false;
                                                                        });
                                                                        List<
                                                                          Map<
                                                                            String,
                                                                            dynamic
                                                                          >
                                                                        >
                                                                        payments = [
                                                                          {
                                                                            "amount":
                                                                                (postAddToBillingModel.total ??
                                                                                        0)
                                                                                    .toDouble(),
                                                                            "balanceAmount":
                                                                                0,
                                                                            "method":
                                                                                selectedFullPaymentMethod.toUpperCase(),
                                                                          },
                                                                        ];
                                                                        final orderPayload = buildOrderPayload(
                                                                          postAddToBillingModel:
                                                                              postAddToBillingModel,
                                                                          tableId:
                                                                              selectedOrderType ==
                                                                                      OrderType.line ||
                                                                                  selectedOrderType ==
                                                                                      OrderType.ac
                                                                              ? tableId
                                                                              : null,
                                                                          waiterId:
                                                                              selectedOrderType ==
                                                                                      OrderType.line ||
                                                                                  selectedOrderType ==
                                                                                      OrderType.ac
                                                                              ? waiterId
                                                                              : null,
                                                                          orderStatus:
                                                                              'WAITLIST',
                                                                          orderType:
                                                                              selectedOrderType ==
                                                                                  OrderType.line
                                                                              ? 'LINE'
                                                                              : selectedOrderType ==
                                                                                    OrderType.parcel
                                                                              ? 'PARCEL'
                                                                              : selectedOrderType ==
                                                                                    OrderType.ac
                                                                              ? "AC"
                                                                              : selectedOrderType ==
                                                                                    OrderType.hd
                                                                              ? "HD"
                                                                              : "SWIGGY",
                                                                          discountAmount: postAddToBillingModel
                                                                              .totalDiscount!
                                                                              .toStringAsFixed(
                                                                                2,
                                                                              ),
                                                                          isDiscountApplied:
                                                                              isDiscountApplied,
                                                                          tipAmount:
                                                                              tipController.text,
                                                                          payments:
                                                                              widget.isEditingOrder ==
                                                                                  true
                                                                              ? []
                                                                              : payments,
                                                                        );
                                                                        debugPrint(
                                                                          "payloadSave:${widget.existingOrder?.data!.id}",
                                                                        );
                                                                        debugPrint(
                                                                          "payloadSave:${jsonEncode(orderPayload)}",
                                                                        );
                                                                        setState(() {
                                                                          orderLoad =
                                                                              true;
                                                                        });
                                                                        if (widget.isEditingOrder ==
                                                                                true &&
                                                                            (postAddToBillingModel.total !=
                                                                                    widget.existingOrder?.data!.total &&
                                                                                widget.existingOrder?.data!.orderStatus ==
                                                                                    "WAITLIST")) {
                                                                          if (((selectedValue ==
                                                                                          null ||
                                                                                      selectedValue ==
                                                                                          'N/A') &&
                                                                                  selectedOrderType ==
                                                                                      OrderType.line) ||
                                                                              (selectedValue ==
                                                                                          null ||
                                                                                      selectedValue ==
                                                                                          'N/A') &&
                                                                                  selectedOrderType ==
                                                                                      OrderType.ac) {
                                                                            showToast(
                                                                              "Table number is required for LINE/AC orders",
                                                                              context,
                                                                              color: false,
                                                                            );
                                                                            setState(() {
                                                                              orderLoad = false;
                                                                            });
                                                                          } else if (((selectedValueWaiter ==
                                                                                          null ||
                                                                                      selectedValueWaiter ==
                                                                                          'N/A') &&
                                                                                  selectedOrderType ==
                                                                                      OrderType.line) ||
                                                                              (selectedValueWaiter ==
                                                                                          null ||
                                                                                      selectedValueWaiter ==
                                                                                          'N/A') &&
                                                                                  selectedOrderType ==
                                                                                      OrderType.ac) {
                                                                            showToast(
                                                                              "Waiter name is required for LINE/AC orders",
                                                                              context,
                                                                              color: false,
                                                                            );
                                                                            setState(() {
                                                                              orderLoad = false;
                                                                            });
                                                                          } else {
                                                                            setState(() {
                                                                              isCompleteOrder = false;
                                                                            });
                                                                            context
                                                                                .read<
                                                                                  FoodCategoryBloc
                                                                                >()
                                                                                .add(
                                                                                  UpdateOrder(
                                                                                    jsonEncode(
                                                                                      orderPayload,
                                                                                    ),
                                                                                    widget.existingOrder?.data!.id,
                                                                                  ),
                                                                                );
                                                                          }
                                                                        } else {
                                                                          setState(
                                                                            () {
                                                                              isCompleteOrder = false;
                                                                            },
                                                                          );
                                                                          context
                                                                              .read<
                                                                                FoodCategoryBloc
                                                                              >()
                                                                              .add(
                                                                                GenerateOrder(
                                                                                  jsonEncode(
                                                                                    orderPayload,
                                                                                  ),
                                                                                ),
                                                                              );
                                                                        }
                                                                      }
                                                                    },
                                                                    style: ElevatedButton.styleFrom(
                                                                      backgroundColor:
                                                                          (widget.isEditingOrder ==
                                                                                      null ||
                                                                                  widget.isEditingOrder ==
                                                                                      false) ||
                                                                              (widget.isEditingOrder ==
                                                                                      true &&
                                                                                  (postAddToBillingModel.total !=
                                                                                          widget.existingOrder?.data!.total &&
                                                                                      widget.existingOrder?.data!.orderStatus ==
                                                                                          "WAITLIST"))
                                                                          ? appPrimaryColor
                                                                          : greyColor,
                                                                      minimumSize:
                                                                          const Size(
                                                                            0,
                                                                            50,
                                                                          ), // Height only
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              30,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                    child: Text(
                                                                      "Save Order",
                                                                      style: TextStyle(
                                                                        color:
                                                                            (widget.isEditingOrder ==
                                                                                        null ||
                                                                                    widget.isEditingOrder ==
                                                                                        false) ||
                                                                                (widget.isEditingOrder ==
                                                                                        true &&
                                                                                    (postAddToBillingModel.total !=
                                                                                            widget.existingOrder?.data!.total &&
                                                                                        widget.existingOrder?.data!.orderStatus ==
                                                                                            "WAITLIST"))
                                                                            ? whiteColor
                                                                            : blackColor,
                                                                      ),
                                                                    ),
                                                                  ),
                                                          )
                                                        : Container(),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: completeLoad
                                                          ? SpinKitCircle(
                                                              color:
                                                                  appPrimaryColor,
                                                              size: 30,
                                                            )
                                                          : ElevatedButton(
                                                              onPressed: () {
                                                                /* Full payment */
                                                                if ((selectedValue ==
                                                                            null &&
                                                                        selectedOrderType ==
                                                                            OrderType.line) ||
                                                                    (selectedValue ==
                                                                            null &&
                                                                        selectedOrderType ==
                                                                            OrderType.ac)) {
                                                                  showToast(
                                                                    "Table number is required for LINE/AC orders",
                                                                    context,
                                                                    color:
                                                                        false,
                                                                  );
                                                                } else if ((selectedValueWaiter ==
                                                                            null &&
                                                                        selectedOrderType ==
                                                                            OrderType.line) ||
                                                                    (selectedValueWaiter ==
                                                                            null &&
                                                                        selectedOrderType ==
                                                                            OrderType.ac)) {
                                                                  showToast(
                                                                    "Waiter name is required for LINE/AC orders",
                                                                    context,
                                                                    color:
                                                                        false,
                                                                  );
                                                                } else {
                                                                  if ((widget.isEditingOrder ==
                                                                              false ||
                                                                          widget.isEditingOrder ==
                                                                              null) ||
                                                                      (widget.isEditingOrder ==
                                                                              true &&
                                                                          widget.existingOrder?.data!.orderStatus ==
                                                                              "WAITLIST")) {
                                                                    setState(() {
                                                                      isCompleteOrder =
                                                                          true;
                                                                    });
                                                                    if (selectedFullPaymentMethod
                                                                            .isEmpty ||
                                                                        (selectedFullPaymentMethod !=
                                                                                "Cash" &&
                                                                            selectedFullPaymentMethod !=
                                                                                "Card" &&
                                                                            selectedFullPaymentMethod !=
                                                                                "UPI")) {
                                                                      showToast(
                                                                        "Select any one of the payment method",
                                                                        context,
                                                                        color:
                                                                            false,
                                                                      );
                                                                      return;
                                                                    }
                                                                    if (selectedFullPaymentMethod ==
                                                                            "Cash" ||
                                                                        selectedFullPaymentMethod ==
                                                                            "Card" ||
                                                                        selectedFullPaymentMethod ==
                                                                            "UPI") {
                                                                      List<
                                                                        Map<
                                                                          String,
                                                                          dynamic
                                                                        >
                                                                      >
                                                                      payments =
                                                                          [];
                                                                      payments = [
                                                                        {
                                                                          "amount":
                                                                              (postAddToBillingModel.total ??
                                                                                      0)
                                                                                  .toDouble(),
                                                                          "balanceAmount":
                                                                              0,
                                                                          "method":
                                                                              selectedFullPaymentMethod.toUpperCase(),
                                                                        },
                                                                      ];
                                                                      final orderPayload = buildOrderPayload(
                                                                        postAddToBillingModel:
                                                                            postAddToBillingModel,
                                                                        tableId:
                                                                            selectedOrderType ==
                                                                                    OrderType.line ||
                                                                                selectedOrderType ==
                                                                                    OrderType.ac
                                                                            ? tableId
                                                                            : null,
                                                                        waiterId:
                                                                            selectedOrderType ==
                                                                                    OrderType.line ||
                                                                                selectedOrderType ==
                                                                                    OrderType.ac
                                                                            ? waiterId
                                                                            : null,
                                                                        orderStatus:
                                                                            'COMPLETED',
                                                                        orderType:
                                                                            selectedOrderType ==
                                                                                OrderType.line
                                                                            ? 'LINE'
                                                                            : selectedOrderType ==
                                                                                  OrderType.parcel
                                                                            ? 'PARCEL'
                                                                            : selectedOrderType ==
                                                                                  OrderType.ac
                                                                            ? "AC"
                                                                            : selectedOrderType ==
                                                                                  OrderType.hd
                                                                            ? "HD"
                                                                            : "SWIGGY",
                                                                        discountAmount: postAddToBillingModel
                                                                            .totalDiscount!
                                                                            .toStringAsFixed(
                                                                              2,
                                                                            ),
                                                                        isDiscountApplied:
                                                                            isDiscountApplied,
                                                                        tipAmount:
                                                                            tipController.text,
                                                                        payments:
                                                                            payments,
                                                                      );
                                                                      debugPrint(
                                                                        "payloadComplete:${widget.existingOrder?.data!.id}",
                                                                      );
                                                                      debugPrint(
                                                                        "payloadComplete:${jsonEncode(orderPayload)}",
                                                                      );
                                                                      setState(() {
                                                                        completeLoad =
                                                                            true;
                                                                      });
                                                                      if ((widget.isEditingOrder ==
                                                                              true &&
                                                                          widget.existingOrder?.data!.orderStatus ==
                                                                              "WAITLIST")) {
                                                                        context
                                                                            .read<
                                                                              FoodCategoryBloc
                                                                            >()
                                                                            .add(
                                                                              UpdateOrder(
                                                                                jsonEncode(
                                                                                  orderPayload,
                                                                                ),
                                                                                widget.existingOrder!.data!.id,
                                                                              ),
                                                                            );
                                                                      } else {
                                                                        context
                                                                            .read<
                                                                              FoodCategoryBloc
                                                                            >()
                                                                            .add(
                                                                              GenerateOrder(
                                                                                jsonEncode(
                                                                                  orderPayload,
                                                                                ),
                                                                              ),
                                                                            );
                                                                      }
                                                                    }
                                                                  }
                                                                  if ((widget.isEditingOrder ==
                                                                          true &&
                                                                      (postAddToBillingModel.total !=
                                                                              widget.existingOrder?.data!.total &&
                                                                          widget.existingOrder?.data!.orderStatus ==
                                                                              "COMPLETED"))) {
                                                                    if (balance <
                                                                        0) {
                                                                      setState(() {
                                                                        isCompleteOrder =
                                                                            false;
                                                                      });
                                                                      List<
                                                                        Map<
                                                                          String,
                                                                          dynamic
                                                                        >
                                                                      >
                                                                      payments =
                                                                          [];
                                                                      debugPrint(
                                                                        "payment<0:$payments",
                                                                      );
                                                                      final orderPayload = buildOrderPayload(
                                                                        postAddToBillingModel:
                                                                            postAddToBillingModel,
                                                                        tableId:
                                                                            selectedOrderType ==
                                                                                    OrderType.line ||
                                                                                selectedOrderType ==
                                                                                    OrderType.ac
                                                                            ? tableId
                                                                            : null,
                                                                        waiterId:
                                                                            selectedOrderType ==
                                                                                    OrderType.line ||
                                                                                selectedOrderType ==
                                                                                    OrderType.ac
                                                                            ? waiterId
                                                                            : null,
                                                                        orderStatus:
                                                                            'COMPLETED',
                                                                        orderType:
                                                                            selectedOrderType ==
                                                                                OrderType.line
                                                                            ? 'LINE'
                                                                            : selectedOrderType ==
                                                                                  OrderType.parcel
                                                                            ? 'PARCEL'
                                                                            : selectedOrderType ==
                                                                                  OrderType.ac
                                                                            ? "AC"
                                                                            : selectedOrderType ==
                                                                                  OrderType.hd
                                                                            ? "HD"
                                                                            : "SWIGGY",
                                                                        discountAmount: postAddToBillingModel
                                                                            .totalDiscount!
                                                                            .toStringAsFixed(
                                                                              2,
                                                                            ),
                                                                        isDiscountApplied:
                                                                            isDiscountApplied,
                                                                        tipAmount:
                                                                            tipController.text,
                                                                        payments:
                                                                            payments,
                                                                      );
                                                                      debugPrint(
                                                                        "payloadComplete<0:${widget.existingOrder?.data!.id}",
                                                                      );
                                                                      debugPrint(
                                                                        "payloadComplete<0:${jsonEncode(orderPayload)}",
                                                                      );
                                                                      setState(() {
                                                                        completeLoad =
                                                                            true;
                                                                      });
                                                                      context
                                                                          .read<
                                                                            FoodCategoryBloc
                                                                          >()
                                                                          .add(
                                                                            UpdateOrder(
                                                                              jsonEncode(
                                                                                orderPayload,
                                                                              ),
                                                                              widget.existingOrder!.data!.id,
                                                                            ),
                                                                          );
                                                                      balance =
                                                                          0;
                                                                    }
                                                                    if (balance >=
                                                                        0) {
                                                                      setState(() {
                                                                        isCompleteOrder =
                                                                            true;
                                                                      });
                                                                      if (selectedFullPaymentMethod
                                                                              .isEmpty ||
                                                                          (selectedFullPaymentMethod !=
                                                                                  "Cash" &&
                                                                              selectedFullPaymentMethod !=
                                                                                  "Card" &&
                                                                              selectedFullPaymentMethod !=
                                                                                  "UPI")) {
                                                                        showToast(
                                                                          "Select any one of the payment method",
                                                                          context,
                                                                          color:
                                                                              false,
                                                                        );
                                                                        return;
                                                                      }
                                                                      if (selectedFullPaymentMethod ==
                                                                              "Cash" ||
                                                                          selectedFullPaymentMethod ==
                                                                              "Card" ||
                                                                          selectedFullPaymentMethod ==
                                                                              "UPI") {
                                                                        List<
                                                                          Map<
                                                                            String,
                                                                            dynamic
                                                                          >
                                                                        >
                                                                        payments =
                                                                            [];
                                                                        payments = [
                                                                          {
                                                                            "amount":
                                                                                widget.existingOrder?.data!.orderStatus ==
                                                                                    "COMPLETED"
                                                                                ? (balance <
                                                                                          0
                                                                                      ? 0
                                                                                      : balance)
                                                                                : (postAddToBillingModel.total ??
                                                                                          0)
                                                                                      .toDouble(),
                                                                            "balanceAmount":
                                                                                0,
                                                                            "method":
                                                                                selectedFullPaymentMethod.toUpperCase(),
                                                                          },
                                                                        ];
                                                                        debugPrint(
                                                                          "payment>=0:$payments",
                                                                        );
                                                                        final orderPayload = buildOrderPayload(
                                                                          postAddToBillingModel:
                                                                              postAddToBillingModel,
                                                                          tableId:
                                                                              selectedOrderType ==
                                                                                      OrderType.line ||
                                                                                  selectedOrderType ==
                                                                                      OrderType.ac
                                                                              ? tableId
                                                                              : null,
                                                                          waiterId:
                                                                              selectedOrderType ==
                                                                                      OrderType.line ||
                                                                                  selectedOrderType ==
                                                                                      OrderType.ac
                                                                              ? waiterId
                                                                              : null,
                                                                          orderStatus:
                                                                              'COMPLETED',
                                                                          orderType:
                                                                              selectedOrderType ==
                                                                                  OrderType.line
                                                                              ? 'LINE'
                                                                              : selectedOrderType ==
                                                                                    OrderType.parcel
                                                                              ? 'PARCEL'
                                                                              : selectedOrderType ==
                                                                                    OrderType.ac
                                                                              ? "AC"
                                                                              : selectedOrderType ==
                                                                                    OrderType.hd
                                                                              ? "HD"
                                                                              : "SWIGGY",
                                                                          discountAmount: postAddToBillingModel
                                                                              .totalDiscount!
                                                                              .toStringAsFixed(
                                                                                2,
                                                                              ),
                                                                          isDiscountApplied:
                                                                              isDiscountApplied,
                                                                          tipAmount:
                                                                              tipController.text,
                                                                          payments:
                                                                              payments,
                                                                        );
                                                                        debugPrint(
                                                                          "payloadComplete>=0:${widget.existingOrder?.data!.id}",
                                                                        );
                                                                        debugPrint(
                                                                          "payloadComplete>=0:${jsonEncode(orderPayload)}",
                                                                        );
                                                                        setState(() {
                                                                          completeLoad =
                                                                              true;
                                                                        });
                                                                        debugPrint(
                                                                          "editIdCompleted:${widget.existingOrder!.data!.id}",
                                                                        );
                                                                        context
                                                                            .read<
                                                                              FoodCategoryBloc
                                                                            >()
                                                                            .add(
                                                                              UpdateOrder(
                                                                                jsonEncode(
                                                                                  orderPayload,
                                                                                ),
                                                                                widget.existingOrder!.data!.id,
                                                                              ),
                                                                            );
                                                                        balance =
                                                                            0;
                                                                      }
                                                                    }
                                                                  }
                                                                }
                                                              },
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    appPrimaryColor,
                                                                minimumSize:
                                                                    const Size(
                                                                      0,
                                                                      50,
                                                                    ),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        30,
                                                                      ),
                                                                ),
                                                              ),
                                                              child: Text(
                                                                widget.isEditingOrder ==
                                                                            true &&
                                                                        widget.existingOrder?.data!.orderStatus ==
                                                                            "COMPLETED"
                                                                    ? "Update Order"
                                                                    : "Complete Order",
                                                                style: TextStyle(
                                                                  color:
                                                                      whiteColor,
                                                                ),
                                                              ),
                                                            ),
                                                    ),
                                                  ],
                                                )
                                              : completeLoad
                                              ? SpinKitCircle(
                                                  color: appPrimaryColor,
                                                  size: 30,
                                                )
                                              : ElevatedButton(
                                                  onPressed: () {
                                                    if (!allSplitAmountsFilled() ||
                                                        !allPaymentMethodsSelected()) {
                                                      showToast(
                                                        "Please complete payment method and amount fields",
                                                        context,
                                                        color: false,
                                                      );
                                                      return;
                                                    }

                                                    if ((widget.isEditingOrder !=
                                                            true &&
                                                        totalSplit !=
                                                            postAddToBillingModel
                                                                .total)) {
                                                      showToast(
                                                        "Split payments must sum to ₹ ${widget.isEditingOrder == true && widget.existingOrder?.data!.orderStatus == "COMPLETED" ? (balance < 0 ? 0 : balance) : (postAddToBillingModel.total ?? 0).toDouble()}",
                                                        context,
                                                        color: false,
                                                      );
                                                      return;
                                                    }

                                                    if ((selectedValue ==
                                                                null &&
                                                            selectedOrderType ==
                                                                OrderType
                                                                    .line) ||
                                                        (selectedValue ==
                                                                null &&
                                                            selectedOrderType ==
                                                                OrderType.ac)) {
                                                      showToast(
                                                        "Table number is required for LINE/AC orders",
                                                        context,
                                                        color: false,
                                                      );
                                                      return;
                                                    }
                                                    if ((selectedValueWaiter ==
                                                                null &&
                                                            selectedOrderType ==
                                                                OrderType
                                                                    .line) ||
                                                        (selectedValueWaiter ==
                                                                null &&
                                                            selectedOrderType ==
                                                                OrderType.ac)) {
                                                      showToast(
                                                        "Waiter name is required for LINE/AC orders",
                                                        context,
                                                        color: false,
                                                      );
                                                      return;
                                                    }
                                                    List<Map<String, dynamic>>
                                                    payments = [];
                                                    if ((widget.isEditingOrder ==
                                                                false ||
                                                            widget.isEditingOrder ==
                                                                null) ||
                                                        (widget.isEditingOrder ==
                                                                true &&
                                                            widget
                                                                    .existingOrder
                                                                    ?.data!
                                                                    .orderStatus ==
                                                                "WAITLIST")) {
                                                      if (isSplitPayment) {
                                                        for (
                                                          int i = 0;
                                                          i < _paymentFieldCount;
                                                          i++
                                                        ) {
                                                          final method =
                                                              selectedPaymentMethods[i];
                                                          final amountText =
                                                              splitAmountControllers[i]
                                                                  .text;
                                                          final amount =
                                                              double.tryParse(
                                                                amountText,
                                                              ) ??
                                                              0;
                                                          if (method == null ||
                                                              method.isEmpty) {
                                                            showToast(
                                                              "Please select a payment method for split #${i + 1}",
                                                              context,
                                                              color: false,
                                                            );
                                                            return;
                                                          }

                                                          payments.add({
                                                            "amount": amount,
                                                            "balanceAmount": 0,
                                                            "method": method
                                                                .toUpperCase(),
                                                          });
                                                        }
                                                      }
                                                      final orderPayload = buildOrderPayload(
                                                        postAddToBillingModel:
                                                            postAddToBillingModel,
                                                        tableId:
                                                            selectedOrderType ==
                                                                    OrderType
                                                                        .line ||
                                                                selectedOrderType ==
                                                                    OrderType.ac
                                                            ? tableId
                                                            : null,
                                                        waiterId:
                                                            selectedOrderType ==
                                                                    OrderType
                                                                        .line ||
                                                                selectedOrderType ==
                                                                    OrderType.ac
                                                            ? waiterId
                                                            : null,
                                                        orderStatus:
                                                            'COMPLETED',
                                                        orderType:
                                                            selectedOrderType ==
                                                                OrderType.line
                                                            ? 'LINE'
                                                            : selectedOrderType ==
                                                                  OrderType
                                                                      .parcel
                                                            ? 'PARCEL'
                                                            : selectedOrderType ==
                                                                  OrderType.ac
                                                            ? "AC"
                                                            : selectedOrderType ==
                                                                  OrderType.hd
                                                            ? "HD"
                                                            : "SWIGGY",
                                                        discountAmount:
                                                            postAddToBillingModel
                                                                .totalDiscount!
                                                                .toStringAsFixed(
                                                                  2,
                                                                ),
                                                        isDiscountApplied:
                                                            isDiscountApplied,
                                                        tipAmount:
                                                            tipController.text,
                                                        payments: payments,
                                                      );
                                                      setState(() {
                                                        completeLoad = true;
                                                      });
                                                      if ((widget.isEditingOrder ==
                                                              true &&
                                                          widget
                                                                  .existingOrder
                                                                  ?.data!
                                                                  .orderStatus ==
                                                              "WAITLIST")) {
                                                        context
                                                            .read<
                                                              FoodCategoryBloc
                                                            >()
                                                            .add(
                                                              UpdateOrder(
                                                                jsonEncode(
                                                                  orderPayload,
                                                                ),
                                                                widget
                                                                    .existingOrder!
                                                                    .data!
                                                                    .id,
                                                              ),
                                                            );
                                                      } else {
                                                        context
                                                            .read<
                                                              FoodCategoryBloc
                                                            >()
                                                            .add(
                                                              GenerateOrder(
                                                                jsonEncode(
                                                                  orderPayload,
                                                                ),
                                                              ),
                                                            );
                                                      }
                                                    }
                                                    if ((widget.isEditingOrder ==
                                                            true &&
                                                        (postAddToBillingModel
                                                                    .total !=
                                                                widget
                                                                    .existingOrder
                                                                    ?.data!
                                                                    .total &&
                                                            widget
                                                                    .existingOrder
                                                                    ?.data!
                                                                    .orderStatus ==
                                                                "COMPLETED"))) {
                                                      if (balance < 0) {
                                                        if (isSplitPayment) {
                                                          for (
                                                            int i = 0;
                                                            i <
                                                                _paymentFieldCount;
                                                            i++
                                                          ) {
                                                            final method =
                                                                selectedPaymentMethods[i];
                                                            final amountText =
                                                                splitAmountControllers[i]
                                                                    .text;
                                                            final amount =
                                                                double.tryParse(
                                                                  amountText,
                                                                ) ??
                                                                0;
                                                            if (method ==
                                                                    null ||
                                                                method
                                                                    .isEmpty) {
                                                              showToast(
                                                                "Please select a payment method for split #${i + 1}",
                                                                context,
                                                                color: false,
                                                              );
                                                              return;
                                                            }
                                                          }
                                                        }

                                                        final orderPayload = buildOrderPayload(
                                                          postAddToBillingModel:
                                                              postAddToBillingModel,
                                                          tableId:
                                                              selectedOrderType ==
                                                                      OrderType
                                                                          .line ||
                                                                  selectedOrderType ==
                                                                      OrderType
                                                                          .ac
                                                              ? tableId
                                                              : null,
                                                          waiterId:
                                                              selectedOrderType ==
                                                                      OrderType
                                                                          .line ||
                                                                  selectedOrderType ==
                                                                      OrderType
                                                                          .ac
                                                              ? waiterId
                                                              : null,
                                                          orderStatus:
                                                              'COMPLETED',
                                                          orderType:
                                                              selectedOrderType ==
                                                                  OrderType.line
                                                              ? 'LINE'
                                                              : selectedOrderType ==
                                                                    OrderType
                                                                        .parcel
                                                              ? 'PARCEL'
                                                              : selectedOrderType ==
                                                                    OrderType.ac
                                                              ? "AC"
                                                              : selectedOrderType ==
                                                                    OrderType.hd
                                                              ? "HD"
                                                              : "SWIGGY",
                                                          discountAmount:
                                                              postAddToBillingModel
                                                                  .totalDiscount!
                                                                  .toStringAsFixed(
                                                                    2,
                                                                  ),
                                                          isDiscountApplied:
                                                              isDiscountApplied,
                                                          tipAmount:
                                                              tipController
                                                                  .text,
                                                          payments: payments,
                                                        );
                                                        setState(() {
                                                          completeLoad = true;
                                                        });
                                                        context
                                                            .read<
                                                              FoodCategoryBloc
                                                            >()
                                                            .add(
                                                              UpdateOrder(
                                                                jsonEncode(
                                                                  orderPayload,
                                                                ),
                                                                widget
                                                                    .existingOrder!
                                                                    .data!
                                                                    .id,
                                                              ),
                                                            );
                                                        balance = 0;
                                                      }
                                                      if (balance >= 0) {
                                                        if (isSplitPayment) {
                                                          for (
                                                            int i = 0;
                                                            i <
                                                                _paymentFieldCount;
                                                            i++
                                                          ) {
                                                            final method =
                                                                selectedPaymentMethods[i];
                                                            final amountText =
                                                                splitAmountControllers[i]
                                                                    .text;
                                                            final amount =
                                                                double.tryParse(
                                                                  amountText,
                                                                ) ??
                                                                0;
                                                            if (method ==
                                                                    null ||
                                                                method
                                                                    .isEmpty) {
                                                              showToast(
                                                                "Please select a payment method for split #${i + 1}",
                                                                context,
                                                                color: false,
                                                              );
                                                              return;
                                                            }
                                                            if (widget.isEditingOrder ==
                                                                    true &&
                                                                widget
                                                                        .existingOrder!
                                                                        .data!
                                                                        .orderStatus ==
                                                                    "COMPLETED" &&
                                                                balance !=
                                                                    amount) {
                                                              showToast(
                                                                "Amount not matching",
                                                                context,
                                                                color: false,
                                                              );
                                                              return;
                                                            }

                                                            payments.add({
                                                              "amount":
                                                                  widget
                                                                          .existingOrder
                                                                          ?.data!
                                                                          .orderStatus ==
                                                                      "COMPLETED"
                                                                  ? (balance < 0
                                                                        ? 0
                                                                        : balance)
                                                                  : amount,
                                                              "balanceAmount":
                                                                  0,
                                                              "method": method
                                                                  .toUpperCase(),
                                                            });
                                                          }
                                                        }
                                                        final orderPayload = buildOrderPayload(
                                                          postAddToBillingModel:
                                                              postAddToBillingModel,
                                                          tableId:
                                                              selectedOrderType ==
                                                                      OrderType
                                                                          .line ||
                                                                  selectedOrderType ==
                                                                      OrderType
                                                                          .ac
                                                              ? tableId
                                                              : null,
                                                          waiterId:
                                                              selectedOrderType ==
                                                                      OrderType
                                                                          .line ||
                                                                  selectedOrderType ==
                                                                      OrderType
                                                                          .ac
                                                              ? waiterId
                                                              : null,
                                                          orderStatus:
                                                              'COMPLETED',
                                                          orderType:
                                                              selectedOrderType ==
                                                                  OrderType.line
                                                              ? 'LINE'
                                                              : selectedOrderType ==
                                                                    OrderType
                                                                        .parcel
                                                              ? 'PARCEL'
                                                              : selectedOrderType ==
                                                                    OrderType.ac
                                                              ? "AC"
                                                              : selectedOrderType ==
                                                                    OrderType.hd
                                                              ? "HD"
                                                              : "SWIGGY",
                                                          discountAmount:
                                                              postAddToBillingModel
                                                                  .totalDiscount!
                                                                  .toStringAsFixed(
                                                                    2,
                                                                  ),
                                                          isDiscountApplied:
                                                              isDiscountApplied,
                                                          tipAmount:
                                                              tipController
                                                                  .text,
                                                          payments: payments,
                                                        );
                                                        setState(() {
                                                          completeLoad = true;
                                                        });
                                                        context
                                                            .read<
                                                              FoodCategoryBloc
                                                            >()
                                                            .add(
                                                              UpdateOrder(
                                                                jsonEncode(
                                                                  orderPayload,
                                                                ),
                                                                widget
                                                                    .existingOrder!
                                                                    .data!
                                                                    .id,
                                                              ),
                                                            );
                                                        balance = 0;
                                                      }
                                                    }
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        (allSplitAmountsFilled() &&
                                                                allPaymentMethodsSelected() &&
                                                                totalSplit ==
                                                                    postAddToBillingModel
                                                                        .total) ||
                                                            (widget.isEditingOrder ==
                                                                    true &&
                                                                widget
                                                                        .existingOrder
                                                                        ?.data!
                                                                        .orderStatus ==
                                                                    "COMPLETED")
                                                        ? appPrimaryColor
                                                        : greyColor,
                                                    minimumSize: Size(
                                                      double.infinity,
                                                      50,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            30,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    "Print Bills",
                                                    style: TextStyle(
                                                      color: whiteColor,
                                                    ),
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          tabletBuilder: (context, constraints) {
            return Text(
              "No Courses found !!!",
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
          backgroundColor: whiteColor,
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
                      "Ramanas",
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
      body: BlocBuilder<FoodCategoryBloc, dynamic>(
        buildWhen: ((previous, current) {
          if (current is GetCategoryModel) {
            getCategoryModel = current;
            if (getCategoryModel.success == true) {
              setState(() {
                categoryLoad = false;
              });
            }
            if (getCategoryModel.errorResponse?.isUnauthorized == true) {
              _handle401Error();
              return true;
            }
            return true;
          }
          if (current is GetProductByCatIdModel) {
            getProductByCatIdModel = current;
            if (getProductByCatIdModel.errorResponse?.isUnauthorized == true) {
              _handle401Error();
              return true;
            }
            if (getProductByCatIdModel.success == true) {
              setState(() {
                categoryLoad = false;
              });
            }
            return true;
          }
          if (current is PostAddToBillingModel) {
            postAddToBillingModel = current;
            if (postAddToBillingModel.errorResponse?.isUnauthorized == true) {
              _handle401Error();
              return true;
            }
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
                categoryLoad = false;
              });
            } else {
              setState(() {
                categoryLoad = false;
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
                categoryLoad = false;
              });
            } else {
              setState(() {
                categoryLoad = false;
              });
              showToast("No Waiter found", context, color: false);
            }
            return true;
          }
          if (current is GetStockMaintanencesModel) {
            getStockMaintanencesModel = current;
            if (getStockMaintanencesModel.errorResponse?.isUnauthorized ==
                true) {
              _handle401Error();
              return true;
            }
            if (getStockMaintanencesModel.success == true) {
              setState(() {
                categoryLoad = false;
              });
            } else {
              setState(() {
                categoryLoad = false;
              });
              showToast("No Stock found", context, color: false);
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
