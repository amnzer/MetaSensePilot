import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:typed_data';
import '../core/constants/ble_constants.dart';
import '../core/constants/database_lib.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();
  List<double> glucoseReadings = [];
  //final Set<DeviceIdentifier> _nobodyGaf = {};
  var myUuid = Guid("1801");
  int companyId = 0x02FF;

  
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
          // prints
          //print("Device: ${r.device.advName} (${r.device.remoteId})");
          //print("  RSSI: ${r.rssi}");
          //print("Manufacturer Data: ${adv.manufacturerData}");
          
          // decode
          var mdata = adv.manufacturerData;
          if (mdata.containsKey(companyId)) {
            List<int> bytes = mdata[companyId]!; // get raw byte array
            if (bytes.length >= 4) { // this is basically implied
              //print(bytes);
              var data = decodeBytes(bytes);
              if (data.isNotEmpty){
                print("Decoded transmission: $data");
                DBUtils.insertRow(data); // write to db!
                //print("Wrote to db!");
              }
              
            }
          }
          print(" "); // \n getting ignored
        }
      }
    });
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