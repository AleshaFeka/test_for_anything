import 'package:blutooth_serial_sender/microphone_live_icon_bloc.dart';
import 'package:blutooth_serial_sender/microphone_live_icon_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rive/rive.dart';

class MicrophoneLiveIcon extends StatefulWidget {
  const MicrophoneLiveIcon({Key? key}) : super(key: key);

  @override
  _MicrophoneLiveIconState createState() => _MicrophoneLiveIconState();
}

class _MicrophoneLiveIconState extends State<MicrophoneLiveIcon> {
  late final MicrophoneLiveIconBloc _bloc;
  late RiveAnimationController _controller;

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
      'Sound',
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
    return BlocListener<MicrophoneLiveIconBloc, MicrophoneLiveIconState>(
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
            {
              _setAnimationState(false);
              break;
            }
          case MicrophoneLiveIconDisableState:
            {
              _setAnimationState(false);
              break;
            }
          case MicrophoneLiveIconErrorState:
            {
              _setAnimationState(false);
              break;
            }
        }
      },
      child: BlocBuilder<MicrophoneLiveIconBloc, MicrophoneLiveIconState>(
        builder: (_, state) {
          switch (state.runtimeType) {
            case MicrophoneLiveIconLoudState:
              {
                return _buildLoud();
              }
            case MicrophoneLiveIconSilentState:
              {
                return _buildSilent();
              }
            case MicrophoneLiveIconDisableState:
              {
                return _buildDisabled();
              }
            case MicrophoneLiveIconErrorState:
              {
                return _buildError();
              }
          }
          return _buildDisabled();
        },
      ),
    );
  }

  Widget _buildContent({
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            height: 100,
            width: 100,
            child: RiveAnimation.asset(
              'assets/rive/sound.riv',
              controllers: [_controller],
            )),
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(
              color: textColor,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          height: 100,
          width: 300,
          child: Center(
            child: InkWell(
              onTap: () {
                print("arg");
                _controller.isActive = true;
//                _bloc.stopListenMicrophone();
              },
              child: Text(
                'Icon stub',
                style: TextStyle(
                  fontSize: 30,
                  fontStyle: FontStyle.italic,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisabled() {
    return _buildContent(backgroundColor: Colors.white, textColor: Colors.grey);
  }

  Widget _buildLoud() {
    return _buildContent(backgroundColor: Colors.white, textColor: Colors.green);
  }

  Widget _buildSilent() {
    return _buildContent(backgroundColor: Colors.white, textColor: Colors.black);
  }

  Widget _buildError() {
    return _buildContent(backgroundColor: Colors.yellow, textColor: Colors.red);
  }
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
