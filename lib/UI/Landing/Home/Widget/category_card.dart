import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ramanas_waiter/Reusable/color.dart';
import 'package:ramanas_waiter/Reusable/image.dart';
import 'package:ramanas_waiter/Reusable/text_styles.dart';

// class CategoryCard extends StatelessWidget {
//   final String label;
//   final String imagePath;
//   final bool isSelected;
//   final VoidCallback onTap;
//
//   const CategoryCard({
//     super.key,
//     required this.label,
//     required this.imagePath,
//     this.isSelected = false,
//     required this.onTap,
//   });
//
//   bool _isNetworkImage(String path) {
//     return path.startsWith("http") || path.startsWith("https");
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     var size = MediaQuery.of(context).size;
//     final String fallbackAsset = Images.all;
//
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         width: size.width < 500 ? size.width * 0.25 : size.width * 0.168,
//         height: size.height * 0.15,
//         padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//         decoration: BoxDecoration(
//           color: isSelected ? whiteColor : greyColor.shade100,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: isSelected ? appPrimaryColor : greyColor,
//             width: 1.5,
//           ),
//         ),
//         child: Column(
//           children: [
//             ClipOval(
//               child: (imagePath.isEmpty)
//                   ? Image.asset(
//                       fallbackAsset,
//                       width: 35,
//                       height: 35,
//                       fit: BoxFit.cover,
//                     )
//                   : _isNetworkImage(imagePath)
//                   ? CachedNetworkImage(
//                       imageUrl: imagePath,
//                       width: 35,
//                       height: 35,
//                       fit: BoxFit.cover,
//                       errorWidget: (context, url, error) => Image.asset(
//                         fallbackAsset,
//                         width: 35,
//                         height: 35,
//                         fit: BoxFit.cover,
//                       ),
//                       progressIndicatorBuilder:
//                           (context, url, downloadProgress) =>
//                               const SpinKitCircle(
//                                 color: appPrimaryColor,
//                                 size: 30,
//                               ),
//                     )
//                   : Image.asset(
//                       imagePath,
//                       width: 35,
//                       height: 35,
//                       fit: BoxFit.cover,
//                     ),
//             ),
//             const SizedBox(height: 6),
//             Expanded(
//               child: Text(
//                 label,
//                 textAlign: TextAlign.center,
//                 style: MyTextStyle.f13(blackColor),
//                 maxLines: 3,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class CategoryCard extends StatelessWidget {
  final String label;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.label,
    required this.imagePath,
    this.isSelected = false,
    required this.onTap,
  });

  bool _isNetworkImage(String path) {
    return path.startsWith("http") || path.startsWith("https");
  }

  @override
  Widget build(BuildContext context) {
    final String fallbackAsset = Images.all;
    var size = MediaQuery.of(context).size;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        // width: size.width * 0.35,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff5B342C) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? const Color(0xff5B342C) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circle with image
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent, // background circle
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.transparent,
                child: ClipOval(
                  child: (imagePath.isEmpty)
                      ? Image.asset(
                          fallbackAsset,
                          width: 25,
                          height: 25,
                          fit: BoxFit.cover,
                        )
                      : _isNetworkImage(imagePath)
                      ? CachedNetworkImage(
                          imageUrl: imagePath,
                          width: 25,
                          height: 25,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Image.asset(
                            fallbackAsset,
                            width: 25,
                            height: 25,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          imagePath,
                          width: 25,
                          height: 25,
                          fit: BoxFit.cover,
                        ),
                ), // optional
              ),
              // ClipOval(
              //   child: (imagePath.isEmpty)
              //       ? Image.asset(
              //           fallbackAsset,
              //           width: 35,
              //           height: 35,
              //           fit: BoxFit.cover,
              //         )
              //       : _isNetworkImage(imagePath)
              //       ? CachedNetworkImage(
              //           imageUrl: imagePath,
              //           width: 30,
              //           height: 35,
              //           fit: BoxFit.cover,
              //           errorWidget: (context, url, error) => Image.asset(
              //             fallbackAsset,
              //             width: 30,
              //             height: 30,
              //             fit: BoxFit.cover,
              //           ),
              //         )
              //       : Image.asset(
              //           imagePath,
              //           width: 30,
              //           height: 30,
              //           fit: BoxFit.cover,
              //         ),
              // ),
            ),
            // const SizedBox(width: 8),
            // Label text
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              maxLines: 3,
              overflow: TextOverflow.visible,
              softWrap: true,
            ),
          ],
        ),
      ),
    );
  }
}
