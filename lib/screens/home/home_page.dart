import 'package:blutooth_serial_sender/model/webasto_data_model.dart';
import 'package:blutooth_serial_sender/screens/home/home_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/src/provider.dart';

class HomePage extends StatefulWidget {
  static const logoAssetPath = "assets/images/logo.jpeg";

  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomePageBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<HomePageBloc>();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<HomePageBloc, HomePageState>(
        builder: (ctx, state) {
          return Scaffold(
            body: SingleChildScrollView(
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: const AssetImage(HomePage.logoAssetPath),
                      fit: BoxFit.fitWidth,
                      colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.1), BlendMode.dstATop),
                    ),
                  ),
                  child: Center(child: _buildContent(context, state)),
                ),
              ),
            ),
          );
        },
      );

  Widget _buildContent(BuildContext context, HomePageState state) {
    if (state is HomePageDisconnectedState) return _buildDisconnected(context);
    if (state is HomePageInitialState) return _buildEmpty();
    if (state is HomePageLoadingState) return _buildLoading();
    if (state is HomePageDataReadyState) return _buildData(state);

    return _buildEmpty();
  }

  Widget _buildDisconnected(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48,),
          const SizedBox(height: 24,),
          const Text(
            "Connection lost.",
            style: TextStyle(fontSize: 32, color: Colors.red),
          ),
          const SizedBox(height: 64,),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Back to connect page"),),
        ],
      ),
    );
  }

  Widget _buildData(HomePageDataReadyState state) => Align(
        alignment: const Alignment(-1, -1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 36),
            _buildValuedRow(title: "Voltage", value: (state.model.milliVolts / 100).toStringAsFixed(2), postfix: "v"),
            const Divider(thickness: 1),
            _buildValuedRow(title: "Temperature", value: state.model.temperatureCelsius.toString(), postfix: "°"),
            const Divider(thickness: 1),
            const SizedBox(height: 32),
            _buildIndicatorsArea(state.model),
            _buildButtonsRow(),
            const SizedBox(height: 48),
          ],
        ),
      );

  Widget _buildButtonsRow() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: _bloc.onButton1Pressed, child: const Text("Webasto on")),
            ElevatedButton(onPressed: _bloc.onButton2Pressed, child: const Text("Webasto off")),
          ],
        ),
        const SizedBox(
          height: 16,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: _bloc.onButton3Pressed, child: const Text("Water pump on")),
            ElevatedButton(onPressed: _bloc.onButton4Pressed, child: const Text("Water pump off")),
          ],
        ),
      ],
    );
  }

  Widget _buildIndicatorsArea(WebastoDataModel model) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildValuedIndicator(model.isWebastoOnline, title: "Webasto"),
        _buildValuedIndicator(model.isFuelPumpWorking, title: "Fuel pump"),
        _buildValuedIndicator(model.isFanWorking, title: "Fan"),
        _buildValuedIndicator(model.isWaterPumpWorking, title: "Water pump"),
      ],
    );
  }

  Widget _buildValuedIndicator(bool isActive, {required String title}) => Row(
        children: [
          SizedBox(
            height: 60,
            width: 60,
            child: FittedBox(
              child: Radio(
                value: isActive,
                groupValue: true,
                onChanged: (_) {},
              ),
            ),
          ),
          Text(title),
        ],
      );

  Widget _buildValuedRow({
    String postfix = "",
    required String value,
    required String title,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$value$postfix",
              style: const TextStyle(fontSize: 48),
            ),
            Text(title),
          ],
        ),
      );

  Widget _buildEmpty() => const SizedBox.shrink();

  Widget _buildLoading() => const CircularProgressIndicator();
}
