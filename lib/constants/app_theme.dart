import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scalemasterguitar/constants/general_audio_constants.dart';

_getFontFamily({size, weight, color}) {
  return //GoogleFonts.merriweather(
      // GoogleFonts.shadowsIntoLight(
      GoogleFonts.lilitaOne(
          fontWeight: weight ?? FontWeight.w100,
          fontSize: size ?? 16.0,
          letterSpacing: 0.5,
          color: color ?? Colors.white);
}

final ThemeData appThemeData = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Constants.mainBackgroundColor,
  drawerTheme:
      const DrawerThemeData(backgroundColor: Constants.mainBackgroundColor),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  textTheme: TextTheme(
    headlineLarge: _getFontFamily(
        size: 50.0, color: Constants.appBarColorTheme, weight: FontWeight.w400),
    headlineMedium: _getFontFamily(
        size: 20.0, color: Constants.appBarColorTheme, weight: FontWeight.w400),
    headlineSmall: _getFontFamily(size: 18.0, color: Colors.white),
    titleLarge: _getFontFamily(size: 20.0),
    titleMedium: _getFontFamily(size: 16.0),
    titleSmall: _getFontFamily(
        size: 12.0, color: Constants.appBarColorTheme, weight: FontWeight.w400),
    bodyMedium: _getFontFamily(size: 16.0),
    bodySmall: _getFontFamily(size: 12.0),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Constants.mainBackgroundColor,
    titleTextStyle: TextStyle(
      color: Constants.appBarColorTheme, // Set the title color here
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
    ),
  ),
  iconTheme: const IconThemeData(color: Constants.appBarColorTheme),
);
