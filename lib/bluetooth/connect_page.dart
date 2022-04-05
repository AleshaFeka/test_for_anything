import 'dart:async';

import 'package:blutooth_serial_sender/screens/home/home_bloc.dart';
import 'package:blutooth_serial_sender/screens/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({Key? key}) : super(key: key);

  @override
  _MainPage createState() => _MainPage();
}

class _MainPage extends State<ConnectPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  bool searchFailed = false;

  Timer? _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;
  bool isDiscovering = false;

  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance.onStateChanged().listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });
  }

  void _restartDiscovery() {
    setState(() {
      isDiscovering = true;
      searchFailed = false;
    });

    _startDiscovery();
  }

  Future _startDiscovery() async {
    bool isWebastoFound = false;
    setState(() {
      searchFailed = false;
      isDiscovering = true;
    });
    _streamSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((r) async {
      print(r.device.name);
      if (r.device.name?.toLowerCase().contains("bulls") ?? false) {
        if (r.device.isBonded) {
          isWebastoFound = true;
          _startChat(context, r.device);
        } else {
          print('Bonding with ${r.device.address}...');
          bool bonded = (await FlutterBluetoothSerial.instance.bondDeviceAtAddress(r.device.address))!;
          if (bonded) {
            setState(() {
              isDiscovering = false;
            });
            isWebastoFound = true;
            _startChat(context, r.device);
          }
          print('Bonding with ${r.device.address} has ${bonded ? 'succed' : 'failed'}.');
        }
      }
    });

    _streamSubscription!.onDone(() {
      setState(() {
        isDiscovering = false;
        if (!isWebastoFound) {
          searchFailed = true;
        }
      });
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _discoverableTimeoutTimer?.cancel();
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage(HomePage.logoAssetPath),
            fit: BoxFit.fitWidth,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.1), BlendMode.dstATop),
          ),
        ),
        child: Column(
          children: <Widget>[
            const Spacer(),
            SwitchListTile(
              title: const Text('Enable Bluetooth'),
              value: _bluetoothState.isEnabled,
              onChanged: (bool value) {
                // Do the request and update with the true value then
                future() async {
                  // async lambda seems to not working
                  if (value) {
                    await FlutterBluetoothSerial.instance.requestEnable();
                  } else {
                    await FlutterBluetoothSerial.instance.requestDisable();
                  }
                }

                future().then((_) {
                  setState(() {});
                });
              },
            ),
            ListTile(
              title: ElevatedButton(
                child: isDiscovering
                    ? const Center(child: CircularProgressIndicator())
                    : Text(searchFailed ? 'Retry' : 'Find and connect Webasto'),
                onPressed: isDiscovering ? null : _startDiscovery,
              ),
            ),
            if (searchFailed)
              const ListTile(
                title: Center(
                  child: Text(
                    "No Webasto found!",
                    style: TextStyle(fontSize: 32, color: Colors.red),
                  ),
                ),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _startChat(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return BlocProvider<HomePageBloc>(
            create: (_) => HomePageBloc(server),
            child: const HomePage(),
          );
//          return ChatPage(server: server);
        },
      ),
    );
  }
}
