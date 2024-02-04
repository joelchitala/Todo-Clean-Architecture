class _LinkListObject<T> {
  int? _index;

  T? data;
  _LinkListObject<T>? _nextPointer;

  _LinkListObject({this.data});

  int? get index => _index;
  set index(int? value) => _index = value;

  _LinkListObject<T>? get nextPointer => _nextPointer;

  bool setNextPointer(_LinkListObject<T>? object) {
    if (object == this) return false;
    _nextPointer = object;
    return true;
  }

  void propagateIndex({int value = 0}) {
    var next = _nextPointer;

    if (next == null) return;

    if (next.index == null) return;

    next.index = (next.index as int) + value;

    next.propagateIndex(value: value);
  }

  toJson() => {
        "index": index,
        "data": data,
        "_nextPointer": _nextPointer == null ? null : nextPointer?.data,
      };
}

class LinkedList<T> {
  _LinkListObject<T>? _startPointer;
  _LinkListObject<T>? _currentPointer;
  List<_LinkListObject<T>> _objects = [];

  _LinkListObject<T>? get startPointer => _startPointer;
  _LinkListObject<T>? get currentPointer => _currentPointer;
  List<_LinkListObject<T>> get objects => _objects;

  bool insert({T? data, int? index}) {
    int numObjects = _objects.length;

    _LinkListObject<T> object = _LinkListObject(data: data);

    if (numObjects == 0) {
      object.index = 0;
      _objects.add(object);
      _currentPointer = object;
      _startPointer = object;
      return true;
    }

    _LinkListObject<T> nextPointer;
    _LinkListObject<T> previousPointer;

    bool results = true;

    if (index == null || index == numObjects) {
      previousPointer = _objects[numObjects - 1];

      object.index = numObjects;
      results = previousPointer.setNextPointer(object);

      if (results) {
        _objects.add(object);
      }

      return results;
    }

    if (index == 0) {
      nextPointer = _objects[index];
      results = object.setNextPointer(nextPointer);
      if (results) {
        object.propagateIndex(value: 1);
        object.index = index;
        _objects.add(object);
        _startPointer = object;
      }

      return results;
    }

    if (index < numObjects) {
      nextPointer = _objects[index];
      previousPointer = _objects[index - 1];

      results = object.setNextPointer(nextPointer);
      if (results) results = previousPointer.setNextPointer(object);

      if (results) {
        object.propagateIndex(value: 1);
        object.index = index;
        _objects.add(object);
      } else {
        previousPointer.setNextPointer(nextPointer);
      }

      return results;
    }

    return results;
  }

  bool removeObject(_LinkListObject<T>? object) {
    if (object == null) return false;

    if (!_objects.remove(object)) return false;

    int idx = object.index!;

    int numObjects = _objects.length;

    if (numObjects == 0) {
      _startPointer = null;
      _currentPointer = null;
      return true;
    }

    object.propagateIndex(value: -1);

    var nextPointer = object.nextPointer;

    if (object == _currentPointer) {
      if (nextPointer == null) {
        var previousPointer = _objects.where((x) => x.nextPointer == object);

        if (previousPointer.length != 0)
          _currentPointer = previousPointer.first;
      } else {
        _currentPointer = nextPointer;
      }
    }

    if (idx == 0) {
      _startPointer = nextPointer;
    }

    if (idx > 0) {
      var previousPointer = _objects.where((x) => x.nextPointer == object);
      previousPointer.first.setNextPointer(nextPointer);
    }

    return true;
  }

  bool progressCursor() {
    _LinkListObject<T>? pointer = _currentPointer;

    if (pointer == null) return false;

    if (pointer.nextPointer == null) return false;

    _currentPointer = pointer.nextPointer;

    return true;
  }

  bool regressCursor() {
    _LinkListObject<T>? pointer = _currentPointer;

    if (pointer == null) return false;

    var previousPointer = _objects.where((x) => x.nextPointer == pointer);
    if (previousPointer.length == 0) return false;

    _currentPointer = previousPointer.first;

    return true;
  }

  bool setCursor({int? index}) {
    int? currentIndex = _currentPointer?.index;

    if (_objects.length == 0 || currentIndex == null) return false;

    if (currentIndex == index) return true;

    if (index != null) {
      if (index >= _objects.length) return false;

      while (true) {
        bool res = true;

        if (_currentPointer!.index == index) return true;

        if (index > (_currentPointer!.index!)) res = progressCursor();

        if (index < (_currentPointer!.index!)) res = regressCursor();

        if (!res) return false;

        if (_currentPointer == null) return false;
      }
    }

    return true;
  }

  T? pop() {
    int idx = _objects.length - 1;

    if (idx == -1) return null;

    setCursor(index: idx);
    var object = _currentPointer!.data;
    removeObject(_currentPointer);

    return object;
  }

  T? popFirst() {
    setCursor();
    var object = _currentPointer!.data;
    removeObject(_currentPointer);
    return object;
  }

  toJson() => {
        "_startPointer": _startPointer?.toJson(),
        "_currentPointer":
            _currentPointer == null ? null : _currentPointer!.toJson(),
        "_objects": _objects.map((object) => object.toJson()),
      };
}
