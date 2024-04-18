import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';

class BluetoothController extends GetxController {
  final FlutterBlue flutterBlue = FlutterBlue.instance;

  // Stream controller for device association response
  final _deviceAssociationResponse = ''.obs;
  Stream<String> get deviceAssociationResponse => _deviceAssociationResponse.stream;

  // Method to update device association response
  void updateAssociationResponse(String response) {
    _deviceAssociationResponse.value = response;
  }

  // Method to scan for Bluetooth devices
  Future<void> scanDevices() async {
    // Start scanning for Bluetooth devices
    flutterBlue.startScan(timeout: Duration(seconds: 30));
    flutterBlue.stopScan();
  }
    Stream<List<ScanResult>> get scanResults => flutterBlue.scanResults;

}
