import 'dart:isolate';

import 'binders/bindings.dart';

String cleanRestrictionTypes({required String type}) {
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

List<List<T>> arrayPairer<T>(List<T> values) {
  List<List<T>> pairs = [];
  try {
    if (values.length % 2 != 0) {
      throw ArgumentError(
          "The input list must have an even number of elements");
    }

    for (int i = 0; i < values.length; i += 2) {
      pairs.add([values[i], values[i + 1]]);
    }

    for (var pair in pairs) {
      pair.sort(((a, b) => a.toString().compareTo(b.toString())));
    }
  } catch (e) {
    print(e);
  }
  return pairs;
}

enum _RestrictionFieldTypes {
  FieldRestriction,
  InvFieldRestriction,
}

_RestrictionFieldTypes? toRestrictionFieldTypes(String type) {
  for (var value in _RestrictionFieldTypes.values) {
    if (value.toString() == type) return value;
  }
  return null;
}

enum _RestrictionValueTypes {
  ValueRestrictionEQ,
  ValueRestrictionINVEQ,
  ValueRestrictionGT,
  ValueRestrictionLT,
  ValueRestrictionEQGT,
  ValueRestrictionEQLT,
  ValueRestrictionRANGE,
  ValueRestrictionINVRANGE,
  ValueRestrictionEQRANGE,
  ValueRestrictionINVEQRANGE,
}

_RestrictionValueTypes? toRestrictionValueTypes(String type) {
  for (var value in _RestrictionValueTypes.values) {
    if (value.toString() == type) return value;
  }
  return null;
}

class RestrictionFieldObject {
  String key;
  _RestrictionFieldTypes restrictionType;
  String? expectedType = dynamic.toString();
  bool unique;
  bool isRequired, exclude;
  bool caseSensitive;
  Binding? binder;

  RestrictionFieldObject({
    required this.key,
    required this.restrictionType,
    this.unique = false,
    this.expectedType,
    this.isRequired = false,
    this.exclude = false,
    this.caseSensitive = false,
    this.binder,
  });

  factory RestrictionFieldObject.fromJson(
      {required Map<String, dynamic> data}) {
    return RestrictionFieldObject(
      key: data["key"],
      restrictionType: toRestrictionFieldTypes(data["restrictionType"]) ??
          _RestrictionFieldTypes.FieldRestriction,
      unique: data["unique"],
      isRequired: data["isRequired"],
      exclude: data["exclude"],
      expectedType: data["expectedType"],
      caseSensitive: data["caseSensitive"],
    );
  }

  bool validate({
    required Map<String, dynamic> json,
    List<Map<String, dynamic>>? dataList,
  }) {
    var data = json[key];

    String runtimeType =
        cleanRestrictionTypes(type: data.runtimeType.toString());
    String expectedRuntimeType =
        cleanRestrictionTypes(type: expectedType.toString());

    bool validRuntimeType() {
      return ((runtimeType == expectedRuntimeType) ||
          (expectedType == dynamic.toString()));
    }

    bool isUnique() {
      if (!unique || dataList == null) return true;
      return dataList.where((x) {
        if (caseSensitive) return x[key] == data;

        return x[key].toString().toLowerCase() == data.toString().toLowerCase();
      }).isEmpty;
    }

    switch (restrictionType) {
      case _RestrictionFieldTypes.FieldRestriction:
        if (isRequired && data == null) return false;

        if (data == null) return true;

        if (!validRuntimeType()) return false;

        if (!isUnique()) return false;

        break;
      case _RestrictionFieldTypes.InvFieldRestriction:
        if (exclude && data != null) return false;

        if (data == null) return true;

        if (!validRuntimeType()) return false;

        if (!isUnique()) return false;

        break;

      default:
        return false;
    }

    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      "key": key,
      "restrictionType": restrictionType.toString(),
      "expectedType": expectedType.toString(),
      "unique": unique,
      "isRequired": isRequired,
      "exclude": exclude,
      "caseSensitive": caseSensitive,
    };
  }
}

class RestrictionValueObject {
  String key;
  _RestrictionValueTypes restrictionType;
  List expectedValues;
  bool caseSensitive = false;

  RestrictionValueObject({
    required this.key,
    required this.restrictionType,
    required this.expectedValues,
    this.caseSensitive = false,
  });

