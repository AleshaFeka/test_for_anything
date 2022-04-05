import 'dart:convert';
import 'dart:typed_data';

import 'package:blutooth_serial_sender/model/webasto_data_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class HomePageBloc extends Cubit<HomePageState> {
  BluetoothConnection? connection;
  final BluetoothDevice server;
  String _messageBuffer = '';

  bool isConnecting = true;
  bool isDisconnecting = false;

  bool get isConnected => (connection?.isConnected ?? false);

  HomePageBloc(this.server) : super(HomePageInitialState()) {
    _init();
  }

  void dispose() {
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }
  }

  void _init() async {
    emit(HomePageLoadingState());
    emit(HomePageDataReadyState(WebastoDataModel(
      isWebastoOnline: false,
      isWaterPumpWorking: false,
      milliVolts: 0,
      temperatureCelsius: 0,
      isFuelPumpWorking: false,
      isFanWorking: false,
    )));

    BluetoothConnection.toAddress(server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      isConnecting = false;
      isDisconnecting = false;

      connection!.input!.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally!');
          emit(HomePageDisconnectedState());
        } else {
          print('Disconnected remotely!');
          emit(HomePageDisconnectedState());
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      final text = backspacesCounter > 0
          ? _messageBuffer.substring(0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString.substring(0, index);

      if (text.split(",").length > 4) {
        final model = WebastoDataModel.fromString(text);
        emit(HomePageDataReadyState(model));
      } else {
        print("Invalid received -  $text");
      }
      _messageBuffer = dataString.substring(index);
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();

    if (text.isNotEmpty) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode(text + "\r\n")));
        await connection!.output.allSent;

      } catch (e) {
        // Ignore error, but notify state
      }
    }
  }


  void onButton1Pressed() {
    _sendMessage("S1");
  }

  void onButton2Pressed() {
    _sendMessage("S0");
  }

  void onButton3Pressed() {
    _sendMessage("P1");
  }

  void onButton4Pressed() {
    _sendMessage("P0");
  }
}

abstract class HomePageState {
  const HomePageState();
}

class HomePageInitialState extends HomePageState {}

class HomePageLoadingState extends HomePageState {}

class HomePageConnectingState extends HomePageState {}

class HomePageDisconnectingState extends HomePageState {}

class HomePageDisconnectedState extends HomePageState {}

class HomePageConnectedState extends HomePageState {}

class HomePageDataReadyState extends HomePageState {
  final WebastoDataModel model;

  const HomePageDataReadyState(this.model);
}
