import 'dart:async';

//import 'dart:html';
import 'dart:typed_data';
import 'microphone_live_icon_html_stub.dart' if (dart.library.html) 'dart:html';

import 'package:blutooth_serial_sender/microphone_live_icon_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:noise_meter/noise_meter.dart';

class MicrophoneLiveIconBloc extends Cubit<MicrophoneLiveIconState> {
  static const _soundRecordUpdatesIntervalMillisWeb = 100;
  static const _aBitHumanVoiceRelatedFrequenciesIndexesWeb = [1, 8, 9, 10];
  static const _volumeToleranceThresholdWeb = 70;
  static const _volumeToleranceThresholdMobile = 60;
  static const _delayFromLoudToSilentWeb = 400;

  MediaRecorder? _recorderWeb;
  int _lastSilenceDetectedTimestamp = DateTime.now().millisecondsSinceEpoch;
  bool _timestampWasSetWhenSilent = false;
  bool _wasLoud = false;

  bool _isRecording = false;
  late StreamSubscription<NoiseReading>? _noiseSubscription;
  late final NoiseMeter _noiseMeter;

  MicrophoneLiveIconBloc() : super(MicrophoneLiveIconDisableState());

  @override
  Future<void> close() {
    _stopListenMicrophoneWeb();
    return super.close();
  }

  void onMicrophoneErrorMobile(Object error) {
    print(error.toString());
  }

  Future<void> startListenMicrophone() async {
    if (kIsWeb) {
      _startListenMicrophoneWeb();
    } else {
      _startListenMicrophoneMobile();
    }
  }

  Future<void> _startListenMicrophoneMobile() async {
    print("startListenMicrophoneMobile");
    _noiseMeter = NoiseMeter(onMicrophoneErrorMobile);
    try {
      _noiseSubscription = _noiseMeter.noiseStream.listen(_onDataAvailableMobile);
    } on Exception catch (exception) {
      print('startRecorder exception: $exception');
    }
  }

  Future<void> _startListenMicrophoneWeb() async {
    final stream = await window.navigator.mediaDevices?.getUserMedia({"audio": "true"});

    if (stream == null) {
      emit(MicrophoneLiveIconErrorState(message: "Stream wasn't open."));
    } else {
      _recorderWeb = MediaRecorder(stream);
      _recorderWeb?.addEventListener('dataavailable', _onDataAvailableWeb);
      _recorderWeb?.start(_soundRecordUpdatesIntervalMillisWeb);
    }
  }

  Future<void> stopListenMicrophone() async {
    if (kIsWeb) {
      _stopListenMicrophoneWeb();
    } else {
      _stopListenMicrophoneMobile();
    }
  }

  Future<void> _stopListenMicrophoneMobile() async {
    print("_stopListenMicrophoneMobile");
    try {
      _noiseSubscription?.cancel();
      _noiseSubscription = null;
      emit(MicrophoneLiveIconDisableState());

    } catch (err) {
      print('stopRecorder error: $err');
      emit(MicrophoneLiveIconErrorState(message: err.toString()));
    }
  }

  Future<void> _stopListenMicrophoneWeb() async {
    _recorderWeb?.stop();
    _recorderWeb?.stream?.getTracks().forEach((track) {
      track.stop();
    });
    emit(MicrophoneLiveIconDisableState());
  }

  void _onDataAvailableMobile(NoiseReading noiseReading) {
    if (noiseReading.maxDecibel > _volumeToleranceThresholdMobile &&
        noiseReading.meanDecibel > _volumeToleranceThresholdMobile) {
      _handleCurrentLoud();
    } else {
      _handleCurrentSilent();
    }
  }

  void _onDataAvailableWeb(Event event) {
    final blobEvent = event as BlobEvent;
    var r = FileReader();
    r.readAsArrayBuffer(blobEvent.data!);
    r.onLoadEnd.listen((e) {
      var buf = r.result as Uint8List;
      if (_checkHumanVoiceSoundsWeb(buf)) {
        _handleCurrentLoud();
      } else {
        _handleCurrentSilent();
      }
    });
  }

  void _handleCurrentSilent() {
    if (_wasLoud) {
      if (_timestampWasSetWhenSilent) {
        final now = DateTime.now();
        if ((now.millisecondsSinceEpoch - _lastSilenceDetectedTimestamp) > _delayFromLoudToSilentWeb) {
          _timestampWasSetWhenSilent = false;
          _wasLoud = false;
          print("off!");
          emit(MicrophoneLiveIconSilentState());
        }
      } else {
        _lastSilenceDetectedTimestamp = DateTime.now().millisecondsSinceEpoch;
        _timestampWasSetWhenSilent = true;
      }
    }
  }

  void _handleCurrentLoud() {
    _timestampWasSetWhenSilent = false;
    if (!_wasLoud) {
      _wasLoud = true;
      print("on!");
      emit(MicrophoneLiveIconLoudState());
    }
  }

  bool _checkHumanVoiceSoundsWeb(Uint8List microphoneRawData) {
    bool result = true;
    for (int index in _aBitHumanVoiceRelatedFrequenciesIndexesWeb) {
      if (ByteData.view(microphoneRawData.buffer).getInt8(index) > _volumeToleranceThresholdWeb) {
        result = false;
      }
    }
    return result;
  }
}