  factory RestrictionValueObject.fromJson(
      {required Map<String, dynamic> data}) {
    return RestrictionValueObject(
      key: data["key"],
      restrictionType: toRestrictionValueTypes(data["restrictionType"]) ??
          _RestrictionValueTypes.ValueRestrictionEQ,
      expectedValues: data["expectedValues"],
      caseSensitive: data["caseSensitive"],
    );
  }

  bool validate({
    required Map<String, dynamic> json,
  }) {
    var data = json[key];

    var cleanedList = [];

    if (!caseSensitive) {
      if (data.runtimeType == String) data = data.toLowerCase();

      List tempArray = [];

      for (var value in expectedValues) {
        value = value.runtimeType == String ? value.toLowerCase() : value;
        tempArray.add(value);
      }
      cleanedList = tempArray;
    } else {
      cleanedList = [...expectedValues];
    }

    switch (restrictionType) {
      case _RestrictionValueTypes.ValueRestrictionEQ:
        for (var expectedValue in cleanedList) {
          if (data == expectedValue) return true;
        }
        return false;
      case _RestrictionValueTypes.ValueRestrictionINVEQ:
        for (var expectedValue in cleanedList) {
          if (data == expectedValue) return false;
        }
        return true;
      case _RestrictionValueTypes.ValueRestrictionGT:
        for (var expectedValue in cleanedList) {
          if (data > expectedValue) return true;
        }
        return false;
      case _RestrictionValueTypes.ValueRestrictionLT:
        for (var expectedValue in cleanedList) {
          if (data >= expectedValue) return false;
        }
        return true;
      case _RestrictionValueTypes.ValueRestrictionEQGT:
        for (var expectedValue in cleanedList) {
          if (data >= expectedValue) return true;
        }
        return false;
      case _RestrictionValueTypes.ValueRestrictionEQLT:
        for (var expectedValue in cleanedList) {
          if (data > expectedValue) return false;
        }
        return true;
      case _RestrictionValueTypes.ValueRestrictionRANGE:
        var pairs = arrayPairer(cleanedList);

        for (var pair in pairs) {
          var expectedValue1 = pair[0];
          var expectedValue2 = pair[1];

          if ((data > expectedValue1) && (data < expectedValue2)) return true;
        }

        return false;
      case _RestrictionValueTypes.ValueRestrictionINVRANGE:
        var pairs = arrayPairer(cleanedList);

        for (var pair in pairs) {
          var expectedValue1 = pair[0];
          var expectedValue2 = pair[1];

          if ((data > expectedValue1) && (data < expectedValue2)) return false;
        }

        return true;
      case _RestrictionValueTypes.ValueRestrictionEQRANGE:
        var pairs = arrayPairer(cleanedList);

        for (var pair in pairs) {
          var expectedValue1 = pair[0];
          var expectedValue2 = pair[1];

          if ((data >= expectedValue1) && (data <= expectedValue2)) return true;
        }

        return false;
      case _RestrictionValueTypes.ValueRestrictionINVEQRANGE:
        var pairs = arrayPairer(cleanedList);

        for (var pair in pairs) {
          var expectedValue1 = pair[0];
          var expectedValue2 = pair[1];

          if ((data >= expectedValue1) && (data <= expectedValue2))
            return false;
        }

        return true;

      default:
        return false;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "key": key,
      "restrictionType": restrictionType.toString(),
      "expectedValues": expectedValues,
      "caseSensitive": caseSensitive,
    };
  }
}

class RestrictionBuilder {
  bool valid = true;

  Map<String, RestrictionFieldObject> _restrictionFieldObjects = {};
  Map<String, RestrictionValueObject> _restrictionValueObjects = {};

  RestrictionBuilder();

  factory RestrictionBuilder.fromJson({required Map<String, dynamic> data}) {
    RestrictionBuilder restriction = RestrictionBuilder();

    try {
      restriction.valid = data["valid"] ?? true;

      Map<String, dynamic>? fieldObjects = data["_restrictionFieldObjects"];

      if (fieldObjects != null) {
        Map<String, RestrictionFieldObject> temp_entries = {};

        for (var object in fieldObjects.entries) {
          var key = object.key;
          var value = object.value;

          temp_entries
              .addAll({key: RestrictionFieldObject.fromJson(data: value)});
        }

        restriction._restrictionFieldObjects = temp_entries;
      }

      Map<String, dynamic>? valueObjects = data["_restrictionValueObjects"];

      if (valueObjects != null) {
        Map<String, RestrictionValueObject> temp_entries = {};

        for (var object in valueObjects.entries) {
          var key = object.key;
          var value = object.value;

          temp_entries
              .addAll({key: RestrictionValueObject.fromJson(data: value)});
        }

        restriction._restrictionValueObjects = temp_entries;
      }
    } catch (e) {
      print(e);
    }

    return restriction;
  }

