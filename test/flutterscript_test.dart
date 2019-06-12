import "package:flutter_test/flutter_test.dart";

import "dart:convert";
import "dart:async";
import "../lib/lisp.dart";
import "package:flutterscript/flutterscript.dart";
import "package:flutterscript/reflector.dart";
import "package:reflectable/reflectable.dart";
import "flutterscript_test.reflectable.dart"; // Import generated code.

void main() {
  initializeReflectable();

  Interp interp;

  var eval = (String source) async {
    return await run(interp, source);
  };

  Map<String, DartFn> fns = {};

  setUp(() async {
    interp = await makeInterp();


    interp.def("dart/funcall", 2, (List arguments) {
      String functionName = arguments.first;
      DartFn fn = fns[functionName];
      if (fn == null) {
        throw new Exception("void function: `$functionName`");
      }
      DartArguments args = arguments[1];

      return fn.invoke(args);
    });

    interp.def("dart/arguments", 2, (List arguments) {
      return DartArguments(arguments);
    });

    interp.globals[Sym("dart/parameters")] =  DartParameters();

    interp.def("dart/methodcall", 3, (List arguments) {
      Object invocant = arguments.first;
      String methodName = arguments[1].toString();

      DartArguments args = arguments[2];

      var mirror = reflector.reflect(invocant);

      return mirror.invoke(methodName, args.positional, args.named);
    });
    interp.def("::", 2, (List arguments) {
      Object invocant = arguments.first;
      String  propertyName = arguments[1].name;

      InstanceMirror mirror = reflector.reflect(invocant);
      return mirror.invokeGetter(propertyName);
    });
    interp.def("List", -1, (List args) {
      List result = new List();
      for (var cell = args.first; cell != null; cell = cell.cdr) {
        result.add(cell.car);
      }
      return result;
    });
    interp.def("Map", -1, (List args) {
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
  });


  test("1 evals to 1", () async {
    expect(await eval("1"), equals(1));
  });

  group("List inter-op", () {
    test("can instantiate a dart List from within Lisp", () async {
      List list = await eval('(List 1 2 "three")');
      expect(list[0], equals(1));
      expect(list[1], equals(2));
      expect(list[2], equals("three"));
    });
  });

  group("Map inter-op", () {
    test("can instantiate a dart map from within Lisp", () async {
      Map map = await eval('(Map "one" 1 "two" 2)');
      expect(map["one"], equals(1));
      expect(map["two"], equals(2));
    });
  });

  group("Raw Dart inter-op", () {

    setUp(() async {
      fns["App"] = new DartConstructor(App, "");

      eval('(setq app (dart/funcall "App" (dart/arguments (List) (Map "title" "Flutter Demo" "theme" "Dark"))))');
    });

    test("can create a new instance of an object with named parameters", () async {
      var app = await eval('app');
      // expect(app, TypeMatcher<MaterialApp>());
      expect(app.title, equals("Flutter Demo"));
      expect(app.theme, equals("Dark"));
    });

    test("can call methods on objects", () async {
      expect(await eval("(dart/methodcall app 'identityMethod (dart/arguments (List 5) (Map)))"), equals(5));
    });

    test("can call methods with optional positional parameters", () async {
      expect(await eval("(dart/methodcall app 'withOptionalPositionalParameters (dart/arguments (List 1 2) (Map)))"), equals([1, 2]));
    });

    test("can call methods with optional positional parameters using dart-like syntax", () async {
    });

    test("can call methods with optional named parameters", () async {
      expect(await eval('(dart/methodcall app \'withOptionalNamedParameters (dart/arguments (List 1) (Map "two" 2)))'),
          equals({"one": 1, "two": 2}));
    });

    test("can call methods with optional named parameters using friendly dart-like syntax", () async {
    });

    test("can get fields from an object", () async {
      expect(await eval("(:: app 'title)"), equals("Flutter Demo"));
      expect(await eval("(:: app 'theme)"), equals("Dark"));
    });
  });

  group("Friendly Dart-like syntax inter-op", () {
    setUp(() async {
      fns["MaterialApp"] = new DartConstructor(App, "");

      eval("""
(defmacro App (&rest args)
              `(dart/funcall "App" (dart/parameters ,@args)))
""");

      eval('(setq app (App title: "Flutter Demo" theme: "Dark"))');
    });

    test("can call methods on object with nice dart-like syntax", () async {
      var app = await eval('app');
      // expect(app, TypeMatcher<MaterialApp>());
      expect(app.title, equals("Flutter Demo"));
      expect(app.theme, equals("Dark"));
    });
  });
}

toList(Cell first) {
  List list = new List();
  for (Cell cell = first; cell != null; cell = cell.cdr) {
    list.add(cell.car);
  }
  return list;
}

Future run(Interp interp, String source) async {
  Stream<String> input = Stream.fromFuture(Future(() => source));
  input = input.transform(const LineSplitter());
  var lines = new StreamIterator(input);
  var reader = new Reader(lines);
  var sExp = await reader.read();
  return interp.eval(sExp, null);
}


// (@dartcall "MaterialApp" bing foo: bar)
//  |
//  |
//  +-- (dartcall "MaterialApp" (List bing) (Map "foo" bar))
// (defmacro MaterialApp (&rest args)
//   `(@dartcall "MaterialApp" ,@args))
// (defun dartcall (name positional-arguments named-arguments))

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
