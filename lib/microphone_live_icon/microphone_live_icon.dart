import 'package:blutooth_serial_sender/microphone_live_icon/microphone_live_icon_bloc.dart';
import 'package:blutooth_serial_sender/microphone_live_icon/microphone_live_icon_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rive/rive.dart';

class MicrophoneLiveIcon extends StatefulWidget {
  final double size;

  const MicrophoneLiveIcon({
    Key? key,
    this.size = 50,
  }) : super(key: key);

  @override
  _MicrophoneLiveIconState createState() => _MicrophoneLiveIconState();
}

class _MicrophoneLiveIconState extends State<MicrophoneLiveIcon> {
  static const _animationName = "Sound";
  static const _animationFileName = "assets/rive/sound.riv";

  late final MicrophoneLiveIconBloc _bloc;
  late final RiveAnimationController _controller;

  bool _isLoudNow = false;

  @override
  void dispose() {
    _bloc.stopListenMicrophone();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _bloc = context.read<MicrophoneLiveIconBloc>();
    _bloc.startListenMicrophone();
    _controller = OneShotAnimation(
      _animationName,
      autoplay: false,
    );
    _controller.isActiveChanged.addListener(() {
      if (!_controller.isActive) {
        if (_isLoudNow) {
          _controller.isActive = true;
        }
      }
    });
  }

  void _setAnimationState(bool isAnimate) {
    _isLoudNow = isAnimate;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MicrophoneLiveIconBloc, MicrophoneLiveIconState>(
      listener: (_, state) {
        switch (state.runtimeType) {
          case MicrophoneLiveIconLoudState:
            {
              _setAnimationState(true);
              if (!_controller.isActive) {
                _controller.isActive = true;
              }
              break;
            }
          case MicrophoneLiveIconSilentState:
          case MicrophoneLiveIconDisableState:
          case MicrophoneLiveIconErrorState:
            {
              _setAnimationState(false);
              break;
            }
        }
      },
      builder: (_, state) {
        switch (state.runtimeType) {
          case MicrophoneLiveIconLoudState:
          case MicrophoneLiveIconSilentState:
            return _buildEnabled();
          case MicrophoneLiveIconErrorState:
          case MicrophoneLiveIconDisableState:
            return _buildDisabled();
          case MicrophoneLiveIconLongSilentState:
            return _buildEmpty();
        }
        return _buildDisabled();
      },
    );
  }

  Widget _buildEmpty() => SizedBox(
    height: widget.size,
    width: widget.size,
  );

  Widget _buildEnabled() {
    return SizedBox(
        height: widget.size,
        width: widget.size,
        child: RiveAnimation.asset(
          _animationFileName,
          controllers: [_controller],
        ));
  }

  Widget _buildDisabled() => SvgPicture.asset(
        "assets/icons/ic_microphone_off.svg",
        height: widget.size,
        width: widget.size,
      );
}

// ignore: use_key_in_widget_constructors
class MicrophoneLiveIconFlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MicrophoneLiveIconBloc(),
      child: const MicrophoneLiveIcon(),
    );
  }
}
