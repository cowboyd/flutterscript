# flutterscript

[![CircleCI](https://circleci.com/gh/cowboyd/flutterscript.svg?style=shield)](https://circleci.com/gh/cowboyd/flutterscript)

An embeddable interpreter for Flutter applications

## Getting Started

``` dart
import "package:flutterscript/flutterscript.dart";

main() async {
  FlutterScript interpreter = await FlutterScript.create();
  await interpreter.eval('"Hello World"'); //> "Hello World"
}
```

You can embed dart functions into the interpreter using the `defn`
method:

``` dart
  await interpreter.defn("loud", (DartArguments arguments) {
    String input = arguments.positional.first.toString();
    return "${input.toUpperCase()}!";
  });

  await interpreter.eval('(loud "Hello World")'); //> "HELLO WORLD!";
```

To embed a _class_ into the interpreter, you use the `defClass` method
where you give it a constructor function, and a list of methods on
that class.

``` dart
  await interpreter.defClass("Text", (DartArguments args) => Text(args[0]), {
    "data": (text, __) => text.data,
    "toString": (text, __) => "Text(${text.data})"
  })

  await interpreter.eval('(setq text (Text "Hello World"))');
  await interpreter.eval('(-> text data)') //> "Hello World";
  await interpreter.eval('(-> text toString)') //> "Text(Hello World)";

```

## FlutterScript server

You can embed a flutter script interpreter into an application and
have it listen for requests on a port. Posting to this server will
result execute the code and write the output to the response.

``` dart
import "package:flutterscript/server.dart"

Future startServer(int port) async {
  Server server = await Server.create(port);
  return server.listen();
}

```

The `Future` returned by `startServer` will complete when the server
is shutdown or crashes.

## Development


``` shell
$ flutter packages get
$ flutter test
```
