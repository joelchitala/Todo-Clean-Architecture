import 'dart:math';

const int RandomMax = 100000;

String generateTimeStamp() {
  DateTime now = DateTime.now();
  return "${now.day}-${now.month}-${now.year}";
}

String generateFullTimeStamp() {
  DateTime now = DateTime.now();
  return "${now.second}:${now.minute}:${now.hour}::${now.day}-${now.month}-${now.year}";
}

String generateUUID() {
  return "${Random().nextInt(RandomMax)}_${generateFullTimeStamp()}";
}

bool isSimilar(List<dynamic> fullSet, List<dynamic> subSet) {
  try {
    for (var i = 0; i < subSet.length; i++) {
      bool results = fullSet.contains(subSet[i]);
      if (!results) return false;
    }
  } catch (e) {
    return false;
  }

  return true;
}

bool isSubset({
  required List<dynamic> set1,
  required List<dynamic> set2,
  bool strict = false,
}) {
  if (set1.isEmpty && set2.isEmpty) return true;

  if (set1.isEmpty || set2.isEmpty) return false;

  bool results = false;

  try {
    List<dynamic> fullSet, subSet;

    if (set1.length >= set2.length) {
      fullSet = set1;
      subSet = set2;
    } else {
      fullSet = set2;
      subSet = set1;
    }

    for (var element in subSet) {
      results = fullSet.contains(element);

      if (results && !strict) return true;

      if (!results && strict) return false;
    }
  } catch (e) {
    print(e);
  }

  return results;
}

String cleanTypes({required String type}) {
  if (type.isEmpty) return type;

  if (type[0] != "_") return type;

  String str = "";

  for (var i = 0; i < type.length; i++) {
    String char = type[i];
    if (i == 0 && char == "_") continue;

    str += char;
  }

  return str;
}

String generateRandomString(int length) {
  Random random = Random();
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890123456789';
  return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
}
