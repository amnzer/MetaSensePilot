class BLE{
  // debug parameters
  static const WRITE_ENABLED = false; // debug parameter
  // lookup and inverse lookups (add more values as sensor count grows)
  static final Map<(int, int), String> sensorIDToName = {
      (0,1): "glucose"
  };
  static final Map<String, (int, int)> sensorNameToID = sensorIDToName.map((k,v) => MapEntry(v,k));
  // database columns
  static const columnNames = ["sensor1", "sensor2", "sensor3", "sensor4"];
  // BLE reading parameters
  static int lastTransmissionNum = -1; // store "chapter"
  static Set<int> pages = {}; // one through whatever
}