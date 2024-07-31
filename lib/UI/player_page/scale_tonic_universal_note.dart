// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import 'provider/tonic_universal_note_provider.dart';

// class ScaleTonicAsUniversalNote extends ConsumerWidget {
//   const ScaleTonicAsUniversalNote({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final isSwitched = ref.watch(tonicUniversalNoteProvider);
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 10.0),
//       child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//         const Expanded(
//           flex: 3,
//           child: Text(
//             "Scale Tonic as Universal Bass Note",
//             style: TextStyle(fontSize: 20, color: Colors.white),
//           ),
//         ),
//         Expanded(
//             child: Align(
//           alignment: Alignment.centerRight,
//           child: Switch(
//             value: isSwitched,
//             onChanged: (bool value) {
//               ref
//                   .read(tonicUniversalNoteProvider.notifier)
//                   .update((state) => value);
//             },
//             activeTrackColor: Colors.lightGreenAccent,
//             activeColor: Colors.green,
//           ),
//         ))
//       ]),
//     );
//   }
// }
