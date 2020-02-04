import 'package:flutter/material.dart';
import "package:flutterscript/flutterscript.dart";

typedef BuilderFunction = Widget Function(
    BuildContext context, FlutterScript interpreter);

class InterpreterBuilder extends StatelessWidget {
  InterpreterBuilder(this.interpreter, {this.builder});

  final BuilderFunction builder;
  final FlutterScript interpreter;

  Future<FlutterScript> registerContext(context) async {
    await interpreter.defn('@', (DartArguments args) => context);
    return interpreter;
  }

  @override
  build(BuildContext context) {
    if (interpreter != null) {
      return FutureBuilder(
          future: registerContext(context),
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                return builder(context, interpreter);
              case ConnectionState.none:
              case ConnectionState.waiting:
              case ConnectionState.active:
                return Container();
            }
          });
    } else {
      return Container();
    }
  }
}
