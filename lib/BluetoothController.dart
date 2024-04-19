import 'dart:async';

import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';

class BluetoothController extends GetxController {
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  bool isScanning = false;
  Timer? scanTimer;
  final associationResponse = ''.obs;
BluetoothCharacteristic? _selectedCharacteristic;

  void updateCharacteristic(BluetoothCharacteristic characteristic) {
    _selectedCharacteristic = characteristic;
    _startListeningForNotifications();
  }

  Future<void> _startListeningForNotifications() async {
    if (_selectedCharacteristic == null || !_selectedCharacteristic!.isNotifying) {
      try {
        await _selectedCharacteristic!.setNotifyValue(true);
        _selectedCharacteristic!.value.listen((value) {
          // Handle received data here
          print('Received data: ${value.toString()}');
        });
      } catch (e) {
        updateAssociationResponse("Failed to start listening for notifications: $e");
      }
    }
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

  // Method to update the association response
  void updateAssociationResponse(String message) {
    associationResponse.value = message;
  }

  // Stream of scan results
  Stream<List<ScanResult>> get scanResults => flutterBlue.scanResults;
}