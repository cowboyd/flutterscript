import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import "package:flutterscript/flutterscript.dart";
import "package:flutterscript/lisp.dart";

import './builder.dart';
import './interpreter.dart';

class Playground extends StatefulWidget {
  Playground({Key key, this.source = '(Text "Hello World")'}) : super(key: key);

  final String source;

  @override
  _PlaygroundState createState() => _PlaygroundState(source: source);
}

class _PlaygroundState extends State<Playground> {
  _PlaygroundState({this.source}) {
    _sourceController = TextEditingController(text: source);
    _urlController = TextEditingController();

    createInterpreter().then((i) {
      setState(() {
        _interpreter = i;
      });
    });
  }

  String source;
  FlutterScript _interpreter;
  TextEditingController _urlController;
  TextEditingController _sourceController;

  void _updateSourceFromInput() async {
    setState(() {
      source = sanitize(_sourceController.text);
    });
  }

  Future _loadScript(String text) async {
    if (text.isNotEmpty) {
      final response = await http.get(text);

      setState(() {
        source = _sourceController.text = sanitize(response.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            TextField(
              controller: _urlController,
              decoration: InputDecoration(hintText: 'Load script from a URL'),
              onSubmitted: _loadScript,
            ),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _sourceController,
                decoration: InputDecoration(hintText: 'Enter script'),
                keyboardType: TextInputType.multiline,
                maxLines: 100,
                style: TextStyle(fontSize: 18.0),
              ),
            ),
            Expanded(
              flex: 1,
              child: InterpreterBuilder(
                  _interpreter,
                  builder: (BuildContext context, FlutterScript i) {
                    return FutureBuilder(
                        future: i.eval(source),
                        builder:
                            (BuildContext context, AsyncSnapshot snapshot) {
                          if (snapshot.hasError) {
                            return playerError(snapshot.error);
                          }
                          if (snapshot.hasData) {
                            return player(snapshot.data);
                          } else {
                            return player(Container());
                          }
                        });
                  }),
            ),
            Padding(
                padding: const EdgeInsets.all(15),
                child: RaisedButton(
                  child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        '✨ evaluate ✨',
                        style: TextStyle(fontSize: 28),
                      )),
                  color: Colors.white,
                  onPressed: _updateSourceFromInput,
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

Widget player(Widget child) {
  return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[300],
      alignment: Alignment.center,
      child: child);
}
