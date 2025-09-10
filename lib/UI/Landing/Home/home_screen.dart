import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ramanas_waiter/Alertbox/AlertDialogBox.dart';
import 'package:ramanas_waiter/Alertbox/snackBarAlert.dart';
import 'package:ramanas_waiter/Bloc/Category/category_bloc.dart';
import 'package:ramanas_waiter/Bloc/demo/demo_bloc.dart';
import 'package:ramanas_waiter/ModelClass/HomeScreen/Category&Product/Get_category_model.dart';
import 'package:ramanas_waiter/ModelClass/HomeScreen/Category&Product/Get_product_by_catId_model.dart';
import 'package:ramanas_waiter/Reusable/color.dart';
import 'package:ramanas_waiter/Reusable/image.dart';
import 'package:ramanas_waiter/Reusable/responsive.dart';
import 'package:ramanas_waiter/Reusable/space.dart';
import 'package:ramanas_waiter/Reusable/text_styles.dart';
import 'package:ramanas_waiter/UI/Authentication/login_screen.dart';
import 'package:ramanas_waiter/UI/Landing/Home/Widget/category_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatelessWidget {
  final from;
  const HomePage({super.key, this.from});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FoodCategoryBloc(),
      child: HomePageView(from: from),
    );
  }
}

class HomePageView extends StatefulWidget {
  final from;
  const HomePageView({super.key, this.from});

  @override
  HomePageViewState createState() => HomePageViewState();
}

class HomePageViewState extends State<HomePageView> {
  GetCategoryModel getCategoryModel = GetCategoryModel();
  GetProductByCatIdModel getProductByCatIdModel = GetProductByCatIdModel();
  // PostAddToBillingModel postAddToBillingModel = PostAddToBillingModel();
  TextEditingController searchController = TextEditingController();
  TextEditingController searchCodeController = TextEditingController();
  Map<String, TextEditingController> quantityControllers = {};
  String selectedCategory = "All";
  String? selectedCatId = "";

  String? errorMessage;
  bool categoryLoad = false;

