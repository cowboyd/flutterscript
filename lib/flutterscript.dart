library flutterscript;

import "dart:convert";
import "dart:async";
import "lisp.dart";

typedef DartFn = Object Function(DartArguments arguments);
typedef DartMethod = Object Function(dynamic invocant, DartArguments arguments);

class DartClass {
  DartFn constructor;
  Map<String, DartMethod> methods;
  DartClass(this.constructor, this.methods);
}

class DartArguments {
  List<Object> positional;
  Map<String, Object> named;

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
      this.named = names;
    }
  }

  operator [](Object key) {
    if (key is Symbol || key is String) {
      return named[key.toString()];
    } else if (key is int) {
      return positional[key];
    }
  }

  String toString() {
    return "DartArguments(${this.positional}, ${this.named})";
  }
}


class FlutterScript {
  Interp lisp;
  Map<String, DartFn> fns;
  Map<Type, Map<String, DartMethod>> methodsOf;

  static Future<FlutterScript> create() async {
    Interp lisp = await makeInterp();
    FlutterScript interpreter = FlutterScript(lisp);

    await interpreter.eval("""
(defmacro -> (invocant name &rest args)
  `(dart/methodcall ,invocant (quote ,name) (dart/parameters ,@args)))
""");

    return interpreter;
  }

  FlutterScript(this.lisp) {
    fns = {};
    methodsOf = {};

    lisp.globals[Sym("dart/parameters")] =  DartParameters();

    lisp.def("dart/arguments", 2, (List arguments) {
      return DartArguments(arguments);
    });

    lisp.def("dart/funcall", 2, (List arguments) {
      String functionName = arguments.first;
      DartFn fn = fns[functionName];
      if (fn == null) {
        throw new Exception("void function: `$functionName`");
      }
      DartArguments args = arguments[1];

      return fn(args);
    });

    lisp.def("dart/methodcall", 3, (List arguments) {
      Object invocant = arguments.first;
      Map<String, DartMethod> methods = methodsOf[invocant.runtimeType];
      String methodName = arguments[1].toString();

      DartMethod method = methods[methodName];
      if (method == null) {
        throw new Exception("no such method `$methodName` on `$invocant`");
      }
      DartArguments args = arguments[2];
      return method(invocant, args);
    });

    lisp.def("List", -1, (List args) {
      List result = new List();
      for (var cell = args.first; cell != null; cell = cell.cdr) {
        result.add(cell.car);
      }
      return result;
    });

    lisp.def("Map", -1, (List args) {
      int index = 0;
      String key;
      List<MapEntry<String, Object>> entries = new List<MapEntry<String, Object>>();
      for (var cell = args.first; cell != null; cell = cell.cdr) {
        if (index % 2 == 0) {
          key = cell.car;
        } else {
          entries.add(MapEntry(key.toString(), cell.car));
        }
        index++;
      }
      return Map.fromEntries(entries);
    });
  }


  defn(String functionName, DartFn function) async {
    fns[functionName] = function;
    return await eval("""
(defmacro $functionName (&rest args)
              `(dart/funcall \"$functionName\" (dart/parameters ,@args)))
        """);
  }

  defineType(Type type, Map<String, DartMethod> methods) {
    if (methodsOf[type] == null) {
      methodsOf[type] = methods;
    }
  }

  addClass(String name, DartClass type) {
    defineClass(name, type.constructor, type.methods);
  }

  defineClass(String name, DartFn constructor, Map<String, DartMethod> methods) {
    defn(name, (DartArguments arguments) {
      Object instance = constructor(arguments);

      defineType(instance.runtimeType, methods);

      return instance;
    });
  }

  Future<Object> eval(String source) async {
    Stream<String> input = Stream.fromFuture(Future(() => source));
    input = input.transform(const LineSplitter());
    var lines = new StreamIterator(input);
    var reader = new Reader(lines);
    var sExp = await reader.read();
    return lisp.eval(sExp, null);
  }
}


class DartParameters extends Macro {
  DartParameters(): super(-1, null);

  @override Cell expandWith(interpreter, Cell arg) {
    Sym mapSym = Sym.table["Map"];
    Sym listSym = Sym.table["List"];
    Sym argumentsSym = Sym.table["dart/arguments"];

    List<dynamic> positional = new List();
    List<MapEntry<Sym, dynamic>> named = new List();
    Sym key = null;

    foldl(arg, arg, (body, item) {
      if (item is Sym && item.name.endsWith(":")) {
        if (key != null) {
          throw new Exception("expected value for key $key, but got another key: $item");
        } else {
          key = item;
        }
      } else {
        if (key != null) {
          named.add(new MapEntry<Sym, dynamic>(key, item));
          key = null;
        } else {
          positional.add(item);
        }
      }
      return body;
    });

    Cell pbody = Cell(listSym, null);
    Cell pcur = pbody;
    positional.forEach((item) {
      pcur.cdr = Cell(item, null);
      pcur = pcur.cdr;
    });
    Cell nbody = Cell(mapSym, null);
    Cell ncur = nbody;
    named.forEach((entry) {
      String keyName = entry.key.name;

      ncur.cdr = Cell(keyName.substring(0, keyName.length - 1), Cell(entry.value, null));
      ncur = ncur.cdr.cdr;
    });
    Cell result = Cell(argumentsSym, Cell(pbody, Cell(nbody, null)));
    return result;
  }
}
