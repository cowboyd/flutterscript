library flutterscript.reflector;
// @GlobalQuantifyCapability(
//     r"^test_reflectable.test.global_quantify_test.(A|B)$", reflector)
import "package:reflectable/reflectable.dart";
// import "reflector.reflectable.dart";

class Reflector extends Reflectable {
  const Reflector() : super(newInstanceCapability, invokingCapability);
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
