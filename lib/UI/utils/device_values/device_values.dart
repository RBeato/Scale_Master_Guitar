//HomePage
import 'package:scalemasterguitar/UI/utils/device_values/medium_phone_portrait.dart';
import 'package:scalemasterguitar/UI/utils/device_values/small_phone.dart';
import 'package:scalemasterguitar/UI/utils/device_values/tablet_landscape_values.dart';
import 'package:flutter/cupertino.dart';

import '../../../constants/device_screen_enum.dart';

class DeviceValues {
  //?HomePage
  //!Progression Tiles
  late double progressionTilePadding;
  late double progressionsTilesCardPadding;
  late double tileTitleFontSize;
  late double mainChordsVerticalMargin;
  late double mainChordsHorizontalMargin;
  late double secondaryDominantsVerticalMargin;
  late double secondaryDominantsHorizontalMargin;
  late double modalInterchangeVerticalMargin;
  late double modalInterchangeHorizontalMargin;
  late double noteCompleteContainerHeight;
  late double noteCompleteContainerWidth;
  late double homePageMainColumnTopPadding;
  late double homePageMainColumnBottomPadding;
  late double sliderTopPadding;
  late double sliderBottomPadding;
  late double sliderLeftPadding;
  late double sliderRightPadding;
  late double progressionCardPadding;
  late double chordsColumnPadding;
  late double chordRowContainerBorderRadius;
  late double chordRowStackPaddingHorizontal;
  late double chordRowStackPaddingVertical;
  late double chordRowPaddingVertical;
  late double chordRowPaddingHorizontal;
  late double noteContainerHorizontalPadding;
  late double noteContainerVerticalPadding;
  late double noteAnimatedContainerPaddingVertical;
  late double noteAnimatedContainerPaddingHorizontal;
  late double noteAnimatedContainerBorderRadius;
  late double chordFunctionFontSize;
  late double chordFunctionContainerHeight;
  late double chordFunctionPositionLeft;
  late double ofWichChordTextFontSize;
  late double ofWichChordPositionLeft;
  late double ofWichChordPositionTop;
  late double ofWichChordContainerHeight;
  late double chordNamePositionLeft;
  late double chordNamePositionTop;
  late double chordNamePositionBottom;
  late double chordNamePositionRight;
  late double chordNameFontSize;
  late double chordTypePositionBottom;
  late double chordTypePositionRight;
  late double chordTypeTextFontSize;
  //!Progression Template
  late double cardPaddingHorizontal;
  late double cardContainerHeightMoreThanEight;
  late double cardContainerHeightLessThanEight;
  late double cardTemplateKeyboardImageSize;
  late double cardTemplateBassImageSize;
  late double instrumentTemplateExteriorTopPadding;
  late double instrumentTemplateRowPadding;
  late double instrumentGridPaddingLessThanNine;
  late double instrumentGridPaddingMoreThanNine;
  // double chordContainerHeight;
  // double chordContainerWidth;
  late double chordContainerBorderRadius;
  late double chordContainerBorderWidth;
  late double chordContainerTextFontSize;
  // double emptyChordContainerHeight;
  // double emptyChordContainerWidth;

//SequencerPage

  DeviceValues({
    this.progressionTilePadding = 1.0,
    this.progressionsTilesCardPadding = 2.0,
    this.tileTitleFontSize = 10.0,
    this.mainChordsVerticalMargin = 66.0,
    this.mainChordsHorizontalMargin = 100.0,
    this.secondaryDominantsVerticalMargin = 66.0,
    this.secondaryDominantsHorizontalMargin = 100.0,
    this.modalInterchangeVerticalMargin = 66.0,
    this.modalInterchangeHorizontalMargin = 100.0,
    this.noteCompleteContainerHeight = 43.0,
    this.noteCompleteContainerWidth = 57.0,
    this.noteContainerHorizontalPadding = 0.0,
    this.noteContainerVerticalPadding = 0.0,
    this.noteAnimatedContainerPaddingHorizontal = 0.0,
    this.noteAnimatedContainerPaddingVertical = 0.0,
    this.noteAnimatedContainerBorderRadius = 5.0,
    this.homePageMainColumnTopPadding = 25.0,
    this.homePageMainColumnBottomPadding = 50.0,
    this.sliderTopPadding = 24.0,
    this.sliderBottomPadding = 0.0,
    this.sliderLeftPadding = 24.0,
    this.sliderRightPadding = 24.0,
    this.progressionCardPadding = 10.0,
    this.chordsColumnPadding = 2.0,
    this.chordRowContainerBorderRadius = 20.0,
    this.chordRowStackPaddingHorizontal = 4.0,
    this.chordRowStackPaddingVertical = 0.0,
    this.chordRowPaddingVertical = 7.0,
    this.chordRowPaddingHorizontal = 5.0,
    this.chordFunctionFontSize = 10.0,
    this.chordFunctionContainerHeight = 36,
    this.chordFunctionPositionLeft = 0.0,
    this.ofWichChordTextFontSize = 9.0,
    this.ofWichChordPositionLeft = 6.0,
    this.ofWichChordPositionTop = 8.0,
    this.ofWichChordContainerHeight = 20.0,
    this.chordNamePositionLeft = 14.0,
    this.chordNamePositionTop = 4.0,
    this.chordNamePositionBottom = 4.0,
    this.chordNamePositionRight = 8.0,
    this.chordNameFontSize = 12.0,
    this.chordTypePositionBottom = 32.0,
    this.chordTypePositionRight = 48.0,
    //!Progression Template
    this.cardPaddingHorizontal = 2.0,
    this.cardContainerHeightMoreThanEight = 240.0,
    this.cardContainerHeightLessThanEight = 185.0,
    this.cardTemplateKeyboardImageSize = 20.0,
    this.cardTemplateBassImageSize = 28.0,
    this.instrumentTemplateExteriorTopPadding = 8.0,
    this.instrumentTemplateRowPadding = 8.0,
    this.instrumentGridPaddingLessThanNine = 8.0,
    this.instrumentGridPaddingMoreThanNine = 0.0,
    // this.chordContainerHeight = 38.0,
    // this.chordContainerWidth = 38.0,
    this.chordContainerBorderRadius = 12.0,
    this.chordContainerBorderWidth = 2.0,
    this.chordContainerTextFontSize = 15.0,
    // this.emptyChordContainerHeight = 45.0,
    // this.emptyChordContainerWidth = 45.0,
  });
}

// DeviceValues deviceValues = DeviceValues();

getDeviceValues({orientation, deviceType, screenSize, localWidgetSize}) {
  DeviceValues deviceValues = DeviceValues();
  if (deviceType == DeviceScreenType.Mobile) {
    if (orientation == Orientation.portrait) {
      if (screenSize.width < 400 && screenSize.height < 600) {
        deviceValues = smallPhonePortraitValues();
      } else if (screenSize.width < 400 && screenSize.height >= 600) {
        deviceValues = mediumPhonePortraitValues();
      } else if (screenSize.width > 400 && screenSize.height >= 900) {
      } else {}
    } else if (orientation == Orientation.landscape) {}
  }
  if (deviceType == DeviceScreenType.Tablet) {
    if (orientation == Orientation.portrait) {
    } else if (orientation == Orientation.landscape) {}
    deviceValues = tabletLandScapeValues();
  }
  if (deviceType == DeviceScreenType.Desktop) {}

  return deviceValues;
}
