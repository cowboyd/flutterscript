import 'package:flutter/material.dart';
import "package:flutterscript/flutterscript.dart";
import "package:flutterscript/lisp.dart";

import './builder.dart';
import './interpreter.dart';
import './examples.dart';

class Playground extends StatefulWidget {
  Playground({Key key}) : super(key: key);

  @override
  _PlaygroundState createState() => _PlaygroundState(examples["Hello World"]);
}

class _PlaygroundState extends State<Playground> {
  _PlaygroundState(this._source) {
    _sourceController = TextEditingController(text: _source);

    createInterpreter().then((i) {
      setState(() {
        _interpreter = i;
      });
    });
  }

  String _source;
  FlutterScript _interpreter;
  TextEditingController _sourceController;

  void _updateSource(source) {
    setState(() {
      _source = source;
    });
  }

  void _loadInput(source) {
    _sourceController.text = source;
    _updateSource(source);
  }

  @override
  Widget build(BuildContext context) {
    String scriptSelection = examples.containsValue(_source)
        ? examples.entries.firstWhere((entry) => entry.value == _source).value
        : "Empty";

    return Scaffold(
      appBar: AppBar(
        title: Text('FlutterScript'),
      ),
      body: Center(
          child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            DropdownButton<String>(
              onChanged: _loadInput,
              value: scriptSelection,
              items: examples.keys.map<DropdownMenuItem<String>>((String name) {
                String value = examples[name];
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(name),
                );
              }).toList(),
            ),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _sourceController,
                decoration: InputDecoration(hintText: 'Enter script'),
                keyboardType: TextInputType.multiline,
                maxLines: 100,
                style: TextStyle(fontSize: 18.0),
                onChanged: _updateSource,
              ),
            ),
            Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: InterpreterBuilder(_interpreter,
                      builder: (BuildContext context, FlutterScript i) {
                    return FutureBuilder(
                        future: i.eval(sanitize(_source)),
                        builder:
                            (BuildContext context, AsyncSnapshot snapshot) {
                          if (snapshot.hasError) {
                            return playerError(snapshot.error);
                          }
                          if (snapshot.hasData) {
                            return player(snapshot.data,
                                color: _sourceController.text == _source
                                    ? Colors.grey[300]
                                    : Colors.yellowAccent);
                          } else {
                            return player(Container());
                          }
                        });
                  }),
                )),
          ],
        ),
      )),
    );
  }
}

String sanitize(String s) {
  return s
      .replaceAll(new RegExp(r'‘'), '\'')
      .replaceAll(new RegExp(r'’'), '\'')
      .replaceAll(new RegExp(r'“'), '\"')
      .replaceAll(new RegExp(r'”'), "\"");
}

Widget errorText(String error) {
  return Text('Error: $error');
}

Widget playerError(EvalException error) {
  return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.red[300],
      alignment: Alignment.center,
      child: Text(error.message,
          style: TextStyle(color: Colors.white, fontSize: 24.0)));
}

Widget player(Widget child, {color}) {
  return Container(
    padding: const EdgeInsets.all(8.0),
    color: color,
    alignment: Alignment.center,
    child: child,
  );
}