  bool addRestrictionFieldObject(RestrictionFieldObject restrictionObject) {
    bool results = true;

    try {
      results = _restrictionFieldObjects.values
          .where((x) => x.key == restrictionObject.key)
          .isEmpty;

      if (!results) {
        valid = false;
        return false;
      }

      _restrictionFieldObjects["${_restrictionFieldObjects.length}"] =
          restrictionObject;
    } catch (e) {
      print(e);
      results = false;
      valid = false;
    }

    return results;
  }

  bool removeRestrictionFieldObject({required String key}) {
    bool results = true;
    try {
      _restrictionFieldObjects.removeWhere((k, value) => value.key == key);
    } catch (e) {
      print(e);
      valid = false;
      return false;
    }

    return results;
  }

  bool addRestrictionValueObject(RestrictionValueObject restrictionObject) {
    bool results = true;

    try {
      results = _restrictionValueObjects.values
          .where((x) => x.key == restrictionObject.key)
          .isEmpty;

      if (!results) {
        valid = false;
        return false;
      }

      _restrictionValueObjects["${_restrictionValueObjects.length}"] =
          restrictionObject;
    } catch (e) {
      print(e);
      results = false;
      valid = false;
    }

    return results;
  }

  bool removeRestrictionValueObject({required String key}) {
    bool results = true;
    try {
      _restrictionValueObjects.removeWhere((k, value) => value.key == key);
    } catch (e) {
      print(e);
      valid = false;
      return false;
    }

    return results;
  }

  RestrictionFieldObject? getFieldObject(String key) {
    return _restrictionFieldObjects.values
        .where((x) => x.key == key)
        .firstOrNull;
  }

  RestrictionValueObject? getValueObject(String key) {
    return _restrictionValueObjects.values
        .where((x) => x.key == key)
        .firstOrNull;
  }

  RestrictionBuilder restrictField({
    required String key,
    bool unique = false,
    Type expectedType = dynamic,
    bool isRequired = false,
    bool caseSensitive = false,
    Binding? binder,
  }) {
    addRestrictionFieldObject(RestrictionFieldObject(
      key: key,
      restrictionType: _RestrictionFieldTypes.FieldRestriction,
      unique: unique,
      expectedType: expectedType.toString(),
      isRequired: isRequired,
      caseSensitive: caseSensitive,
      binder: binder,
    ));
    return this;
  }

  RestrictionBuilder restrictInvField({
    required String key,
    bool unique = false,
    Type expectedType = dynamic,
    bool exclude = false,
    bool caseSensitive = false,
  }) {
    addRestrictionFieldObject(RestrictionFieldObject(
      key: key,
      restrictionType: _RestrictionFieldTypes.InvFieldRestriction,
      unique: unique,
      expectedType: expectedType.toString(),
      exclude: exclude,
      caseSensitive: caseSensitive,
    ));
    return this;
  }

  RestrictionBuilder restrictValueEQ({
    required String key,
    required List expectedValues,
    bool caseSensitive = false,
  }) {
    addRestrictionValueObject(RestrictionValueObject(
      key: key,
      restrictionType: _RestrictionValueTypes.ValueRestrictionEQ,
      expectedValues: expectedValues,
      caseSensitive: caseSensitive,
    ));
    return this;
  }

  RestrictionBuilder restrictValueINVEQ({
    required String key,
    required List expectedValues,
    bool caseSensitive = false,
  }) {
    addRestrictionValueObject(RestrictionValueObject(
      key: key,
      restrictionType: _RestrictionValueTypes.ValueRestrictionINVEQ,
      expectedValues: expectedValues,
      caseSensitive: caseSensitive,
    ));
    return this;
  }

  RestrictionBuilder restrictValueGT({
    required String key,
    required List expectedValues,
    bool caseSensitive = false,
  }) {
    addRestrictionValueObject(RestrictionValueObject(
      key: key,
      restrictionType: _RestrictionValueTypes.ValueRestrictionGT,
      expectedValues: expectedValues,
      caseSensitive: caseSensitive,
    ));
    return this;
  }

