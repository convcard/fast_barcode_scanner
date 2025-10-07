// import 'package:fast_barcode_scanner/fast_barcode_scanner.dart';
// import 'package:flutter/material.dart';

// class OverlaySelector extends StatefulWidget {
//   const OverlaySelector({super.key});

//   @override
//   State<OverlaySelector> createState() => _OverlaySelectorState();
// }

// class _OverlaySelectorState extends State<OverlaySelector> {
//   _OverlaySelectorState();

//   @override
//   Widget build(BuildContext context) {
//     return ListView.separated(
//       itemBuilder: (ctx, idx) {
//         final item = ScanningOverlayType.values.elementAt(idx);
//         return CheckboxListTile(
//           key: Key(_items[idx]),
//           value: _selected.contains(item),
//           title: Text(_items[idx]),
//           onChanged: (newValue) {
//             setState(() {
//               if (newValue == true) {
//                 _selected.add(item);
//               } else {
//                 _selected.remove(item);
//               }
//             });
//           },
//         );
//       },
//       separatorBuilder: (_, __) => const Divider(height: 1),
//       itemCount: BarcodeType.values.length,
//     );
//   }
// }
