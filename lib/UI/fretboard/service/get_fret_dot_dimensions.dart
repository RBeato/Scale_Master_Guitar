import 'package:flutter/material.dart';

Map getFretDotDimensions(cardSizeInfo) {
  Map fretDimensions = {
    ['height']: 0.0,
    ['width']: 0.0
  };

  if (cardSizeInfo.orientation == Orientation.landscape) {
    fretDimensions['height'] = cardSizeInfo.localWidgetSize.height / 9;
    fretDimensions['width'] = cardSizeInfo.localWidgetSize.width / 10;
  }
  if (cardSizeInfo.orientation == Orientation.portrait) {
    fretDimensions['height'] = cardSizeInfo.localWidgetSize.width / 20;
    fretDimensions['width'] = cardSizeInfo.localWidgetSize.height / 20;
  }
  return fretDimensions;
}
