import "package:flutter_test/flutter_test.dart";

import "package:flutterscript/flutterscript.dart";
import "package:flutterscript/reflector.dart";
import "package:flutter/widgets.dart";

void main() {

  initializeFlutterScript();

  FlutterScript interp;
  var eval = (String source) async {
    return await interp.eval(source);
  };

  setUp(() async {
    interp = await FlutterScript.create();
  });


  test("1 evals to 1", () async {
    expect(await interp.eval("1"), equals(1));
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
      await interp.defn("App", new DartConstructor(App, ""));

      await eval('(setq app (dart/funcall "App" (dart/arguments (List) (Map "title" "Flutter Demo" "theme" "Dark"))))');
    });

    test("can create a new instance of an object with named parameters", () async {
      App app = await eval('app');
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

    test("can call methods with optional named parameters", () async {
      expect(await eval('(dart/methodcall app \'withOptionalNamedParameters (dart/arguments (List 1) (Map "two" 2)))'),
          equals({"one": 1, "two": 2}));
    });


    test("can get fields from an object", () async {
      expect(await eval("(dart/property-get app 'title)"), equals("Flutter Demo"));
      expect(await eval("(dart/property-get app \"title\")"), equals("Flutter Demo"));
      expect(await eval("(dart/property-get app 'theme)"), equals("Dark"));
      expect(await eval("(dart/property-get app \"theme\")"), equals("Dark"));
    });
  });

  group("Friendly Dart-like syntax inter-op", () {
    setUp(() async {
      await interp.defn("App", new DartConstructor(App, ""));

      await eval('(setq app (App title: "Flutter Demo" theme: "Dark"))');
    });

    test("can call methods on object with nice dart-like syntax", () async {
      App app = await eval('app');
      expect(app.title, equals("Flutter Demo"));
      expect(app.theme, equals("Dark"));
    });

    test("can call methods with optional positional parameters using dart-like syntax", () async {
      var result = await eval('(-> app withOptionalPositionalParameters 1 2)');
      expect(result, equals([1, 2]));
    });

    test("can call methods with optional named parameters using friendly dart-like syntax", () async {
      expect(await eval('(-> app withOptionalNamedParameters 1 two: 2)'),
          equals({"one": 1, "two": 2}));
    });
  });

  group("Flutter inter-op", () {
    setUp(() async {
      await interp.defn("Text", new DartConstructor(Text, ""));
    });
    test("can actually instantiate and call methods on flutter widgets",() async {
      Text text = await eval('(Text "hello world")');
      String data = await eval('(:: (Text "hello world") data)');
      expect(text.data, equals("hello world"));
      expect(data, equals("hello world"));
    });
  });
}
