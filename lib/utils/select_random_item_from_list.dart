import 'dart:math';

Random _random = Random();

selectRandomItem(itemList) {
  int index = _random.nextInt(itemList.length);
  var value = itemList[index];
  return value;
}
