import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:async';
import '../core/constants/ble_constants.dart';
import '../core/constants/database_lib.dart';
import 'package:shared_preferences/shared_preferences.dart';
class BleService {
  static const advertEnabled = true; // 1 for advert, 0 for gatt. must be consistent w/ MCU code

  // 1. Setup
  // 1a. Singleton
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription? _pipelineSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;

  // 1b. Vars
  final FlutterReactiveBle ble = FlutterReactiveBle();
  static final scanDuration = advertEnabled ? Duration(days: 100000): Duration(minutes: 20);

  final sensorServiceUUID = Uuid.parse("86b00c77-f4f3-4bbc-9f35-b8b64dd27191");
  final sensorCharacteristicUUID = Uuid.parse("af515174-df50-457d-9f08-082a4dbd8ce0");
  int companyId = 0x02FF;

  // 2. Helper Functions
  // 2a. I/O
  Future<void> saveDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ble_device_id', deviceId);
  }
  Future<String?> loadDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ble_device_id');
  }

  // 2b. Decoding
  List<int> decodeAdvertFromManufacturerData(List<int> mfgData) {
    if (mfgData.length < 2) return [];
    
    final int id =mfgData[0] | (mfgData[1] << 8);
    if (id != companyId) return [];

    // Return just the payload
    return mfgData.sublist(2);
  }

  Future<List<int>> decodeGATTFromScan(DiscoveredDevice d) async {
    if (d.serviceUuids.contains(sensorServiceUUID)) {
      print("ok\n");
      // If you want to stop scanning once you find one:
      await stopScan();
    }
    return [];
  }

  // 2c. Connection management
  Stream<DiscoveredDevice> scanStream({
      required List<Uuid> withServices,
    }) {
      return ble.scanForDevices(
        withServices: withServices,
        scanMode: ScanMode.lowLatency,
      );
  }

  Future<void> startScan() async {
    await ble.statusStream.where((s) => s == BleStatus.ready).first;

    // sensorService is not advertised for adv-based comms on MCU
    List<Uuid> services = advertEnabled ? [] : [sensorServiceUUID]; 
    final devices = scanStream(withServices: services); // or [sensorServiceUUID]

    // Pipeline: scan → filter → route by mode
    _pipelineSub = devices.listen((d) {
      if (advertEnabled) {
        _handleAdvertisingDevice(d);
      } else {
        _handleGattDevice(d);
      }
    });
  }
  
  Future<void> stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    await _pipelineSub?.cancel();
    _pipelineSub = null;
  }

  void _handleAdvertisingDevice(DiscoveredDevice d) {
    // lightweight filter here
    if (!d.name.contains("Meta")) return;

    // decoding is fully separate and pure
    final payload = decodeAdvertFromManufacturerData(d.manufacturerData);
    if (payload.isEmpty){
      print("no content in payload\n");
      return;
    } 

    final data = decodeBytes(payload); // your function
    if (data.isNotEmpty){ // this is not an error case btw. could just mean that the packet is duplicate
      print("human timestamp: ${DateFormat.Hms().format(DateTime.now())}");
      print("advert decoded: $data\n");
      //DBUtils.insertRow(data);
    }
  }

  void _handleGattDevice(DiscoveredDevice d) {
    if (!d.name.contains("Meta")) return;
    if (!d.serviceUuids.contains(sensorServiceUUID)) return;

    // push GATT connection tasks elsewhere (don’t do long async inside scan callback)
    _connectAndReadOnce(d.id);
  }
  bool _gattBusy = false;
  String? _pendingDeviceId;
  static const _gattConnectTimeout = Duration(seconds: 20);

  Future<void> _connectAndReadOnce(String deviceId) async {
    if (_gattBusy) {
      _pendingDeviceId = deviceId;
      return;
    }
    _gattBusy = true;
    try {
      final value = await connectAndReadCharacteristic(deviceId);
      //print(value);
      final decodedInfo = decodeBytes(value.sublist(4)); // this is payload
      print("human timestamp: ${DateFormat.Hms().format(DateTime.now())}");
      print("GATT decoded: $decodedInfo");
    } catch (e) {
      // No-op: transient BLE connect/disconnects are expected.
    } finally {
      _gattBusy = false;
      final pending = _pendingDeviceId;
      _pendingDeviceId = null;
      if (pending != null) {
        Future(() => _connectAndReadOnce(pending));
      }
    }
  }

  // 3. GATT Handling
  Future<List<int>> connectAndReadCharacteristic(String deviceId) async {
  // Cancel any previous connection stream to avoid overlapping connections.
  await _connSub?.cancel();
  _connSub = null;

  // Connection stream (we'll wait until connected)
  final completer = Completer<void>();

  _connSub = ble
      .connectToDevice(
        id: deviceId,
        // This helps Reactive BLE know what to discover up-front (optional but recommended)
        servicesWithCharacteristicsToDiscover: {
          sensorServiceUUID: [sensorCharacteristicUUID]
        },
        connectionTimeout: const Duration(seconds: 15),
      )
      .listen((update) async {
        //print("BLE state: ${update.connectionState}");
        if (update.connectionState == DeviceConnectionState.connected) {
          if (!completer.isCompleted) completer.complete();
        } else if (update.connectionState ==
            DeviceConnectionState.disconnected) {
          print("BLE disconnected: $deviceId");
          if (!completer.isCompleted) {
            completer.completeError(Exception("Disconnected before ready"));
          }
        }
      }, onError: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      });

    try {
      // Wait for connected (avoid hanging if the device disconnects rapidly).
      await completer.future.timeout(_gattConnectTimeout);

      // Now read the characteristic (this is where iOS will trigger pairing if required)
      final qc = QualifiedCharacteristic(
        deviceId: deviceId,
        serviceId: sensorServiceUUID,
        characteristicId: sensorCharacteristicUUID,
      );

      // iOS sometimes needs a short beat after connection/encryption;
      // do a simple retry once (very common with encrypted characteristics)
      try {
        return await ble.readCharacteristic(qc);
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 700));
        return await ble.readCharacteristic(qc);
      }
    } finally {
      await _connSub?.cancel();
      _connSub = null;
    }
  }
  // 4. Core
  // Manufacturer data is raw bytes (includes company ID in first 2 bytes)

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
