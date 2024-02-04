class BiLinkedListObject<T> {
  int? index;
  BiLinkedListObject<T>? _aheadPointer, _prevPointer;
  T? data;

  BiLinkedListObject({required this.data});

  BiLinkedListObject<T>? get aheadPointer => _aheadPointer;

  bool setAheadPointer(BiLinkedListObject<T>? value) {
    if (value == this) return false;
    _aheadPointer = value;
    return true;
  }

  BiLinkedListObject<T>? get prevPointer => _prevPointer;

  bool setPrevPointer(BiLinkedListObject<T>? value) {
    if (value == this) return false;
    _prevPointer = value;
    return true;
  }

  bool propagateIndex({bool skip = false, int value = 0}) {
    var aheadPointer = _aheadPointer;

    if (aheadPointer == null) return false;

    var aheadIndex = aheadPointer.index;

    if (!skip && (aheadIndex == null || aheadIndex == 0)) return false;

    if (aheadIndex != null) aheadPointer.index = aheadIndex + value;

    aheadPointer.propagateIndex(skip: skip, value: value);

    return true;
  }

  Map<String, dynamic> toJson() => {
        "index": index,
        "_aheadPointer": _aheadPointer,
        "_prevPointer": _prevPointer,
        "data": data,
      };
}

class BidirectionalLinkedList<T> {
  List<BiLinkedListObject<T>> _objects = [];

  BiLinkedListObject<T>? _startPointer;

  BiLinkedListObject<T>? _currentPointer;

  List<BiLinkedListObject<T>> get objects => _objects;

  BiLinkedListObject<T>? get currentPointer => _currentPointer;

  bool progressCursor() {
    BiLinkedListObject<T>? pointer = _currentPointer;

    if (_currentPointer == null) {
      if (_startPointer == null) return false;
      _currentPointer = _startPointer!.aheadPointer;
      return true;
    }

    if (pointer == null) return false;

    if (pointer.aheadPointer == null) return false;

    _currentPointer = pointer._aheadPointer;

    return true;
  }

  bool regressCursor() {
    BiLinkedListObject<T>? pointer = _currentPointer;

    if (pointer == null) return false;

    if (pointer.prevPointer == null) return false;

    _currentPointer = pointer.prevPointer;

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

        if (index > (_currentPointer!.index as int)) res = progressCursor();

        if (index < (_currentPointer!.index as int)) res = regressCursor();

        if (!res) return false;

        if (_currentPointer == null) return false;
      }
    }

    return true;
  }

  bool insert({required T? data, int? index}) {
    int numObjects = _objects.length;

    BiLinkedListObject<T> object = BiLinkedListObject(data: data);

    if (numObjects == 0) {
      object.index = 0;
      _objects.add(object);
      _currentPointer = object;
      _startPointer = object;
      return true;
    }

    BiLinkedListObject<T> next;
    BiLinkedListObject<T> previous;

    bool results;

    if (index == null || index == numObjects) {
      int idx = numObjects - 1;
      previous = _objects[idx];

      results = object.setPrevPointer(previous);
      results = previous.setAheadPointer(object);

      object.index = numObjects;
      if (results) _objects.add(object);
      return true;
    }

    if (index < numObjects) {
      int nextIndex = index;
      int previousIndex = index - 1;

      next = _objects[nextIndex];

      results = next.setPrevPointer(object);
      results = object.setAheadPointer(next);

      if (previousIndex >= 0) {
        previous = _objects[previousIndex];

        results = previous.setAheadPointer(object);
        results = object.setPrevPointer(previous);
      }

      if (results) {
        object.index = index;
        object.propagateIndex(skip: index == 0 ? true : false, value: 1);
        _objects.add(object);

        if (index == 0) {
          _startPointer = object;
        }
      }

      return true;
    }

    return false;
  }

  bool removeCurrentObject() => removeObject(_currentPointer);

  bool removeObject(BiLinkedListObject<T>? object) {
    if (object == null) return false;

    if (!_objects.remove(object)) return false;

    int numObjects = _objects.length;

    if (numObjects == 0) {
      _startPointer = null;
      _currentPointer = null;
      return true;
    }

    var next = object.aheadPointer;
    var previous = object.prevPointer;

    if (next != null) next.setPrevPointer(previous);

    if (previous != null) previous.setAheadPointer(next);

    object.propagateIndex(skip: true, value: -1);

    int? index = object.index;
    if (index != null && index == 0) {
      _startPointer = object.aheadPointer;
    }

    void setCurPointer() {
      if (next != null) {
        _currentPointer = next;
        return;
      }

      if (previous != null) {
        _currentPointer = previous;
        return;
      }
      _currentPointer = null;
    }

    setCurPointer();

    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      "_currentPointer": _currentPointer?.toJson() ?? "",
      "_objects": _objects.map((e) => e.toJson()).toList(),
    };
  }
}
