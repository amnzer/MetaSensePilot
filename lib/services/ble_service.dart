import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:typed_data';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();
  List<double> glucoseReadings = [];
  final Set<DeviceIdentifier> _nobodyGaf = {};
  var myUuid = Guid("1801");
  int companyId = 0x02FF;
  void startScan() async {
    await FlutterBluePlus.adapterState.where((val) => val == BluetoothAdapterState.on).first;
    print("Starting BLE scan...");
    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));
    FlutterBluePlus.scanResults.listen((results) {
      for (var r in results) {
        if (!_nobodyGaf.contains(r.device.remoteId)){
          //print("  Connectable: ${adv.connectable}");
          //print("  Service UUIDs: ${adv.serviceUuids}");
          // firstly check if it's metameta
          var adv = r.advertisementData;
          //if (!adv.serviceUuids.contains(myUuid)) {
          //  _nobodyGaf.add(r.device.remoteId); // not metasense
          //  continue;
          //}
          // if metameta (or, if anything)
          if (r.device.advName.contains("Meta")){
            print("Device: ${r.device.advName} (${r.device.remoteId})");
            //print("Device found: ${r.device.advName} (${r.device.remoteId})");
            print("  RSSI: ${r.rssi}");
            //print("uuids${adv.serviceUuids}");       // contains your UUID
            //print("service data${adv.serviceData}"); 
            var mdata = adv.manufacturerData;
            print("Manufacturer Data: ${adv.manufacturerData}");
            if (mdata.containsKey(companyId)) {
              List<int> bytes = mdata[companyId]!; // get raw byte array
              if (bytes.length >= 4) {
                print(bytes);
                var floatval = decodeBytes(bytes);
                print("Received this value: $floatval");
                // convert first 4 bytes to float
              }
            }
        
            //var byteStream = adv.serviceData[myUuid];
            //print("Byte stream len: ${byteStream?.length}");
            //if (byteStream != null && byteStream.length >= 4) {
            //  print("Got valid bytes from Meta device.");
            //}
            //else{
            //  print("Invalid byte stream from Meta device.");
            //}
            print(" "); // \n getting ignored
          //print("  Manufacturer Data: ${adv.manufacturerData}");
          }
      } 
      }
    });
  }
  Map<String, num> decodeBytes(List<int> sensorbytes){

    // it is known that bytes will be at least 4 long. 
    // here's the current way to encode.
    final glucoseBytes = sensorbytes.sublist(0, 4);
    final bytes = Uint8List.fromList(glucoseBytes);
    final byteData = ByteData.sublistView(bytes);
    double glucoseValue = byteData.getFloat32(0,Endian.little);
    
    var allSensorData = {"glucose": glucoseValue};
    
    return allSensorData;
    
  }
}