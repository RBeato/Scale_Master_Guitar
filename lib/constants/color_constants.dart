import 'package:flutter/material.dart';
import 'package:tonic/tonic.dart' as tonic;

class ConstantColors {
  static const Color yellowGreen = Color(0xFF33cc33);
  static const Color scarlet = Color(0xFFcc3300); //
  static const Color blueGreen = Color(0xFF00cccc);
  static const Color orange = Color(0xFFff9933);
  static const Color blue = Color(0xFF1a53ff);
  static const Color lemonYellow = Color(0xFFf4ec6b);
  static const Color accentBlue = Color.fromARGB(255, 39, 141, 175);
  static const Color violet = Color(0xFF800080);
  static const Color green = Color(0xFF006600);
  static const Color darkGreen = Color(0xFF006600);
  static const Color red = Color(0xFFff3300);
  static const Color lightRed = Color(0xFFff6666);
  static const Color lightBlue = Color(0xFF33ccff);
  static const Color yellow = Color(0xFFffcc00);
  static const Color lightYellow = Color(0xFFffff99);
  static const Color darkYellow = Color.fromARGB(255, 196, 157, 1);
  static const Color blueViolet = Color(0xFF6600ff);

  static Map scaleColorMap = {
    'I': green,
    'i': green,
    '♭II': violet,
    '♭ii': violet,
    'II': lemonYellow,
    'ii': lemonYellow,
    '♯II': accentBlue,
    '♯ii': accentBlue,
    '♭III': blue,
    '♭iii': blue,
    'III': orange,
    'iii': orange,
    '♭IV': lightRed,
    '♭iv': lightRed,
    'IV': blueGreen,
    'iv': blueGreen,
    '♯IV': blueGreen,
    '♯iv': blueGreen,
    '♭V': scarlet,
    '♭v': scarlet,
    'V': yellowGreen,
    'v': yellowGreen,
    '♯V': yellowGreen,
    '♯v': yellowGreen,
    'VI': yellow,
    'vi': yellow,
    '♯VI': yellow,
    '♯vi': yellow,
    'VII': red,
    'vii': red,
    '♭VI': blueViolet,
    '♭vi': blueViolet,
    '♭♭VII': darkYellow,
    '♭♭vii': darkYellow,
    '♭VII': lightBlue,
    '♭vii': lightBlue,
  };

  static Map<tonic.Interval, Color> scaleTonicColorMap = {
    tonic.Interval.P1: green,
    tonic.Interval.m2: violet,
    tonic.Interval.M2: lemonYellow,
    tonic.Interval.A2: accentBlue,
    tonic.Interval.M3: orange,
    tonic.Interval.m3: blue,
    tonic.Interval.d4: lightRed,
    tonic.Interval.P4: blueGreen,
    tonic.Interval.A4: scarlet,
    tonic.Interval.d5: scarlet,
    tonic.Interval.P5: yellowGreen,
    tonic.Interval.A5: darkGreen,
    tonic.Interval.m6: blueViolet,
    tonic.Interval.M6: yellow,
    tonic.Interval.A6: lightYellow,
    tonic.Interval.d7: darkYellow,
    tonic.Interval.m7: lightBlue,
    tonic.Interval.M7: red,
  };
}
