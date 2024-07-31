// Create a utility class for Roman numeral conversion
class RomanNumeralConverter {
  static String convertToFretRomanNumeral(int fret) {
    switch (fret) {
      case 3:
        return 'III';
      case 5:
        return 'V';
      case 7:
        return 'VII';
      case 9:
        return 'IX';
      case 12:
        return 'XII';
      case 15:
        return 'XV';
      case 17:
        return 'XVII';
      case 19:
        return 'XIX';
      case 21:
        return 'XXI';
      case 24:
        return 'XXIV';
      default:
        return '';
    }
  }
}
