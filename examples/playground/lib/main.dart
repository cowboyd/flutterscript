import 'package:flutter/material.dart';
import './playground.dart';

void main() => runApp(MaterialApp(
      title: 'Title',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Playground(),
    ));
