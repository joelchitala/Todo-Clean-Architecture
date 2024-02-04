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

enum QueryType {
  EQ,
  INVEQ,
  GT,
  LT,
  EQGT,
  EQLT,
  RANGE,
  INVRANGE,
  EQRANGE,
  INVEQRANGE,
  CONTAINS,
  INVCONTAINS,
}

class QueryObject<T, G> {
  T key;
  List<G> values;
  QueryType type;
  bool caseSensitive;

  QueryObject({
    required this.type,
    required this.key,
    required this.values,
    this.caseSensitive = false,
  });

  bool validator({required Map<T, dynamic> json}) {
    var data = json[key];

    var cleanedList = [];

    if (!caseSensitive) {
      if (data.runtimeType == String) data = data.toLowerCase();

      List tempArray = [];

      for (var value in values) {
        if (value != null) {
          value = value.runtimeType == String
              ? ("$value".toLowerCase() as G)
              : value;
        }
        tempArray.add(value);
      }
      cleanedList = tempArray;
    } else {
      cleanedList = [...values];
    }

    switch (type) {
      case QueryType.EQ:
        for (var expectedValue in cleanedList) {
          if (data == expectedValue) return true;
        }
        return false;
      case QueryType.INVEQ:
        for (var expectedValue in cleanedList) {
          if (data == expectedValue) return false;
        }
        return true;
      case QueryType.GT:
        for (var expectedValue in cleanedList) {
          if (data > expectedValue) return true;
        }
        return false;
      case QueryType.LT:
        for (var expectedValue in cleanedList) {
          if (data >= expectedValue) return false;
        }
        return true;
      case QueryType.EQGT:
        for (var expectedValue in cleanedList) {
          if (data >= expectedValue) return true;
        }
        return false;
      case QueryType.EQLT:
        for (var expectedValue in cleanedList) {
          if (data > expectedValue) return false;
        }
        return true;
      case QueryType.RANGE:
        var pairs = arrayPairer(cleanedList);

        for (var pair in pairs) {
          var expectedValue1 = pair[0];
          var expectedValue2 = pair[1];

          if ((data > expectedValue1) && (data < expectedValue2)) return true;
        }

        return false;
      case QueryType.INVRANGE:
        var pairs = arrayPairer(cleanedList);

        for (var pair in pairs) {
          var expectedValue1 = pair[0];
          var expectedValue2 = pair[1];

          if ((data > expectedValue1) && (data < expectedValue2)) return false;
        }

        return true;
      case QueryType.EQRANGE:
        var pairs = arrayPairer(cleanedList);

        for (var pair in pairs) {
          var expectedValue1 = pair[0];
          var expectedValue2 = pair[1];

          if ((data >= expectedValue1) && (data <= expectedValue2)) return true;
        }

        return false;
      case QueryType.INVEQRANGE:
        var pairs = arrayPairer(cleanedList);

        for (var pair in pairs) {
          var expectedValue1 = pair[0];
          var expectedValue2 = pair[1];

          if ((data >= expectedValue1) && (data <= expectedValue2))
            return false;
        }

        return true;
      case QueryType.CONTAINS:
        var values = cleanedList.map((e) => "$e").toList();

        for (var value in values) {
          if ("$data".contains(value)) return true;
        }

        return false;
      case QueryType.INVCONTAINS:
        var values = cleanedList.map((e) => "$e").toList();

        for (var value in values) {
          if ("$data".contains(value)) return false;
        }

        return true;
      default:
        return false;
    }
  }

  Map<String, dynamic> toJson() => {
        "key": key,
        "values": values,
        "type": type,
      };
}

class _QuerySortObject {
  var key;
  bool ascending, includeExcludedData;

  _QuerySortObject({
    required this.key,
    this.ascending = true,
    this.includeExcludedData = false,
  });

  List<Map<K, dynamic>> interpret<K>({required List<Map<K, dynamic>> data}) {
    List<Map<K, dynamic>> array = [];
    List<Map<K, dynamic>> excludeArray = [];

    for (var map in data) {
      map.containsKey(key) ? array.add(map) : excludeArray.add(map);
    }

    try {
      if (ascending) {
        array.sort((a, b) => a[key].compareTo(b[key]));
      } else {
        array.sort((a, b) => b[key].compareTo(a[key]));
      }
    } catch (e) {
      print(e);
    }

    if (includeExcludedData) array = [...array, ...excludeArray];

    return array;
  }
}

class BaseQueryBuilder<T> {
  bool valid = true;
  Map<int, QueryObject> _queryObjects = {};
  _QuerySortObject? __querySortObject;
  int _limit = -1;

  _QuerySortObject? get sortObject => __querySortObject;

  int getLastIndex() => _queryObjects.length;

  bool _set_QuerySortObject(_QuerySortObject sortObject) {
    bool results = true;
    try {
      __querySortObject = sortObject;
    } catch (e) {
      print(e);
      return false;
    }
    return results;
  }

  bool _remove_QuerySortObject() {
    bool results = true;
    try {
      __querySortObject = null;
    } catch (e) {
      print(e);
      return false;
    }
    return results;
  }

  bool _addQueryObject(QueryObject queryObject) {
    bool results = true;

    try {
      _queryObjects[getLastIndex()] = queryObject;

      results = true;
    } catch (e) {
      print(e);
      results = false;
    }

    valid = results;

    return results;
  }

  T sort({
    required var key,
    bool ascending = true,
    bool includeExcludedData = false,
  }) {
    _set_QuerySortObject(_QuerySortObject(
      key: key,
      ascending: ascending,
      includeExcludedData: includeExcludedData,
    ));
    return this as T;
  }

