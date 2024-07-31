import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define a provider to manage the state of the selected color
final fretboardColorProvider = StateProvider<Color>((ref) => Colors.grey);
