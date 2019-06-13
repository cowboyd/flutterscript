library flutterscript;

import "dart:convert";
import "dart:async";
import "package:reflectable/reflectable.dart";
import "reflector.dart";
import "lisp.dart";

initializeFlutterScript() {
  initializeReflector();
}

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

  String toString() {
    return "DartArguments(${this.positional}, ${this.named})";
  }
}


class FlutterScript {
  Interp lisp;
  Map<String, DartFn> fns;

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

      return fn.invoke(args);
    });
    lisp.def("dart/methodcall", 3, (List arguments) {
      Object invocant = arguments.first;
      String methodName = arguments[1].toString();
      DartArguments args = arguments[2];

      InstanceMirror mirror = reflector.reflect(invocant);

      return mirror.invoke(methodName, args.positional, args.named);
    });
    lisp.def("::", 2, (List arguments) {
      Object invocant = arguments.first;
      String  propertyName = arguments[1].name;

      InstanceMirror mirror = reflector.reflect(invocant);
      return mirror.invokeGetter(propertyName);
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
