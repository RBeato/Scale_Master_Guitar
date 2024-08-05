// import 'package:flutter/material.dart';
// import 'package:purchases_flutter/purchases_flutter.dart';

// class PaywallWidget extends StatefulWidget {
//   const PaywallWidget({
//     Key? key,
//     required this.title,
//     required this.description,
//     required this.packages,
//     required this.onClickedPackage,
//   }) : super(key: key);

//   final String title;
//   final String description;
//   final List<Package> packages;
//   final ValueChanged<Package> onClickedPackage;

//   @override
//   State<PaywallWidget> createState() => _PaywallWidgetState();
// }

// class _PaywallWidgetState extends State<PaywallWidget> {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//         constraints: BoxConstraints(
//           maxHeight: MediaQuery.of(context).size.height * 0.75,
//         ),
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               Text(widget.title),
//               const SizedBox(
//                 height: 16,
//               ),
//               Text(widget.description,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(fontSize: 20.0, color: Colors.black)),
//               const SizedBox(
//                 height: 16,
//               ),
//               buildPackages(),
//             ],
//           ),
//         ));
//   }

//   Widget buildPackages() {
//     return ListView.builder(
//         shrinkWrap: true,
//         primary: false,
//         itemCount: widget.packages.length,
//         itemBuilder: (context, index) {
//           final package = widget.packages[index];
//           return buildPackage(context, package);
//         });
//   }

//   Widget buildPackage(BuildContext context, Package package) {
//     // final product = package.storeProduct; //TODO: check this
//     final product = package.product; //TODO: check this

//     return Card(
//       color: Theme.of(context).colorScheme.secondary,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       child: Theme(
//         data: ThemeData.light(),
//         child: ListTile(
//           contentPadding: const EdgeInsets.all(8),
//           title: Text(
//             product.title,
//             style: const TextStyle(fontSize: 18),
//           ),
//           subtitle: Text(
//             product.description,
//             style: const TextStyle(fontSize: 14),
//           ),
//           trailing: TextButton(
//             onPressed: () => widget.onClickedPackage(package),
//             child: const Text(
//               "Buy",
//               style: TextStyle(fontSize: 18),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
