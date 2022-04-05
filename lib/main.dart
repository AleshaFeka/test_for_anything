/*
import 'package:flutter/material.dart';

import 'bluetooth/connect_page.dart';

void main() {
  runApp(const BSApp());
}

class BSApp extends StatelessWidget {
  const BSApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Bulls Electronics',
      home: ConnectPage(),
    );
  }
}

*/

import 'package:blutooth_serial_sender/microphone_live_icon.dart';
import 'package:flutter/material.dart';

void main() => runApp(WebcamApp());

class WebcamApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        home: WebcamPage(),
      );
}

class WebcamPage extends StatefulWidget {
  @override
  _WebcamPageState createState() => _WebcamPageState();
}

class _WebcamPageState extends State<WebcamPage> {
  @override
  void initState() {
    super.initState();
//    _tryPrepareWebHardware();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: MicrophoneLiveIconFlow(),
        ),
      );
}