  int counter = 0;
  List<Map<String, dynamic>> billingItems = [];

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
    categoryLoad = true;
  }

  @override
  void dispose() {
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

      // double total = (postAddToBillingModel.total ?? 0).toDouble();
      // double paidAmount = (widget.existingOrder?.data?.total ?? 0).toDouble();
      // balance = total - paidAmount;

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

      // int getCurrentQuantity(String itemId) {
      //   final item = billingItems.firstWhereOrNull(
      //     (item) => item['_id'].toString() == itemId,
      //   );
      //   return item?['qty'] ?? 0;
      // }

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
                                                  separatorBuilder: (_, __) =>
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
                                                                                                // if ((widget.isEditingOrder == true && widget.existingOrder?.data?.orderStatus == "COMPLETED") || (widget.isEditingOrder == true && widget.existingOrder?.data?.orderStatus == "WAITLIST")) {
                                                                                                //   final paidQty = widget.existingOrder?.data?.items?.firstWhereOrNull((item) => item.product?.id == p.id)?.quantity ?? 0;
                                                                                                //   canAdd = currentQtyInCart < ((p.availableQuantity ?? 0) + paidQty);
                                                                                                // } else {
                                                                                                //   canAdd = currentQtyInCart < (p.availableQuantity ?? 0);
                                                                                                // }
                                                                                              } else {
                                                                                                canAdd = true;
                                                                                              }

                                                                                              // if (!canAdd) {
                                                                                              //   showToast("Cannot add more items. Stock limit reached.", context, color: false);
                                                                                              //   return;
                                                                                              // }

                                                                                              setState(
                                                                                                () {
                                                                                                  // isSplitPayment = false;
                                                                                                  // if (widget.isEditingOrder != true) {
                                                                                                  //   selectedOrderType = OrderType.line;
                                                                                                  // }
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
                                                                                                  // context.read<FoodCategoryBloc>().add(AddToBilling(List.from(billingItems), isDiscountApplied, selectedOrderType));

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
                                                              //   if ((widget.isEditingOrder ==
                                                              //       true &&
                                                              //       widget.existingOrder?.data
                                                              //           ?.orderStatus ==
                                                              //           "COMPLETED") ||
                                                              //       (widget.isEditingOrder ==
                                                              //           true &&
                                                              //           widget.existingOrder?.data
                                                              //               ?.orderStatus ==
                                                              //               "WAITLIST")) {
                                                              //     final paidQty = widget
                                                              //         .existingOrder
                                                              //         ?.data
                                                              //         ?.items
                                                              //         ?.firstWhereOrNull((item) =>
                                                              //     item.product?.id ==
                                                              //         p.id)
                                                              //         ?.quantity ??
                                                              //         0;
                                                              //     canAdd = currentQtyInCart <
                                                              //         ((p.availableQuantity ??
                                                              //             0) +
                                                              //             paidQty);
                                                              //   } else {
                                                              //     canAdd =
                                                              //         currentQtyInCart <
                                                              //             (p.availableQuantity ??
                                                              //                 0);
                                                              //   }
                                                              // } else {
                                                              //   canAdd = true;
                                                              // }
                                                              //
                                                              // if (!canAdd) {
                                                              //   showToast(
                                                              //       "Cannot add more items. Stock limit reached.",
                                                              //       context,
                                                              //       color: false);
                                                              //   return;
                                                              // }
                                                              //
                                                              // setState(() {
                                                              //   isSplitPayment =
                                                              //   false;
                                                              //   if (widget
                                                              //       .isEditingOrder !=
                                                              //       true) {
                                                              //     selectedOrderType =
                                                              //         OrderType
                                                              //             .line;
                                                              //   }
                                                              //   final index = billingItems
                                                              //       .indexWhere(
                                                              //           (item) =>
                                                              //       item[
                                                              //       '_id'] ==
                                                              //           p.id);
                                                              //   if (index != -1) {
                                                              //     billingItems[
                                                              //     index][
                                                              //     'qty'] = billingItems[
                                                              //     index]
                                                              //     [
                                                              //     'qty'] +
                                                              //         1;
                                                              //     updateControllerText(
                                                              //         p.id
                                                              //             .toString(),
                                                              //         billingItems[
                                                              //         index]
                                                              //         [
                                                              //         'qty']);
                                                              //   } else {
                                                              billingItems.add({
                                                                "_id": p.id,
                                                                "basePrice":
                                                                    p.basePrice,
                                                                "image":
                                                                    p.image,
                                                                "qty": 1,
                                                                "name": p.name,
                                                                "availableQuantity":
                                                                    p.availableQuantity,
                                                                "selectedAddons": p
                                                                    .addons!
                                                                    .where(
                                                                      (addon) =>
                                                                          addon
                                                                              .quantity >
                                                                          0,
                                                                    )
                                                                    .map(
                                                                      (
                                                                        addon,
                                                                      ) => {
                                                                        "_id": addon
                                                                            .id,
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
                                                            //   context
                                                            //       .read<
                                                            //       FoodCategoryBloc>()
                                                            //       .add(AddToBilling(
                                                            //       List.from(
                                                            //           billingItems),
                                                            //       isDiscountApplied,
                                                            //       selectedOrderType));
                                                            // });
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
                                                          child:
                                                              // Padding(
                                                              //         padding:
                                                              //             const EdgeInsets.all(
                                                              //               12,
                                                              //             ),
                                                              //         child:
                                                              Column(
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
                                                                  ),
                                                                  verticalSpace(
                                                                    height: 5,
                                                                  ),
                                                                  SizedBox(
                                                                    width:
                                                                        size.width *
                                                                        0.25,
                                                                    child: Text(
                                                                      p.name ??
                                                                          '',
                                                                      style: MyTextStyle.f13(
                                                                        blackColor,
                                                                        weight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                      maxLines:
                                                                          3,
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
                                                                                weight: FontWeight.w500,
                                                                              ),
                                                                              maxLines: 1,
                                                                              overflow: TextOverflow.ellipsis,
                                                                            ),
                                                                            Text(
                                                                              '${p.availableQuantity ?? 0}',
                                                                              style: MyTextStyle.f12(
                                                                                (p.availableQuantity ??
                                                                                            0) >
                                                                                        0
                                                                                    ? greyColor
                                                                                    : redColor,
                                                                                weight: FontWeight.w500,
                                                                              ),
                                                                              maxLines: 1,
                                                                              overflow: TextOverflow.ellipsis,
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
                                                                      padding: EdgeInsets.symmetric(
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
                                                                          weight:
                                                                              FontWeight.bold,
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
                                                                              TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  if (currentQuantity !=
                                                                          0 &&
                                                                      (p.availableQuantity ??
                                                                              0) >
                                                                          0)
                                                                    verticalSpace(
                                                                      height:
                                                                          10,
                                                                    ),
                                                                  if (currentQuantity !=
                                                                          0 &&
                                                                      (p.availableQuantity ??
                                                                              0) >
                                                                          0)
                                                                    Padding(
                                                                      padding: const EdgeInsets.only(
                                                                        left:
                                                                            5.0,
                                                                        right:
                                                                            5.0,
                                                                      ),
                                                                      child: Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.start,
                                                                        children: [
                                                                          Expanded(
                                                                            child: Text(
                                                                              '₹ ${p.basePrice}',
                                                                              style: MyTextStyle.f14(
                                                                                blackColor,
                                                                                weight: FontWeight.w600,
                                                                              ),
                                                                              maxLines: 1,
                                                                              overflow: TextOverflow.ellipsis,
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
                                                                                size: 15,
                                                                                color: blackColor,
                                                                              ),
                                                                              onPressed: () {
                                                                                // setState(() {
                                                                                //   isSplitPayment =
                                                                                //       false;
                                                                                //   if (widget.isEditingOrder !=
                                                                                //       true) {
                                                                                //     selectedOrderType =
                                                                                //         OrderType.line;
                                                                                //   }
                                                                                //   final index = billingItems.indexWhere(
                                                                                //     (
                                                                                //       item,
                                                                                //     ) =>
                                                                                //         item['_id'] ==
                                                                                //         p.id,
                                                                                //   );
                                                                                //   if (index !=
                                                                                //           -1 &&
                                                                                //       billingItems[index]['qty'] >
                                                                                //           1) {
                                                                                //     billingItems[index]['qty'] =
                                                                                //         billingItems[index]['qty'] -
                                                                                //         1;
                                                                                //     updateControllerText(
                                                                                //       p.id.toString(),
                                                                                //       billingItems[index]['qty'],
                                                                                //     );
                                                                                //   } else {
                                                                                //     billingItems.removeWhere(
                                                                                //       (
                                                                                //         item,
                                                                                //       ) =>
                                                                                //           item['_id'] ==
                                                                                //           p.id,
                                                                                //     );
                                                                                //     quantityControllers.remove(
                                                                                //       p.id,
                                                                                //     );
                                                                                //     if (billingItems.isEmpty ||
                                                                                //         billingItems ==
                                                                                //             []) {
                                                                                //       isDiscountApplied =
                                                                                //           false;
                                                                                //       widget.isEditingOrder =
                                                                                //           false;
                                                                                //       tableId =
                                                                                //           null;
                                                                                //       waiterId =
                                                                                //           null;
                                                                                //       selectedValue =
                                                                                //           null;
                                                                                //       selectedValueWaiter =
                                                                                //           null;
                                                                                //     }
                                                                                //   }
                                                                                //   context
                                                                                //       .read<
                                                                                //         FoodCategoryBloc
                                                                                //       >()
                                                                                //       .add(
                                                                                //         AddToBilling(
                                                                                //           List.from(
                                                                                //             billingItems,
                                                                                //           ),
                                                                                //           isDiscountApplied,
                                                                                //           selectedOrderType,
                                                                                //         ),
                                                                                //       );
                                                                                // });
                                                                              },
                                                                            ),
                                                                          ),
                                                                          Container(
                                                                            width:
                                                                                45,
                                                                            height:
                                                                                32,
                                                                            margin: const EdgeInsets.symmetric(
                                                                              horizontal: 12,
                                                                            ),
                                                                            decoration: BoxDecoration(
                                                                              border: Border.all(
                                                                                color: greyColor,
                                                                              ),
                                                                              borderRadius: BorderRadius.circular(
                                                                                4,
                                                                              ),
                                                                            ),
                                                                            child: TextField(
                                                                              controller: currentController,
                                                                              textAlign: TextAlign.center,
                                                                              keyboardType: TextInputType.number,
                                                                              style: MyTextStyle.f16(
                                                                                blackColor,
                                                                              ),
                                                                              decoration: const InputDecoration(
                                                                                border: InputBorder.none,
                                                                                isDense: true,
                                                                                contentPadding: EdgeInsets.all(
                                                                                  8,
                                                                                ),
                                                                              ),
                                                                              // onChanged: (value) {
                                                                              //   final newQty =
                                                                              //       int.tryParse(
                                                                              //         value,
                                                                              //       );
                                                                              //   if (newQty !=
                                                                              //           null &&
                                                                              //       newQty >
                                                                              //           0) {
                                                                              //     bool
                                                                              //     canSetQuantity;
                                                                              //     if (p.isStock ==
                                                                              //         true) {
                                                                              //       if ((widget.isEditingOrder ==
                                                                              //                   true &&
                                                                              //               widget.existingOrder?.data?.orderStatus ==
                                                                              //                   "COMPLETED") ||
                                                                              //           (widget.isEditingOrder ==
                                                                              //                   true &&
                                                                              //               widget.existingOrder?.data?.orderStatus ==
                                                                              //                   "WAITLIST")) {
                                                                              //         final paidQty =
                                                                              //             widget.existingOrder?.data?.items
                                                                              //                 ?.firstWhereOrNull(
                                                                              //                   (
                                                                              //                     item,
                                                                              //                   ) =>
                                                                              //                       item.product?.id ==
                                                                              //                       p.id,
                                                                              //                 )
                                                                              //                 ?.quantity ??
                                                                              //             0;
                                                                              //         canSetQuantity =
                                                                              //             newQty <=
                                                                              //             ((p.availableQuantity ??
                                                                              //                     0) +
                                                                              //                 paidQty);
                                                                              //       } else {
                                                                              //         canSetQuantity =
                                                                              //             newQty <=
                                                                              //             (p.availableQuantity ??
                                                                              //                 0);
                                                                              //       }
                                                                              //     } else {
                                                                              //       canSetQuantity =
                                                                              //           true;
                                                                              //     }
                                                                              //
                                                                              //     if (canSetQuantity) {
                                                                              //       setState(() {
                                                                              //         isSplitPayment =
                                                                              //             false;
                                                                              //         if (widget.isEditingOrder !=
                                                                              //             true) {
                                                                              //           selectedOrderType = OrderType.line;
                                                                              //         }
                                                                              //
                                                                              //         final index = billingItems.indexWhere(
                                                                              //           (
                                                                              //             item,
                                                                              //           ) =>
                                                                              //               item['_id'] ==
                                                                              //               p.id,
                                                                              //         );
                                                                              //         if (index !=
                                                                              //             -1) {
                                                                              //           billingItems[index]['qty'] = newQty;
                                                                              //         } else {
                                                                              //           billingItems.add(
                                                                              //             {
                                                                              //               "_id": p.id,
                                                                              //               "basePrice": p.basePrice,
                                                                              //               "image": p.image,
                                                                              //               "qty": newQty,
                                                                              //               "name": p.name,
                                                                              //               "availableQuantity": p.availableQuantity,
                                                                              //               "selectedAddons": p.addons!
                                                                              //                   .where(
                                                                              //                     (
                                                                              //                       addon,
                                                                              //                     ) =>
                                                                              //                         addon.quantity >
                                                                              //                         0,
                                                                              //                   )
                                                                              //                   .map(
                                                                              //                     (
                                                                              //                       addon,
                                                                              //                     ) => {
                                                                              //                       "_id": addon.id,
                                                                              //                       "price": addon.price,
                                                                              //                       "quantity": addon.quantity,
                                                                              //                       "name": addon.name,
                                                                              //                       "isAvailable": addon.isAvailable,
                                                                              //                       "maxQuantity": addon.maxQuantity,
                                                                              //                       "isFree": addon.isFree,
                                                                              //                     },
                                                                              //                   )
                                                                              //                   .toList(),
                                                                              //             },
                                                                              //           );
                                                                              //         }
                                                                              //         context
                                                                              //             .read<
                                                                              //               FoodCategoryBloc
                                                                              //             >()
                                                                              //             .add(
                                                                              //               AddToBilling(
                                                                              //                 List.from(
                                                                              //                   billingItems,
                                                                              //                 ),
                                                                              //                 isDiscountApplied,
                                                                              //                 selectedOrderType,
                                                                              //               ),
                                                                              //             );
                                                                              //       });
                                                                              //     } else {
                                                                              //       currentController
                                                                              //           .text = getCurrentQuantity(
                                                                              //         p.id.toString(),
                                                                              //       ).toString();
                                                                              //       ScaffoldMessenger.of(
                                                                              //         context,
                                                                              //       ).showSnackBar(
                                                                              //         SnackBar(
                                                                              //           content: Text(
                                                                              //             "Maximum available quantity is ${p.availableQuantity ?? 0}",
                                                                              //           ),
                                                                              //         ),
                                                                              //       );
                                                                              //     }
                                                                              //   } else if (newQty ==
                                                                              //           0 ||
                                                                              //       value
                                                                              //           .isEmpty) {
                                                                              //     setState(() {
                                                                              //       billingItems.removeWhere(
                                                                              //         (
                                                                              //           item,
                                                                              //         ) =>
                                                                              //             item['_id'] ==
                                                                              //             p.id,
                                                                              //       );
                                                                              //       quantityControllers.remove(
                                                                              //         p.id,
                                                                              //       );
                                                                              //       if (billingItems.isEmpty ||
                                                                              //           billingItems ==
                                                                              //               []) {
                                                                              //         isDiscountApplied =
                                                                              //             false;
                                                                              //         widget.isEditingOrder =
                                                                              //             false;
                                                                              //         tableId =
                                                                              //             null;
                                                                              //         waiterId =
                                                                              //             null;
                                                                              //         selectedValue =
                                                                              //             null;
                                                                              //         selectedValueWaiter =
                                                                              //             null;
                                                                              //       }
                                                                              //       context
                                                                              //           .read<
                                                                              //             FoodCategoryBloc
                                                                              //           >()
                                                                              //           .add(
                                                                              //             AddToBilling(
                                                                              //               List.from(
                                                                              //                 billingItems,
                                                                              //               ),
                                                                              //               isDiscountApplied,
                                                                              //               selectedOrderType,
                                                                              //             ),
                                                                              //           );
                                                                              //     });
                                                                              //   }
                                                                              // },
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
                                                                                  bool canAddMore;
                                                                                  // if (p.isStock ==
                                                                                  //     true) {
                                                                                  //   if ((widget.isEditingOrder ==
                                                                                  //               true &&
                                                                                  //           widget.existingOrder?.data?.orderStatus ==
                                                                                  //               "COMPLETED") ||
                                                                                  //       (widget.isEditingOrder ==
                                                                                  //               true &&
                                                                                  //           widget.existingOrder?.data?.orderStatus ==
                                                                                  //               "WAITLIST")) {
                                                                                  //     final paidQty =
                                                                                  //         widget.existingOrder?.data?.items
                                                                                  //             ?.firstWhereOrNull(
                                                                                  //               (
                                                                                  //                 item,
                                                                                  //               ) =>
                                                                                  //                   item.product?.id ==
                                                                                  //                   p.id,
                                                                                  //             )
                                                                                  //             ?.quantity ??
                                                                                  //         0;
                                                                                  //     canAddMore =
                                                                                  //         currentQtyInCart <
                                                                                  //         ((p.availableQuantity ??
                                                                                  //                 0) +
                                                                                  //             paidQty);
                                                                                  //   } else {
                                                                                  //     canAddMore =
                                                                                  //         (p.availableQuantity ??
                                                                                  //                 0) >
                                                                                  //             0 &&
                                                                                  //         currentQtyInCart <
                                                                                  //             (p.availableQuantity ??
                                                                                  //                 0);
                                                                                  //   }
                                                                                  // } else {
                                                                                  //   canAddMore =
                                                                                  //       true;
                                                                                  // }

                                                                                  return CircleAvatar(
                                                                                    radius: 15,
                                                                                    backgroundColor:
                                                                                        // canAddMore
                                                                                        // ? appPrimaryColor
                                                                                        //    :
                                                                                        greyColor,
                                                                                    child: IconButton(
                                                                                      icon: Icon(
                                                                                        Icons.add,
                                                                                        size: 16,
                                                                                        color:
                                                                                            // canAddMore
                                                                                            // ? whiteColor
                                                                                            // :
                                                                                            blackColor,
                                                                                      ),
                                                                                      onPressed: () {},
                                                                                      //     canAddMore
                                                                                      //     ? () {
                                                                                      //         setState(
                                                                                      //           () {
                                                                                      //             isSplitPayment = false;
                                                                                      //             if (widget.isEditingOrder !=
                                                                                      //                 true) {
                                                                                      //               selectedOrderType = OrderType.line;
                                                                                      //             }
                                                                                      //             final index = billingItems.indexWhere(
                                                                                      //               (
                                                                                      //                 item,
                                                                                      //               ) =>
                                                                                      //                   item['_id'] ==
                                                                                      //                   p.id,
                                                                                      //             );
                                                                                      //             if (index !=
                                                                                      //                 -1) {
                                                                                      //               billingItems[index]['qty'] =
                                                                                      //                   billingItems[index]['qty'] +
                                                                                      //                   1;
                                                                                      //               updateControllerText(
                                                                                      //                 p.id.toString(),
                                                                                      //                 billingItems[index]['qty'],
                                                                                      //               );
                                                                                      //             } else {
                                                                                      //               billingItems.add(
                                                                                      //                 {
                                                                                      //                   "_id": p.id,
                                                                                      //                   "basePrice": p.basePrice,
                                                                                      //                   "image": p.image,
                                                                                      //                   "qty": 1,
                                                                                      //                   "name": p.name,
                                                                                      //                   "availableQuantity": p.availableQuantity,
                                                                                      //                   "selectedAddons": p.addons!
                                                                                      //                       .where(
                                                                                      //                         (
                                                                                      //                           addon,
                                                                                      //                         ) =>
                                                                                      //                             addon.quantity >
                                                                                      //                             0,
                                                                                      //                       )
                                                                                      //                       .map(
                                                                                      //                         (
                                                                                      //                           addon,
                                                                                      //                         ) => {
                                                                                      //                           "_id": addon.id,
                                                                                      //                           "price": addon.price,
                                                                                      //                           "quantity": addon.quantity,
                                                                                      //                           "name": addon.name,
                                                                                      //                           "isAvailable": addon.isAvailable,
                                                                                      //                           "maxQuantity": addon.maxQuantity,
                                                                                      //                           "isFree": addon.isFree,
                                                                                      //                         },
                                                                                      //                       )
                                                                                      //                       .toList(),
                                                                                      //                 },
                                                                                      //               );
                                                                                      //               updateControllerText(
                                                                                      //                 p.id.toString(),
                                                                                      //                 1,
                                                                                      //               );
                                                                                      //             }
                                                                                      //             context
                                                                                      //                 .read<
                                                                                      //                   FoodCategoryBloc
                                                                                      //                 >()
                                                                                      //                 .add(
                                                                                      //                   AddToBilling(
                                                                                      //                     List.from(
                                                                                      //                       billingItems,
                                                                                      //                     ),
                                                                                      //                     isDiscountApplied,
                                                                                      //                     selectedOrderType,
                                                                                      //                   ),
                                                                                      //                 );
                                                                                      //           },
                                                                                      //         );
                                                                                      //       }
                                                                                      //     : () {
                                                                                      //         if (p.isStock ==
                                                                                      //                 true &&
                                                                                      //             (p.availableQuantity ??
                                                                                      //                     0) ==
                                                                                      //                 0) {
                                                                                      //           ScaffoldMessenger.of(
                                                                                      //             context,
                                                                                      //           ).showSnackBar(
                                                                                      //             const SnackBar(
                                                                                      //               content: Text(
                                                                                      //                 "Out of stock",
                                                                                      //               ),
                                                                                      //             ),
                                                                                      //           );
                                                                                      //         }
                                                                                      //       },
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
                                                                      height:
                                                                          10,
                                                                    ),
                                                                  if (currentQuantity !=
                                                                          0 &&
                                                                      p.isStock ==
                                                                          false)
                                                                    Padding(
                                                                      padding: const EdgeInsets.only(
                                                                        left:
                                                                            5.0,
                                                                        right:
                                                                            5.0,
                                                                      ),
                                                                      child: Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.start,
                                                                        children: [
                                                                          Expanded(
                                                                            child: Text(
                                                                              '₹ ${p.basePrice}',
                                                                              style: MyTextStyle.f14(
                                                                                blackColor,
                                                                                weight: FontWeight.w600,
                                                                              ),
                                                                              maxLines: 1,
                                                                              overflow: TextOverflow.ellipsis,
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
                                                                                size: 15,
                                                                                color: blackColor,
                                                                              ),
                                                                              onPressed: () {
                                                                                // setState(() {
                                                                                //   isSplitPayment =
                                                                                //       false;
                                                                                //   if (widget.isEditingOrder !=
                                                                                //       true) {
                                                                                //     selectedOrderType =
                                                                                //         OrderType.line;
                                                                                //   }
                                                                                //   final index = billingItems.indexWhere(
                                                                                //     (
                                                                                //       item,
                                                                                //     ) =>
                                                                                //         item['_id'] ==
                                                                                //         p.id,
                                                                                //   );
                                                                                //   if (index !=
                                                                                //           -1 &&
                                                                                //       billingItems[index]['qty'] >
                                                                                //           1) {
                                                                                //     billingItems[index]['qty'] =
                                                                                //         billingItems[index]['qty'] -
                                                                                //         1;
                                                                                //     updateControllerText(
                                                                                //       p.id.toString(),
                                                                                //       billingItems[index]['qty'],
                                                                                //     );
                                                                                //   } else {
                                                                                //     billingItems.removeWhere(
                                                                                //       (
                                                                                //         item,
                                                                                //       ) =>
                                                                                //           item['_id'] ==
                                                                                //           p.id,
                                                                                //     );
                                                                                //     quantityControllers.remove(
                                                                                //       p.id,
                                                                                //     );
                                                                                //     if (billingItems.isEmpty ||
                                                                                //         billingItems ==
                                                                                //             []) {
                                                                                //       isDiscountApplied =
                                                                                //           false;
                                                                                //       widget.isEditingOrder =
                                                                                //           false;
                                                                                //       tableId =
                                                                                //           null;
                                                                                //       waiterId =
                                                                                //           null;
                                                                                //       selectedValue =
                                                                                //           null;
                                                                                //       selectedValueWaiter =
                                                                                //           null;
                                                                                //     }
                                                                                //   }
                                                                                //   context
                                                                                //       .read<
                                                                                //         FoodCategoryBloc
                                                                                //       >()
                                                                                //       .add(
                                                                                //         AddToBilling(
                                                                                //           List.from(
                                                                                //             billingItems,
                                                                                //           ),
                                                                                //           isDiscountApplied,
                                                                                //           selectedOrderType,
                                                                                //         ),
                                                                                //       );
                                                                                // });
                                                                              },
                                                                            ),
                                                                          ),
                                                                          Container(
                                                                            width:
                                                                                45,
                                                                            height:
                                                                                32,
                                                                            margin: const EdgeInsets.symmetric(
                                                                              horizontal: 12,
                                                                            ),
                                                                            decoration: BoxDecoration(
                                                                              border: Border.all(
                                                                                color: greyColor,
                                                                              ),
                                                                              borderRadius: BorderRadius.circular(
                                                                                4,
                                                                              ),
                                                                            ),
                                                                            child: TextField(
                                                                              controller: currentController,
                                                                              textAlign: TextAlign.center,
                                                                              keyboardType: TextInputType.number,
                                                                              style: MyTextStyle.f16(
                                                                                blackColor,
                                                                              ),
                                                                              decoration: const InputDecoration(
                                                                                border: InputBorder.none,
                                                                                isDense: true,
                                                                                contentPadding: EdgeInsets.all(
                                                                                  8,
                                                                                ),
                                                                              ),
                                                                              // onChanged: (value) {
                                                                              //   final newQty =
                                                                              //       int.tryParse(
                                                                              //         value,
                                                                              //       );
                                                                              //   if (newQty !=
                                                                              //           null &&
                                                                              //       newQty >
                                                                              //           0) {
                                                                              //     bool
                                                                              //     canSetQuantity;
                                                                              //     if (p.isStock ==
                                                                              //         true) {
                                                                              //       if ((widget.isEditingOrder ==
                                                                              //                   true &&
                                                                              //               widget.existingOrder?.data?.orderStatus ==
                                                                              //                   "COMPLETED") ||
                                                                              //           (widget.isEditingOrder ==
                                                                              //                   true &&
                                                                              //               widget.existingOrder?.data?.orderStatus ==
                                                                              //                   "WAITLIST")) {
                                                                              //         final paidQty =
                                                                              //             widget.existingOrder?.data?.items
                                                                              //                 ?.firstWhereOrNull(
                                                                              //                   (
                                                                              //                     item,
                                                                              //                   ) =>
                                                                              //                       item.product?.id ==
                                                                              //                       p.id,
                                                                              //                 )
                                                                              //                 ?.quantity ??
                                                                              //             0;
                                                                              //         canSetQuantity =
                                                                              //             newQty <=
                                                                              //             ((p.availableQuantity ??
                                                                              //                     0) +
                                                                              //                 paidQty);
                                                                              //       } else {
                                                                              //         canSetQuantity =
                                                                              //             newQty <=
                                                                              //             (p.availableQuantity ??
                                                                              //                 0);
                                                                              //       }
                                                                              //     } else {
                                                                              //       canSetQuantity =
                                                                              //           true;
                                                                              //     }
                                                                              //
                                                                              //     if (canSetQuantity) {
                                                                              //       setState(() {
                                                                              //         isSplitPayment =
                                                                              //             false;
                                                                              //         if (widget.isEditingOrder !=
                                                                              //             true) {
                                                                              //           selectedOrderType = OrderType.line;
                                                                              //         }
                                                                              //
                                                                              //         final index = billingItems.indexWhere(
                                                                              //           (
                                                                              //             item,
                                                                              //           ) =>
                                                                              //               item['_id'] ==
                                                                              //               p.id,
                                                                              //         );
                                                                              //         if (index !=
                                                                              //             -1) {
                                                                              //           billingItems[index]['qty'] = newQty;
                                                                              //         } else {
                                                                              //           billingItems.add(
                                                                              //             {
                                                                              //               "_id": p.id,
                                                                              //               "basePrice": p.basePrice,
                                                                              //               "image": p.image,
                                                                              //               "qty": newQty,
                                                                              //               "name": p.name,
                                                                              //               "availableQuantity": p.availableQuantity,
                                                                              //               "selectedAddons": p.addons!
                                                                              //                   .where(
                                                                              //                     (
                                                                              //                       addon,
                                                                              //                     ) =>
                                                                              //                         addon.quantity >
                                                                              //                         0,
                                                                              //                   )
                                                                              //                   .map(
                                                                              //                     (
                                                                              //                       addon,
                                                                              //                     ) => {
                                                                              //                       "_id": addon.id,
                                                                              //                       "price": addon.price,
                                                                              //                       "quantity": addon.quantity,
                                                                              //                       "name": addon.name,
                                                                              //                       "isAvailable": addon.isAvailable,
                                                                              //                       "maxQuantity": addon.maxQuantity,
                                                                              //                       "isFree": addon.isFree,
                                                                              //                     },
                                                                              //                   )
                                                                              //                   .toList(),
                                                                              //             },
                                                                              //           );
                                                                              //         }
                                                                              //         context
                                                                              //             .read<
                                                                              //               FoodCategoryBloc
                                                                              //             >()
                                                                              //             .add(
                                                                              //               AddToBilling(
                                                                              //                 List.from(
                                                                              //                   billingItems,
                                                                              //                 ),
                                                                              //                 isDiscountApplied,
                                                                              //                 selectedOrderType,
                                                                              //               ),
                                                                              //             );
                                                                              //       });
                                                                              //     } else {
                                                                              //       currentController
                                                                              //           .text = getCurrentQuantity(
                                                                              //         p.id.toString(),
                                                                              //       ).toString();
                                                                              //       ScaffoldMessenger.of(
                                                                              //         context,
                                                                              //       ).showSnackBar(
                                                                              //         SnackBar(
                                                                              //           content: Text(
                                                                              //             "Maximum available quantity is ${p.availableQuantity ?? 0}",
                                                                              //           ),
                                                                              //         ),
                                                                              //       );
                                                                              //     }
                                                                              //   } else if (newQty ==
                                                                              //           0 ||
                                                                              //       value
                                                                              //           .isEmpty) {
                                                                              //     setState(() {
                                                                              //       billingItems.removeWhere(
                                                                              //         (
                                                                              //           item,
                                                                              //         ) =>
                                                                              //             item['_id'] ==
                                                                              //             p.id,
                                                                              //       );
                                                                              //       quantityControllers.remove(
                                                                              //         p.id,
                                                                              //       );
                                                                              //       if (billingItems.isEmpty ||
                                                                              //           billingItems ==
                                                                              //               []) {
                                                                              //         isDiscountApplied =
                                                                              //             false;
                                                                              //         widget.isEditingOrder =
                                                                              //             false;
                                                                              //         tableId =
                                                                              //             null;
                                                                              //         waiterId =
                                                                              //             null;
                                                                              //         selectedValue =
                                                                              //             null;
                                                                              //         selectedValueWaiter =
                                                                              //             null;
                                                                              //       }
                                                                              //       context
                                                                              //           .read<
                                                                              //             FoodCategoryBloc
                                                                              //           >()
                                                                              //           .add(
                                                                              //             AddToBilling(
                                                                              //               List.from(
                                                                              //                 billingItems,
                                                                              //               ),
                                                                              //               isDiscountApplied,
                                                                              //               selectedOrderType,
                                                                              //             ),
                                                                              //           );
                                                                              //     });
                                                                              //   }
                                                                              // },
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
                                                                                  bool canAddMore;
                                                                                  // if (p.isStock ==
                                                                                  //     true) {
                                                                                  //   if ((widget.isEditingOrder ==
                                                                                  //               true &&
                                                                                  //           widget.existingOrder?.data?.orderStatus ==
                                                                                  //               "COMPLETED") ||
                                                                                  //       (widget.isEditingOrder ==
                                                                                  //               true &&
                                                                                  //           widget.existingOrder?.data?.orderStatus ==
                                                                                  //               "WAITLIST")) {
                                                                                  //     final paidQty =
                                                                                  //         widget.existingOrder?.data?.items
                                                                                  //             ?.firstWhereOrNull(
                                                                                  //               (
                                                                                  //                 item,
                                                                                  //               ) =>
                                                                                  //                   item.product?.id ==
                                                                                  //                   p.id,
                                                                                  //             )
                                                                                  //             ?.quantity ??
                                                                                  //         0;
                                                                                  //     canAddMore =
                                                                                  //         currentQtyInCart <
                                                                                  //         ((p.availableQuantity ??
                                                                                  //                 0) +
                                                                                  //             paidQty);
                                                                                  //   } else {
                                                                                  //     canAddMore =
                                                                                  //         (p.availableQuantity ??
                                                                                  //                 0) >
                                                                                  //             0 &&
                                                                                  //         currentQtyInCart <
                                                                                  //             (p.availableQuantity ??
                                                                                  //                 0);
                                                                                  //   }
                                                                                  // } else {
                                                                                  canAddMore = true;
                                                                                  // }

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
                                                                                      onPressed: () {},
                                                                                      // onPressed:
                                                                                      //     canAddMore
                                                                                      //     ? () {
                                                                                      //         setState(
                                                                                      //           () {
                                                                                      //             isSplitPayment = false;
                                                                                      //             if (widget.isEditingOrder !=
                                                                                      //                 true) {
                                                                                      //               selectedOrderType = OrderType.line;
                                                                                      //             }
                                                                                      //             final index = billingItems.indexWhere(
                                                                                      //               (
                                                                                      //                 item,
                                                                                      //               ) =>
                                                                                      //                   item['_id'] ==
                                                                                      //                   p.id,
                                                                                      //             );
                                                                                      //             if (index !=
                                                                                      //                 -1) {
                                                                                      //               billingItems[index]['qty'] =
                                                                                      //                   billingItems[index]['qty'] +
                                                                                      //                   1;
                                                                                      //               updateControllerText(
                                                                                      //                 p.id.toString(),
                                                                                      //                 billingItems[index]['qty'],
                                                                                      //               );
                                                                                      //             } else {
                                                                                      //               billingItems.add(
                                                                                      //                 {
                                                                                      //                   "_id": p.id,
                                                                                      //                   "basePrice": p.basePrice,
                                                                                      //                   "image": p.image,
                                                                                      //                   "qty": 1,
                                                                                      //                   "name": p.name,
                                                                                      //                   "availableQuantity": p.availableQuantity,
                                                                                      //                   "selectedAddons": p.addons!
                                                                                      //                       .where(
                                                                                      //                         (
                                                                                      //                           addon,
                                                                                      //                         ) =>
                                                                                      //                             addon.quantity >
                                                                                      //                             0,
                                                                                      //                       )
                                                                                      //                       .map(
                                                                                      //                         (
                                                                                      //                           addon,
                                                                                      //                         ) => {
                                                                                      //                           "_id": addon.id,
                                                                                      //                           "price": addon.price,
                                                                                      //                           "quantity": addon.quantity,
                                                                                      //                           "name": addon.name,
                                                                                      //                           "isAvailable": addon.isAvailable,
                                                                                      //                           "maxQuantity": addon.maxQuantity,
                                                                                      //                           "isFree": addon.isFree,
                                                                                      //                         },
                                                                                      //                       )
                                                                                      //                       .toList(),
                                                                                      //                 },
                                                                                      //               );
                                                                                      //               updateControllerText(
                                                                                      //                 p.id.toString(),
                                                                                      //                 1,
                                                                                      //               );
                                                                                      //             }
                                                                                      //             context
                                                                                      //                 .read<
                                                                                      //                   FoodCategoryBloc
                                                                                      //                 >()
                                                                                      //                 .add(
                                                                                      //                   AddToBilling(
                                                                                      //                     List.from(
                                                                                      //                       billingItems,
                                                                                      //                     ),
                                                                                      //                     isDiscountApplied,
                                                                                      //                     selectedOrderType,
                                                                                      //                   ),
                                                                                      //                 );
                                                                                      //           },
                                                                                      //         );
                                                                                      //       }
                                                                                      //     : () {
                                                                                      //         if (p.isStock ==
                                                                                      //                 true &&
                                                                                      //             (p.availableQuantity ??
                                                                                      //                     0) ==
                                                                                      //                 0) {
                                                                                      //           ScaffoldMessenger.of(
                                                                                      //             context,
                                                                                      //           ).showSnackBar(
                                                                                      //             const SnackBar(
                                                                                      //               content: Text(
                                                                                      //                 "Out of stock",
                                                                                      //               ),
                                                                                      //             ),
                                                                                      //           );
                                                                                      //         }
                                                                                      //       },
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
                          const Center(
                            child: Text(
                              "Cart Items",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
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
