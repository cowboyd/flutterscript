import 'package:flutter/material.dart';
import "package:flutterscript/flutterscript.dart";

createInterpreter() async {
  FlutterScript interpreter = await FlutterScript.create();

  interpreter.addClass(
      'Text',
      DartClass(
          (DartArguments args) => Text(
                args[0],
                style: args.named['style'],
              ),
          {}));

  interpreter.addClass(
      'FloatingActionButton',
      DartClass(
          (DartArguments args) => FloatingActionButton(
                child: args['child'],
                onPressed: args['onPressed'],
              ),
          {}));

  interpreter.addClass(
      'Duration',
      DartClass(
          (DartArguments args) => Duration(seconds: args.named['seconds']),
          {}));

  interpreter.addClass(
      'TextStyle',
      DartClass(
          (DartArguments args) => TextStyle(
              fontSize: args.named['fontSize'],
              fontFamily: args.named['fontFamily'],
              color: args.named['color']),
          {}));

  interpreter.addClass(
      'FlatButton',
      DartClass(
          (DartArguments args) => FlatButton(
              child: args.positional[0],
              onPressed: args.named['onPressed'],
              color: args.named['color']),
          {}));

  interpreter.addClass(
      'ButtonBar',
      DartClass(
          (DartArguments args) => ButtonBar(
                children: args.positional.cast<Widget>(),
                alignment: args.named['alignment'],
              ),
          {}));

  interpreter.addClass(
      'AlertDialog',
      DartClass(
          (DartArguments args) => AlertDialog(
              actions: args.positional.cast<Widget>(),
              title: args['title'],
              content: args['content']),
          {}));

  await interpreter.defn(
      'showDialog',
      (DartArguments args) => showDialog(
          context: args['context'],
          builder: (BuildContext context) {
            return args[0];
          }));

  await interpreter.defn('print', (DartArguments args) => print(args[0]));

  await interpreter.defn('color', (DartArguments args) {
    switch (args[0]) {
      case 'red': return Colors.red;
      case 'yellow': return Colors.yellow;
      case 'blue': return Colors.blue;
    }
  });

  await interpreter.defn('alignment', (DartArguments args) {
    switch (args.positional[0]) {
      case 'start':
        return MainAxisAlignment.start;
      case 'center':
        return MainAxisAlignment.center;
      case 'end':
        return MainAxisAlignment.end;
      case 'spaceEvenly':
        return MainAxisAlignment.spaceEvenly;
    }
    return null;
  });

  await interpreter.defn("<=", (DartArguments arguments) {
    FlutterScriptFn fn = arguments[0];
    final args = arguments.positional.sublist(1);
    return () {
      fn(args);
    };
  });

  return interpreter;
}
