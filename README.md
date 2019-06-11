# flutterscript

[![CircleCI](https://circleci.com/gh/cowboyd/flutterscript.svg?style=shield)](https://circleci.com/gh/cowboyd/flutterscript)

An embeddable interpreter for Flutter applications

## Getting Started

``` dart
import "package:flutterscript/flutterscript.dart";

Interpreter interperter = Interpreter();
interpreter.eval('"Hello World "') //=> "Hello World"
```

## Development

FlutterScript requires you to build reflection stubs so that you can
invoke Flutter classes and methods dynamically. To do this, you must
manually invoke the build runner any time the set of embedable classes changes.

``` shell
$ flutter packages get
$ flutter packages pub run build_runner build
$ flutter test
```
