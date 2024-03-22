import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothController extends GetxController {
  final FlutterBlue flutterBlue = FlutterBlue.instance;

  Future<bool> isBluetoothEnabled() async {
    return await flutterBlue.isOn;
  }

  Future<void> requestBluetoothPermission() async {
    var status = await Permission.bluetooth.request();
    if (status != PermissionStatus.granted) {
      throw PlatformException(
        code: 'PERMISSION_NOT_GRANTED',
        message: 'Bluetooth permission not granted',
      );
    }
  }

  Future<void> requestBluetoothScanPermission() async {
    var status = await Permission.bluetoothScan.request();
    if (status != PermissionStatus.granted) {
      throw PlatformException(
        code: 'PERMISSION_NOT_GRANTED',
        message: 'Bluetooth scan permission not granted',
      );
    }
  }

  Stream<List<ScanResult>> scanDevices() async* {
    try {
      // Request Bluetooth permissions
      await requestBluetoothPermission();
      await requestBluetoothScanPermission();

      // Start scanning for Bluetooth devices
      await flutterBlue.startScan(timeout: Duration(seconds: 30)); // Increased scan duration to 30 seconds

      // Listen to scan results
      await for (List<ScanResult> results in flutterBlue.scanResults) {
        yield results;
      }
    } catch (e) {
      print('Error scanning for devices: $e');
      yield []; // Return an empty list in case of an error
    }
  }

  Stream<List<ScanResult>> get scanResults => flutterBlue.scanResults;
}

