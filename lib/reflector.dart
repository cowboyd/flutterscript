library flutterscript.reflector;

// ignore:unused_import
import "package:flutter/material.dart";
// ignore:unused_import
import "package:flutter/widgets.dart";

// These two are fine.
@GlobalQuantifyCapability(r"^dart.core.(List|Map)$", reflector)
@GlobalQuantifyCapability(r".*\.(Text|Title)$", reflector)

// this causes the builder to fail.
@GlobalQuantifyCapability(r".*\.(MaterialApp)$", reflector)

import "package:reflectable/reflectable.dart";
import "reflector.reflectable.dart";


class Reflector extends Reflectable {
  const Reflector() : super(invokingCapability);
}


const reflector = const Reflector();


// just an object with some methods and properties
// to invoke and access during tests.
@reflector
class App {
  String title;
  String theme;

  App({this.title, this.theme});

  identityMethod(value) {
    return value;
  }

  withOptionalPositionalParameters (one, [two]) {
    return [one, two];
  }

  withOptionalNamedParameters(one, { two }) {
    return {"one": one, "two": two };
  }
}

void main() {}

initializeReflector() {
  initializeReflectable();
}
