import "package:reflectable/reflectable.dart";

class Reflector extends Reflectable {
  const Reflector() : super(invokingCapability, delegateCapability);
}

const reflector = const Reflector();

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
