import 'dart:async';

import 'package:chedly_pfe_bluetooth/UuidHelper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'BluetoothController.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<BluetoothDevice> scannedDevices = [];
  List<BluetoothDevice> lastScannedDevices = []; // List to store last scanned devices
  bool hasNewDevices = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: GetBuilder<BluetoothController>(
          init: BluetoothController(),
          builder: (controller) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: 180,
                    color: Colors.blue,
                    child: Center(
                      child: Text(
                        "Bluetooth Screen",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        var locationStatus = await Permission.location.status;
                        if (locationStatus.isDenied || locationStatus.isPermanentlyDenied) {
                          var result = await Permission.location.request();
                          if (result != PermissionStatus.granted) {
                            showPermissionDeniedDialog(context, "Location");
                            return;
                          }
                        }

                        if (!await Geolocator.isLocationServiceEnabled()) {
                          showLocationOffDialog(context);
                          return;
                        }

                        bool isBluetoothOn = await FlutterBlue.instance.isOn;
                        if (!isBluetoothOn) {
                          showBluetoothOffDialog(context);
                          return;
                        }
                        controller.scanDevices();
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        minimumSize: Size(350, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                      child: Text(
                        controller.isScanning ? 'Scanning...' : 'Scan',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  StreamBuilder<List<ScanResult>>(
                    stream: controller.scanResults,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text("Error: ${snapshot.error}"),
                        );
                      } else if (snapshot.data != null && snapshot.data!.isNotEmpty) {
                        scannedDevices.clear();
                        snapshot.data!.forEach((result) {
                          scannedDevices.add(result.device);
                        });
                        hasNewDevices = true;
                      } else {
                        // Scanning process finished, add scanned devices to lastScannedDevices
                        scannedDevices.forEach((device) {
                          if (!lastScannedDevices.any((lastDevice) => lastDevice.id == device.id)) {
                            lastScannedDevices.add(device);
                          }
                        });
                        scannedDevices.clear();
                        hasNewDevices = false;
                      }

                      return Column(
                        children: [
                          Text(
                            hasNewDevices ? 'New devices scanned' : 'No new devices scanned',
                            style: TextStyle(
                              fontSize: 18,
                              color: hasNewDevices ? Colors.green : Colors.red,
                            ),
                          ),
                          SizedBox(height: 10),
                          if (scannedDevices.isNotEmpty)
                            Column(
                              children: [
                                Text(
                                  'Newly Scanned Devices:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),
                                ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: scannedDevices.length,
                                  itemBuilder: (context, index) {
                                    final device = scannedDevices[index];
                                    return GestureDetector(
                                      onTap: () async {
                                        String result = await _showAssociationDialog(context, device, controller);
                                        print(result);
                                      },
                                      child: Card(
                                        elevation: 2,
                                        child: ListTile(
                                          leading: Icon(Icons.devices),
                                          title: Text(device.name ?? 'Unknown'),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("ID: ${device.id.id}"),
                                              StreamBuilder<BluetoothDeviceState>(
                                                stream: device.state,
                                                initialData: BluetoothDeviceState.disconnected,
                                                builder: (context, deviceStateSnapshot) {
                                                  IconData connectionIconData = deviceStateSnapshot.data == BluetoothDeviceState.connected
                                                      ? Icons.check_circle
                                                      : Icons.cancel;
                                                  Color connectionColor = deviceStateSnapshot.data == BluetoothDeviceState.connected
                                                      ? Colors.green
                                                      : Colors.red;
                                                  String status = getDeviceStateString(deviceStateSnapshot.data!);
                                                  return Row(
                                                    children: [
                                                      Text('Status: $status'),
                                                      SizedBox(width: 5),
                                                      Icon(connectionIconData, color: connectionColor),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          SizedBox(height: 10),
                          if (lastScannedDevices.isNotEmpty)
                            Column(
                              children: [
                                Text(
                                  'Last Scanned Devices:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),
                                ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: lastScannedDevices.length,
                                  itemBuilder: (context, index) {
                                    final device = lastScannedDevices[index];
                                    return GestureDetector(
                                      onTap: () => _showAssociationDialog(context, device, controller),
                                      child: Card(
                                        elevation: 2,
                                        child: ListTile(
                                          leading: Icon(Icons.devices),
                                          title: Text(device.name ?? 'Unknown'),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("ID: ${device.id.id}"),
                                              StreamBuilder<BluetoothDeviceState>(
                                                stream: device.state,
                                                initialData: BluetoothDeviceState.disconnected,
                                                builder: (context, deviceStateSnapshot) {
                                                  IconData connectionIconData = deviceStateSnapshot.data == BluetoothDeviceState.connected
                                                      ? Icons.check_circle
                                                      : Icons.cancel;
                                                  Color connectionColor = deviceStateSnapshot.data == BluetoothDeviceState.connected
                                                      ? Colors.green
                                                      : Colors.red;
                                                  String status = getDeviceStateString(deviceStateSnapshot.data!);
                                                  return Row(
                                                    children: [
                                                      Text('Status: $status'),
                                                      SizedBox(width: 5),
                                                      Icon(connectionIconData, color: connectionColor),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            Obx(
                () => Text(
                  controller.associationResponse.value,
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: GetBuilder<BluetoothController>(
        init: BluetoothController(),
        builder: (controller) {
          return SizedBox.shrink();
        },
      ),
    );
  }

  Future<String> _showAssociationDialog(BuildContext homeContext, BluetoothDevice device, BluetoothController controller) async {
  Completer<String> completer = Completer<String>();

  AwesomeDialog(
    context: homeContext,
    dialogType: DialogType.info,
    title: 'Associate Device',
    desc: 'Do you want to associate with ${device.name}?',
    btnCancelOnPress: () {
      completer.complete("Association canceled");
      Navigator.of(homeContext).pop();
    },
    btnOkOnPress: () async {
      try {
        await device.connect();

        // Listen to changes in device state after attempting to connect
        StreamSubscription<BluetoothDeviceState>? stateSubscription;
        stateSubscription = device.state.listen((state) {
          if (state == BluetoothDeviceState.connected) {
            controller.updateAssociationResponse("Device ${device.name} associated successfully");
            stateSubscription?.cancel();
          } else if (state == BluetoothDeviceState.disconnected) {
            controller.updateAssociationResponse("Failed to associate with device ${device.name}");
            stateSubscription?.cancel();
          }
        });

        // Start listening for notifications
        device.discoverServices().then((services) {
          services.forEach((service) {
            if (service.uuid.toString() == UuidHelper.lightServiceUuid) {
              service.characteristics.forEach((characteristic) {
                if (characteristic.uuid.toString() == UuidHelper.lightCharacteristicUuid) {
                  controller.updateCharacteristic(characteristic);
                }
              });
            }
          });
        });

        completer.complete("Device associated successfully");
        Navigator.of(homeContext).pop();
      } catch (e) {
        controller.updateAssociationResponse("Failed to associate with device ${device.name}");
        completer.complete("Association failed: $e");
      }
    },
    width: MediaQuery.of(homeContext).size.width * 0.75,
  ).show();

  return completer.future;
}

  String getDeviceStateString(BluetoothDeviceState state) {
    switch (state) {
      case BluetoothDeviceState.connected:
        return "Connected";
      case BluetoothDeviceState.disconnected:
        return "Disconnected";
      case BluetoothDeviceState.connecting:
        return "Connecting";
      case BluetoothDeviceState.disconnecting:
        return "Disconnecting";
      default:
        return "Unknown";
    }
  }

  void showPermissionDeniedDialog(BuildContext context, String permissionName) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      title: 'Permission Denied',
      desc: 'Please grant $permissionName permission to proceed.',
      btnOkText: 'OK',
      btnOkOnPress: () {
        // Do nothing when OK is pressed
      },
    ).show();
  }

  void showBluetoothOffDialog(BuildContext context) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      title: 'Bluetooth Off',
      desc: 'Please turn on Bluetooth to proceed.',
      btnOkText: 'OK',
      btnOkOnPress: () {
        // Do nothing when OK is pressed
      },
    ).show();
  }

  void showLocationOffDialog(BuildContext context) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      title: 'Location Off',
      desc: 'Please turn on location services to proceed.',
      btnOkText: 'OK',
      btnOkOnPress: () {
        // Do nothing when OK is pressed
      },
    ).show();
  }

}