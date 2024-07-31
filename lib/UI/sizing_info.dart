import 'package:test/UI/utils/device_values/device_values.dart';
import 'package:flutter/material.dart';

import '../constants/device_screen_enum.dart';

class SizingInformation {
  final Orientation orientation;
  final DeviceScreenType deviceType;
  final Size screenSize;
  final Size localWidgetSize;
  DeviceValues deviceValues = DeviceValues();

  SizingInformation(
      {required this.orientation,
      required this.deviceType,
      required this.screenSize,
      required this.localWidgetSize}) {
    deviceValues = getDeviceValues(
        orientation: orientation,
        deviceType: deviceType,
        screenSize: screenSize,
        localWidgetSize: localWidgetSize);
  }

  @override
  String toString() {
    return "Orientation:$orientation DeviceType:$deviceType ScreenSize:$screenSize LocalWidget:$localWidgetSize";
  }
}
