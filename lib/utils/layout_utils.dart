// import 'package:flutter/material.dart';
// import '../models/story_model.dart';
//
// class LayoutUtils {
//   static Size calculateAspectRatioSize(double width, double height, BoxConstraints constraints) {
//     final ratio = width / height;
//     final screenRatio = constraints.maxWidth / constraints.maxHeight;
//
//     if (screenRatio > ratio) {
//       final newHeight = constraints.maxHeight;
//       final newWidth = newHeight * ratio;
//       return Size(newWidth, newHeight);
//     } else {
//       final newWidth = constraints.maxWidth;
//       final newHeight = newWidth / ratio;
//       return Size(newWidth, newHeight);
//     }
//   }
//
//   static Offset calculateCenterOffset(Size imageSize, BoxConstraints constraints) {
//     final offsetX = (constraints.maxWidth - imageSize.width) / 2;
//     final offsetY = (constraints.maxHeight - imageSize.height) / 2;
//     return Offset(offsetX, offsetY);
//   }
//
//   static Rect calculateInteractiveArea(StoryPage page, Size imageSize, Offset imageOffset) {
//     final scaleX = imageSize.width / page.widthImage;
//     final scaleY = imageSize.height / page.heightImage;
//
//     return Rect.fromLTWH(
//       (page.x * scaleX) + imageOffset.dx,
//       (page.y * scaleY) + imageOffset.dy,
//       page.width * scaleX,
//       page.height * scaleY,
//     );
//   }
//
//   static bool isPointInRect(Offset point, Rect rect) {
//     return rect.contains(point);
//   }
// }