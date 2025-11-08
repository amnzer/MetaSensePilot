import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();
  List<double> glucoseReadings = [];
  final Set<DeviceIdentifier> _seenDeviceIds = {};

  void startScan() async {
    await FlutterBluePlus.adapterState.where((val) => val == BluetoothAdapterState.on).first;
    print("Starting BLE scan...");
    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));
    FlutterBluePlus.scanResults.listen((results) {
      for (var r in results) {
        if (r.device.advName.isNotEmpty && !_seenDeviceIds.contains(r.device.remoteId)){
          _seenDeviceIds.add(r.device.remoteId);
          print("Device found: ${r.device.advName} (${r.device.remoteId})");
          print("  RSSI: ${r.rssi}");
          print("  Connectable: ${r.advertisementData.connectable}");
          print("  Service UUIDs: ${r.advertisementData.serviceUuids}");
      }
      }
    });
  }
}