  T removeSort() {
    _remove_QuerySortObject();
    return this as T;
  }

  T eq<G>({
    required var key,
    required List<G> values,
    bool? caseSensitive,
  }) {
    _addQueryObject(QueryObject<dynamic, G>(
      type: QueryType.EQ,
      key: key,
      values: values,
      caseSensitive: caseSensitive ?? false,
    ));
    return this as T;
  }

  T inveq<G>({
    required var key,
    required List<G> values,
    bool? caseSensitive,
  }) {
    _addQueryObject(QueryObject<dynamic, G>(
      type: QueryType.INVEQ,
      key: key,
      values: values,
      caseSensitive: caseSensitive ?? false,
    ));
    return this as T;
  }

  T gt<G>({
    required var key,
    required List<G> values,
    bool? caseSensitive,
  }) {
    _addQueryObject(QueryObject<dynamic, G>(
      type: QueryType.GT,
      key: key,
      values: values,
      caseSensitive: caseSensitive ?? false,
    ));
    return this as T;
  }

  T lt<G>({
    required var key,
    required List<G> values,
    bool? caseSensitive,
  }) {
    _addQueryObject(QueryObject<dynamic, G>(
      type: QueryType.LT,
      key: key,
      values: values,
      caseSensitive: caseSensitive ?? false,
    ));
    return this as T;
  }

  T eqgt<G>({
    required var key,
    required List<G> values,
    bool? caseSensitive,
  }) {
    _addQueryObject(QueryObject<dynamic, G>(
      type: QueryType.EQGT,
      key: key,
      values: values,
      caseSensitive: caseSensitive ?? false,
    ));
    return this as T;
  }

  T eqlt<G>({
    required var key,
    required List<G> values,
    bool? caseSensitive,
  }) {
    _addQueryObject(QueryObject<dynamic, G>(
      type: QueryType.EQLT,
      key: key,
      values: values,
      caseSensitive: caseSensitive ?? false,
    ));
    return this as T;
  }

  T range<G>({
    required var key,
    required List<G> values,
    bool? caseSensitive,
  }) {
    _addQueryObject(QueryObject<dynamic, G>(
      type: QueryType.RANGE,
      key: key,
      values: values,
      caseSensitive: caseSensitive ?? false,
    ));
    return this as T;
  }

  T invrange<G>({
    required var key,
    required List<G> values,
    bool? caseSensitive,
  }) {
    _addQueryObject(QueryObject<dynamic, G>(
      type: QueryType.INVRANGE,
      key: key,
      values: values,
      caseSensitive: caseSensitive ?? false,
    ));
    return this as T;
  }

  T eqrange<G>({
    required var key,
    required List<G> values,
    bool? caseSensitive,
  }) {
    _addQueryObject(QueryObject<dynamic, G>(
      type: QueryType.EQRANGE,
      key: key,
      values: values,
      caseSensitive: caseSensitive ?? false,
    ));
    return this as T;
  }

  T inveqrange<G>({
    required var key,
    required List<G> values,
    bool? caseSensitive,
  }) {
    _addQueryObject(QueryObject<dynamic, G>(
      type: QueryType.INVEQRANGE,
      key: key,
      values: values,
      caseSensitive: caseSensitive ?? false,
    ));
    return this as T;
  }

  T contains<G>({
    required var key,
    required List<G> values,
    bool? caseSensitive,
  }) {
    _addQueryObject(QueryObject<dynamic, G>(
      type: QueryType.CONTAINS,
      key: key,
      values: values,
      caseSensitive: caseSensitive ?? false,
    ));
    return this as T;
  }

  T notcontain<G>({
    required var key,
    required List<G> values,
    bool? caseSensitive,
  }) {
    _addQueryObject(QueryObject<dynamic, G>(
      type: QueryType.INVCONTAINS,
      key: key,
      values: values,
      caseSensitive: caseSensitive ?? false,
    ));
    return this as T;
  }

  T limit(int value) {
    _limit = value;
    if (value < 0) _limit = -1;
    return this as T;
  }

  List<Map<K, dynamic>> interpret<K>({required List<Map<K, dynamic>> data}) {
    var buildQuery = build();

    var buildValues = buildQuery.values.toList();

    List<Map<K, dynamic>> ref = data;

    for (var i = 0; i < buildValues.length; i++) {
      var queryInstance = buildValues[i];

      // array holds the list of data elements that are valid under the current query instance.
      List<Map<K, dynamic>> array = [];

      for (Map<K, dynamic> x in ref) {
        // if element x is valid under the current query instance, it is added to the array.
        if (queryInstance.validator(json: x)) array.add(x);
      }

      // sets the ref array to contain valid elements from the current query instance
      ref = array;
    }

    // Sorts ref array if sort object exists
    if (__querySortObject != null)
      ref = __querySortObject!.interpret(data: ref);

    // if the limit is less than 0 or limit is greater than the ref array, the ref array is returned.
    if (_limit < 0 || _limit > ref.length) return ref;

    // if the limit is 0 then an empty array is returned
    if (_limit == 0) return [];

    // Array that contains the number of ref elements as defined by the limit
    List<Map<K, dynamic>> limitArr = [];

    for (var i = 0; i < _limit; i++) {
      limitArr.add(ref[i]);
    }

    ref = limitArr;

    return ref;
  }

  Map<int, QueryObject> build() => _queryObjects;

  List<Map<String, dynamic>> buildJson() =>
      _queryObjects.values.map((x) => x.toJson()).toList();
}
