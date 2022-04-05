abstract class MicrophoneLiveIconState {}

class MicrophoneLiveIconDisableState extends MicrophoneLiveIconState {}

class MicrophoneLiveIconSilentState extends MicrophoneLiveIconState {}

class MicrophoneLiveIconLoudState extends MicrophoneLiveIconState {}

class MicrophoneLiveIconErrorState extends MicrophoneLiveIconState {
  String message;

  MicrophoneLiveIconErrorState({required this.message});
}
