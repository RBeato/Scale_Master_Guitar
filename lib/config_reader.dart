import 'dart:convert';
import 'package:flutter/services.dart';

abstract class ConfigReader {
  static Map<String, dynamic>? _config;
  static String? _env;

  static Future<void> initialize(String env) async {
    _env = env;
    final configString = await rootBundle.loadString('config/app_config.json');
    _config = json.decode(configString) as Map<String, dynamic>;
  }

  static int isPaid() {
    //TODO: fix this
    return _config![_env!] as int;
  }
}
