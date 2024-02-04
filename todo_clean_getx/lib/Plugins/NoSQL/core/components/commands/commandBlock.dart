class CommandBlock<T> {
  String? id;
  T? _reference;
  List<CommandBlock> internalBlocks = [];
  CommandBlock? sub_block;

  Future<bool> Function(Function(T? ref) setRef)? _doFunction;
  Future<bool> Function(T? ref, bool results)? _undoFunction;

  CommandBlock({this.id});

  Future<bool> addInternalBlock(CommandBlock block) async {
    bool results = true;

    if (sub_block != null) {
      results = await sub_block?.addInternalBlock(block) ?? false;
      if (!results) return false;
    } else {
      if (internalBlocks.contains(block)) return false;
      internalBlocks.add(block);

      sub_block = block;
      results = await block.execute();
      sub_block = null;
    }

    return results;
  }

  void _setReference(T? ref) {
    _reference = ref;
  }

  void setCommands({
    required Future<bool> Function(Function(T? ref) setRef) doFunc,
    required Future<bool> Function(T? ref, bool results) undoFunc,
  }) {
    _doFunction = doFunc;
    _undoFunction = undoFunc;
  }

  Future<bool> execute() async {
    if (_doFunction == null) return true;
    bool res = await _doFunction!(_setReference);
    return res;
  }

  Future<bool> undo() async {
    if (_undoFunction == null) return true;
    bool results = true;
    for (var block in internalBlocks.reversed) {
      var res = await block.undo();
      if (!res) results = false;
    }
    return await _undoFunction!(
      _reference,
      results,
    );
  }
}
