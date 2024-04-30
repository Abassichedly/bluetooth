import 'dart:async';
import 'package:chedly_pfe_bluetooth/BluetoothController.dart';
import 'package:chedly_pfe_bluetooth/UuidHelper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class Devices extends StatefulWidget {

  const Devices({Key? key});

  @override
  State<Devices> createState() => _DevicesState();
}

class _DevicesState extends State<Devices> {
  final Color color = Color(0xFF199F97);
  final Color textColor = Color(0xFF0C266E);
  final Color cardColor = Color(0xFF60C2D0);
  List<BluetoothDevice> scannedDevices = [];
  List<Map<String, dynamic>> lastScannedDevices = []; // List to store last scanned devices with UID and status
  bool hasNewDevices = false;


@override
Widget build(BuildContext context) {
  return Scaffold(
    body: GetBuilder<BluetoothController>(
      init: BluetoothController(),
      builder: (controller) {
        return SingleChildScrollView(
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(80),
                        bottomRight: Radius.circular(80),
                      ),
                      color: color,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 30, 15, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "   Home \n      Devices \n          Scanner",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Image.asset(
                              'assets/logo.png',
                              height: 120,
                              width: 120,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 210),
              Padding(
                padding: const EdgeInsets.only(top: 220),
                child: Center(
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
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(top: 290, left: 20),
                child: StreamBuilder<List<ScanResult>>(
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

                      // No need to send data here
                    } else {
                      // Scanning process finished, add scanned devices to lastScannedDevices
                      scannedDevices.forEach((device) {
                        if (!lastScannedDevices.any((Map<String, dynamic> item) => item['device'].id == device.id)) {
                          lastScannedDevices.add({
                            'device': device,
                            'uid': '', // Assuming uid is empty here, replace it with the actual value if needed
                            'status': '', // Initialize status as empty
                          });
                        }
                      });
                      scannedDevices.clear();
                      hasNewDevices = false;

                      // Send updated devices to backend here
                      if (lastScannedDevices.isNotEmpty) {
                        sendDevicesToBackend(lastScannedDevices);
                      }
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
                                  final deviceDetails = lastScannedDevices[index];
                                  final BluetoothDevice device = deviceDetails['device'];
                                  final String uid = deviceDetails['uid'];
                                  final String status = deviceDetails['status']; // Get status directly from the map
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
                                            Text("UID: $uid"),
                                            Row(
                                              children: [
                                                Text('Status: $status'), // Use status from the map directly
                                                SizedBox(width: 5),
                                                Icon(
                                                  status == 'connected' ? Icons.check_circle : Icons.cancel,
                                                  color: status == 'connected' ? Colors.green : Colors.red,
                                                ),
                                              ],
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
              ),
            ],
          ),
        );
      },
    ),
    bottomNavigationBar: GetBuilder<BluetoothController>(
      init: BluetoothController(),
      builder: (controller) {
        return SizedBox.shrink();
      },
    ),
  );
}


  Future<String> _showAssociationDialog(BuildContext DevicesContext, BluetoothDevice device, BluetoothController controller) async {
    Completer<String> completer = Completer<String>();

    AwesomeDialog(
      context: DevicesContext,
      dialogType: DialogType.info,
      title: 'Associate Device',
      desc: 'Do you want to associate with ${device.name}?',
      btnCancelOnPress: () {
        completer.complete("Association canceled");
        Navigator.of(DevicesContext).pop();
      },
      btnOkOnPress: () async {
        try {
          await device.connect();

          // Listen to changes in device state after attempting to connect
          StreamSubscription<BluetoothDeviceState>? stateSubscription;
          stateSubscription = device.state.listen((state) {
            if (state == BluetoothDeviceState.connected) {
              controller.updateAssociationResponse("Device ${device.name} associated successfully");
              // Update status in lastScannedDevices
              final deviceIndex = lastScannedDevices.indexWhere((item) => item['device'].id == device.id);
              if (deviceIndex != -1) {
                setState(() {
                  lastScannedDevices[deviceIndex]['status'] = state;
                });
              }
              stateSubscription?.cancel();
            } else if (state == BluetoothDeviceState.disconnected) {
              controller.updateAssociationResponse("Failed to associate with device ${device.name}");
              // Update status in lastScannedDevices
              final deviceIndex = lastScannedDevices.indexWhere((item) => item['device'].id == device.id);
              if (deviceIndex != -1) {
                setState(() {
                  lastScannedDevices[deviceIndex]['status'] = state;
                });
              }
              stateSubscription?.cancel();
            }
          });

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
          Navigator.of(DevicesContext).pop();
        } catch (e) {
          controller.updateAssociationResponse("Failed to associate with device ${device.name}");
          completer.complete("Association failed: $e");
        }
      },
      width: MediaQuery.of(DevicesContext).size.width * 0.75,
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
Future<void> sendDevicesToBackend(List<Map<String, dynamic>> devices) async {
  String apiUrl = 'http://192.168.184.239:5000/devices';

  try {
    // Convert devices list to JSON format
    List<Map<String, dynamic>> devicesJson = devices.map((device) => {
      'id': device['device'].id.id,
      'name': device['device'].name != null ? device['device'].name :'Unknown',
      'uid': device['uid'],
      'status': device['status'] != null ? device['status'].toString().split('.').last : 'unknown', // Ensure status is not null
    }).toList();

    // Send POST request to backend
    var response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(devicesJson),
    );

    if (response.statusCode == 200) {
      print("Devices updated successfully");
    } else {
      print("Failed to update devices: ${response.statusCode} , ${response.body}");
    }
  } catch (e) {
    print("Error sending devices data: $e");
  }
}
}