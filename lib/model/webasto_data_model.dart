class WebastoDataModel {
  final int milliVolts;
  final int temperatureCelsius;
  final bool isFuelPumpWorking;
  final bool isWaterPumpWorking;
  final bool isFanWorking;
  final bool isWebastoOnline;

  WebastoDataModel({
    required this.milliVolts,
    required this.temperatureCelsius,
    required this.isFuelPumpWorking,
    required this.isWaterPumpWorking,
    required this.isFanWorking,
    required this.isWebastoOnline,
  });

  factory WebastoDataModel.fromString(String raw) {
    final values = raw.replaceAll("\r", "").replaceAll("\n", "").split(",");
    final bool webastoOnline = values[0] == "1";
    final bool fanWorking = values[1] == "1";
    final bool fuelPumpWorking = values[2] == "1";
    final bool waterPumpWorking = values[3] == "1";
    final int voltage = int.parse(values[4]);
    final int temperature = int.parse(values[5]);
    return WebastoDataModel(
      milliVolts: voltage,
      temperatureCelsius: temperature,
      isFanWorking: fanWorking,
      isFuelPumpWorking: fuelPumpWorking,
      isWaterPumpWorking: waterPumpWorking,
      isWebastoOnline: webastoOnline,
    );
  }


  @override
  String toString() {
    final String webastoOnline = isWebastoOnline ? "1" : "0";
    final String fanWorking =  isFanWorking ? "1" : "0";
    final String fuelPumpWorking =  isFuelPumpWorking ? "1" : "0";
    final String waterPumpWorking =  isWaterPumpWorking ? "1" : "0";
    final String voltage = milliVolts.toString();
    final String temperature = temperatureCelsius.toString();
    return "$webastoOnline,$fanWorking,$fuelPumpWorking,$waterPumpWorking,$voltage,$temperature";
  }
}
