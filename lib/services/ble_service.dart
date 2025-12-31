import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:typed_data';
import '../core/constants/ble_constants.dart';
import '../core/constants/database_lib.dart';
import 'package:shared_preferences/shared_preferences.dart';
class BleService {
  // 1. Flags + singleton setup
  static const advertEnabled = false; // 1 for advert, 0 for gatt. must be consistent w/ MCU code
  static final scanDuration = advertEnabled ? Duration(days: 100000): Duration(minutes: 20);
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();
  //final Set<DeviceIdentifier> _nobodyGaf = {};
  // 2. Helper Functions
  // 2a. Vars
  var sensorServiceUUID = Guid("86b00c77-f4f3-4bbc-9f35-b8b64dd27191");
  var sensorCharacteristicUUID = Guid("af515174-df50-457d-9f08-082a4dbd8ce0");
  int companyId = 0x02FF;
  // 2.b Establishing connections
  Future<void> saveDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ble_device_id', deviceId);
  }
  Future<String?> loadDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ble_device_id');
  }


  // 3. Decoding Functions
  List<int> decodeAdvert(AdvertisementData adv) {
      var mdata = adv.manufacturerData;
      if (mdata.containsKey(companyId)) {
        List<int> bytes = mdata[companyId]!; // raw byte array
        return bytes;
      }
      return [];
  }
  Future<List<int>> decodeGATT(ScanResult r) async{
    //print(r.advertisementData.serviceUuids);
    //print(r.advertisementData.serviceUuids[0].runtimeType);
    if (r.advertisementData.serviceUuids.contains(sensorServiceUUID)) {
      // You found a candidate
      print("ok\n");
      //print("Found: ${r.device.platformName}  id=${r.device.remoteId}\n");
    }
    var target = r.device;
    await FlutterBluePlus.stopScan();
    return [];
  }
  // 4. Core
  void startScan() async {
    var currentState = await FlutterBluePlus.adapterState.first;
    print("Current adapter state: $currentState");

    await FlutterBluePlus.adapterState
    .where((val) => val == BluetoothAdapterState.on).first;

    print("Starting BLE scan...");
    FlutterBluePlus.startScan(); // no timeout now
    FlutterBluePlus.scanResults.listen((results) {
      for (var r in results) {
        var adv = r.advertisementData;
        if (r.device.advName.contains("Meta")){
          //Rprint(r.device.advName);
          var bytes = advertEnabled ? decodeAdvert(adv) : decodeGATT(r);
          if (bytes.isNotEmpty){
            var data = decodeBytes(bytes);
            print("Decoded transmission: $data\n");
             // DBUtils.insertRow(data);
          }
              
          }
          // print(" "); // \n getting ignored
        }
      }
    );
  }

  Map<String, num> decodeBytes(List<int> sensorbytes){
    // get uniqueness identifiers
    final chpg = sensorbytes[0];
    final chapter = (chpg>>4)&0x0F;
    final page = chpg&0x0F;
    // reset  
    if (chapter != BLE.lastTransmissionNum){
      BLE.lastTransmissionNum = chapter;
      BLE.pages = {};
    }
    // get data
    if (!BLE.pages.contains(page)){
      // extraction and conversion
      final sensor1raw = sensorbytes.sublist(1, 5);
      final sensor2raw = sensorbytes.sublist(5, 9);
      final sensor3raw = sensorbytes.sublist(9, 13);
      final sensor4raw = sensorbytes.sublist(13,17);

      final sensor1bytes = Uint8List.fromList(sensor1raw);
      final sensor2bytes = Uint8List.fromList(sensor2raw);
      final sensor3bytes = Uint8List.fromList(sensor3raw);
      final sensor4bytes = Uint8List.fromList(sensor4raw);

      final sensor1data = ByteData.sublistView(sensor1bytes).getFloat32(0,Endian.little); 
      final sensor2data = ByteData.sublistView(sensor2bytes).getFloat32(0,Endian.little);
      final sensor3data = ByteData.sublistView(sensor3bytes).getFloat32(0,Endian.little);
      final sensor4data = ByteData.sublistView(sensor4bytes).getFloat32(0,Endian.little);

      final sensorDatas = [sensor1data, sensor2data, sensor3data, sensor4data];
      
      // write
      Map<String,num> allSensorData = {"timestamp": DateTime.now().millisecondsSinceEpoch,"page":page};

      for (var i=0; i<4; i++){
        if (sensorDatas[i]!=0){
          allSensorData[DBUtils.columnNames[i+2]] = sensorDatas[i]; // first 2 cols are timestamp and page
        }
      }
      // only have non-zero readings
      //print(sensor1data);
      BLE.pages.add(page);
      return allSensorData;
    }
    return {};
  }
}
          // prints
          //print("Device: ${r.device.advName} (${r.device.remoteId})");
          //print("  RSSI: ${r.rssi}");
          //print("Manufacturer Data: ${adv.manufacturerData}");
          
          // decode


          Future<T> retryOnce<T>(Future<T> Function() op) async {
  try {
    return await op();
  } catch (_) {
    await Future.delayed(const Duration(milliseconds: 700));
    return await op();
  }
}

Future<void> connectAndBond() async {
  // 1) Scan + pick device advertising the service
  BluetoothDevice? target;

  final sub = FlutterBluePlus.scanResults.listen((results) async {
    for (final r in results) {
      if (r.advertisementData.serviceUuids.contains(sensorServiceUUID)) {
        target = r.device;
        await FlutterBluePlus.stopScan();
        break;
      }
    }
  });
  
  await FlutterBluePlus.startScan(
    // On iOS this filter isn't always strict, but it helps.
    withServices: [sensorServiceUUID],
    timeout: const Duration(seconds: 10),
  );
  
  await sub.cancel();

  if (target == null) {
    throw Exception("No device found advertising sensorServiceUUID");
  }

  final device = target!;

  // 2) Ensure clean connection state
  try {
    await device.disconnect();
  } catch (_) {}

  await device.connect(
    autoConnect: false,
    timeout: const Duration(seconds: 15),
  );

  // 3) Discover services/characteristics
  final services = await device.discoverServices();

  final service = services.firstWhere(
    (s) => s.uuid == sensorServiceUUID,
    orElse: () => throw Exception("Service not found after connect"),
  );

  final ch = service.characteristics.firstWhere(
    (c) => c.uuid == sensorCharacteristicUUID,
    orElse: () => throw Exception("Characteristic not found after connect"),
  );

  // 4) Trigger iOS pairing/bonding:
  //    do a protected read first (usually triggers pairing UI)
  final bytes = await retryOnce(() => ch.read());
  print("Secure read OK: $bytes");

  // 5) Now enable notify (CCCD write may also require encryption)
  if (!(ch.properties.notify || ch.properties.indicate)) {
    throw Exception("Characteristic does not support notify/indicate");
  }

  await retryOnce(() => ch.setNotifyValue(true));
  print("Notify enabled");

  // 6) Listen for notifications
  ch.lastValueStream.listen((value) {
    print("Notify: $value");
  });

  // Optional: keep connection alive; handle disconnects in a real app
}