import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothController extends GetxController {
  final FlutterBlue flutterBlue = FlutterBlue.instance;

  Future scanDevices() async {
    // Start scanning for Bluetooth devices
    flutterBlue.startScan(
        timeout:
            Duration(seconds: 30)); // Increased scan duration to 30 seconds
    flutterBlue.stopScan();
  }

  Stream<List<ScanResult>> get scanResults => flutterBlue.scanResults;
}