  RestrictionBuilder restrictValueLT({
    required String key,
    required List expectedValues,
    bool caseSensitive = false,
  }) {
    addRestrictionValueObject(RestrictionValueObject(
      key: key,
      restrictionType: _RestrictionValueTypes.ValueRestrictionLT,
      expectedValues: expectedValues,
      caseSensitive: caseSensitive,
    ));
    return this;
  }

  RestrictionBuilder restrictValueEQGT({
    required String key,
    required List expectedValues,
    bool caseSensitive = false,
  }) {
    addRestrictionValueObject(RestrictionValueObject(
      key: key,
      restrictionType: _RestrictionValueTypes.ValueRestrictionEQGT,
      expectedValues: expectedValues,
      caseSensitive: caseSensitive,
    ));
    return this;
  }

  RestrictionBuilder restrictValueEQLT({
    required String key,
    required List expectedValues,
    bool caseSensitive = false,
  }) {
    addRestrictionValueObject(RestrictionValueObject(
      key: key,
      restrictionType: _RestrictionValueTypes.ValueRestrictionEQLT,
      expectedValues: expectedValues,
      caseSensitive: caseSensitive,
    ));

    return this;
  }

  RestrictionBuilder restrictRangeValue({
    required String key,
    required List expectedValues,
    bool caseSensitive = false,
  }) {
    if (expectedValues.length % 2 != 0) {
      valid = false;
      return this;
    }
    addRestrictionValueObject(RestrictionValueObject(
      key: key,
      restrictionType: _RestrictionValueTypes.ValueRestrictionRANGE,
      expectedValues: expectedValues,
      caseSensitive: caseSensitive,
    ));
    return this;
  }

  RestrictionBuilder restrictInvRangeValue({
    required String key,
    required List expectedValues,
    bool caseSensitive = false,
  }) {
    if (expectedValues.length % 2 != 0) {
      valid = false;
      return this;
    }
    addRestrictionValueObject(RestrictionValueObject(
      key: key,
      restrictionType: _RestrictionValueTypes.ValueRestrictionINVRANGE,
      expectedValues: expectedValues,
      caseSensitive: caseSensitive,
    ));
    return this;
  }

  RestrictionBuilder restrictEqRangeValue({
    required String key,
    required List expectedValues,
    bool caseSensitive = false,
  }) {
    if (expectedValues.length % 2 != 0) {
      valid = false;
      return this;
    }
    addRestrictionValueObject(RestrictionValueObject(
      key: key,
      restrictionType: _RestrictionValueTypes.ValueRestrictionEQRANGE,
      expectedValues: expectedValues,
      caseSensitive: caseSensitive,
    ));
    return this;
  }

  RestrictionBuilder restrictInvEqRangeValue({
    required String key,
    required List expectedValues,
    bool caseSensitive = false,
  }) {
    if (expectedValues.length % 2 != 0) {
      valid = false;
      return this;
    }
    addRestrictionValueObject(RestrictionValueObject(
      key: key,
      restrictionType: _RestrictionValueTypes.ValueRestrictionINVEQRANGE,
      expectedValues: expectedValues,
      caseSensitive: caseSensitive,
    ));
    return this;
  }

  Future<bool> interpret({
    required Map<String, dynamic> data,
    List<Map<String, dynamic>>? dataList,
  }) async {
    ReceivePort receivePort = ReceivePort();

    Future<void> queryInterpreterIsolate(SendPort sendPort) async {
      bool results = true;

      for (var obj in _restrictionFieldObjects.values) {
        if (!obj.validate(
          json: data,
          dataList: dataList,
        )) {
          results = false;
          break;
        }
      }

      for (var obj in _restrictionValueObjects.values) {
        if (!obj.validate(json: data)) {
          {
            results = false;
            break;
          }
        }
      }
      sendPort.send(results);
    }

    Isolate isolate = await Isolate.spawn(
      queryInterpreterIsolate,
      receivePort.sendPort,
    );

    bool results = await receivePort.first;

    receivePort.close();
    isolate.kill();
    return results;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> fieldObjects = {};

    for (var object in _restrictionFieldObjects.entries) {
      var key = object.key;
      var value = object.value;

      fieldObjects.addAll({key: value.toJson()});
    }

    Map<String, dynamic> valueObjects = {};

    for (var object in _restrictionValueObjects.entries) {
      var key = object.key;
      var value = object.value;

      valueObjects.addAll({key: value.toJson()});
    }

    return {
      "valid": valid,
      "_restrictionFieldObjects": fieldObjects,
      "_restrictionValueObjects": valueObjects,
    };
  }
}
