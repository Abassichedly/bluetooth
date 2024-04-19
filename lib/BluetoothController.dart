import 'dart:async';

import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';

class BluetoothController extends GetxController {
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  bool isScanning = false;
  Timer? scanTimer;
  final associationResponse = ''.obs;


  // Stream controller for device association response
  final _deviceAssociationResponse = ''.obs;
  Stream<String> get deviceAssociationResponse => _deviceAssociationResponse.stream;

  // Method to update device association response
  void updateAssociationResponse(String message) {
    print('Updating association response: $message');
    associationResponse.value = message;
  }

  // Method to scan for Bluetooth devices
  Future<void> scanDevices() async {
    if (!isScanning) {
      isScanning = true;
      updateScanStatus();
      scanTimer = Timer(const Duration(seconds: 30), () {
        isScanning = false;
        flutterBlue.stopScan();
        updateScanStatus();
      });
      flutterBlue.startScan(timeout: const Duration(seconds: 30));
    }
  }

  // Method to stop scanning for Bluetooth devices
  Future<void> stopScan() async {
    scanTimer?.cancel();
    isScanning = false;
    flutterBlue.stopScan();
    updateScanStatus();
  }

  // Method to update the scan status
  void updateScanStatus() {
    update();
  }

  // Stream of scan results
  Stream<List<ScanResult>> get scanResults => flutterBlue.scanResults;
}