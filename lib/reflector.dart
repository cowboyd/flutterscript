library flutterscript.reflector;

// ignore:unused_import
import "package:flutter/material.dart";
// ignore:unused_import
import "package:flutter/widgets.dart";

@GlobalQuantifyCapability(r"^flutterscript.reflector.App$", reflector)
@GlobalQuantifyCapability(r"^dart.core.(List|Map)$", reflector)
@GlobalQuantifyCapability(r".*\.(Text)$", reflector)
// @GlobalQuantifyCapability(r".*\.(FlatButton)$", reflector)
import "package:reflectable/reflectable.dart";
import "reflector.reflectable.dart";


class Reflector extends Reflectable {
  const Reflector() : super(invokingCapability, delegateCapability);
}


const reflector = const Reflector();

//@reflector
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
