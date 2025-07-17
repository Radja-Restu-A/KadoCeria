// import 'package:flutter/material.dart';
// import '../../core/constants.dart';
//
// class AppLoadingWidget extends StatelessWidget {
//   final String? message;
//
//   const AppLoadingWidget({
//     super.key,
//     this.message,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(FlipbookConstants.primaryColor),
//           ),
//           if (message != null) ...[
//             const SizedBox(height: 16),
//             Text(
//               message!,
//               style: const TextStyle(
//                 fontSize: 16,
//                 color: FlipbookConstants.primaryColor,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }