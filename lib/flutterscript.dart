library flutterscript;

import "package:reflectable/reflectable.dart";
import "reflector.dart";

abstract class DartFn {
  Object invoke(DartArguments arguments);
}

class DartConstructor implements DartFn {
  Type type;
  String name;

  DartConstructor(this.type, this.name);

  Object invoke(DartArguments arguments) {
    ClassMirror mirror = reflector.reflectType(this.type);
    var instance = mirror.newInstance(this.name, arguments.positional, arguments.named);

    return instance;
  }
}

class DartArguments {
  List<Object> positional;
  Map<Symbol, Object> named;

  DartArguments(List input) {
    List<Object> positions = input.first;
    Map<String, Object> names = input.last;

    if (positions == null) {
      this.positional = [];
    } else {
      this.positional = positions;
    }
    if (names == null) {
      this.named = {};
    } else {
      this.named = names.map((key, value) => MapEntry<Symbol, Object>(Symbol(key), value)).cast<Symbol, Object>();
    }
  }
}


/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;
}
