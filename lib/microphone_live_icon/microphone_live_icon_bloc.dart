import 'dart:async';

//import 'dart:html';
import 'dart:typed_data';
import 'microphone_live_icon_html_stub.dart' if (dart.library.html) 'dart:html';

import 'package:blutooth_serial_sender/microphone_live_icon/microphone_live_icon_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:noise_meter/noise_meter.dart';

class MicrophoneLiveIconBloc extends Cubit<MicrophoneLiveIconState> {
  static const _soundRecordUpdatesIntervalMillisWeb = 100;
  static const _aBitHumanVoiceRelatedFrequenciesIndexesWeb = [1, 8, 9, 10];
  static const _volumeToleranceThresholdWeb = 70;
  static const _volumeToleranceThresholdMobile = 60;
  static const _delayFromLoudToSilent = 400;

  MediaRecorder? _recorderWeb;
  int _silenceDetectedTimestamp = DateTime.now().millisecondsSinceEpoch;
  int _silentStateEmittedTimestamp = DateTime.now().millisecondsSinceEpoch;
  bool _silentStateEmittedTimestampWasSet = false;
  bool _silenceDetectedTimestampWasSet = false;
  bool _wasLoud = false;

  late StreamSubscription<NoiseReading>? _noiseSubscription;
  late final NoiseMeter _noiseMeter;

  MicrophoneLiveIconBloc() : super(MicrophoneLiveIconLongSilentState());

  @override
  Future<void> close() {
    _stopListenMicrophoneWeb();
    return super.close();
  }

  void onMicrophoneErrorMobile(Object error) {
    emit(MicrophoneLiveIconErrorState(message: error.toString()));
  }

  Future<void> startListenMicrophone() async {
    if (kIsWeb) {
      _startListenMicrophoneWeb();
    } else {
      _startListenMicrophoneMobile();
    }
  }

  Future<void> _startListenMicrophoneMobile() async {
    _noiseMeter = NoiseMeter(onMicrophoneErrorMobile);
    try {
      _noiseSubscription = _noiseMeter.noiseStream.listen(_onDataAvailableMobile);
    } on Exception catch (exception) {
      emit(MicrophoneLiveIconErrorState(message: exception.toString()));
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
    try {
      _noiseSubscription?.cancel();
      _noiseSubscription = null;
      emit(MicrophoneLiveIconDisableState());
    } catch (err) {
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
      if (_silenceDetectedTimestampWasSet) {
        if ((DateTime.now().millisecondsSinceEpoch - _silenceDetectedTimestamp) > _delayFromLoudToSilent) {
          _handleLongSilent();
        }
      } else {
        _handleShortSilent();
      }
    } else {
      _handleVeryLongSilent();
    }
  }

  void _handleVeryLongSilent() {
    if (_silentStateEmittedTimestampWasSet) {
      if ((DateTime.now().millisecondsSinceEpoch - _silentStateEmittedTimestamp) > 2000) {
        _silentStateEmittedTimestampWasSet = false;
        emit(MicrophoneLiveIconLongSilentState());
      }
    }
  }

  void _handleShortSilent() {
    _silenceDetectedTimestamp = DateTime.now().millisecondsSinceEpoch;
    _silenceDetectedTimestampWasSet = true;
  }

  void _handleLongSilent() {
    _silenceDetectedTimestampWasSet = false;
    _wasLoud = false;
    emit(MicrophoneLiveIconSilentState());
    _silentStateEmittedTimestamp = DateTime.now().millisecondsSinceEpoch;
    _silentStateEmittedTimestampWasSet = true;
  }

  void _handleCurrentLoud() {
    _silenceDetectedTimestampWasSet = false;
    if (!_wasLoud) {
      _wasLoud = true;
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
