import 'dart:async';

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
  bool hasNewDevices = false;
 @override
Widget build(BuildContext context) {
  return Scaffold(
    body: GetBuilder<BluetoothController>(
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
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final data = snapshot.data![index];
                        BluetoothDevice device = data.device;

                        return GestureDetector(
                          onTap: () => _showAssociationDialog(context, device, controller),
                          child: StreamBuilder<BluetoothDeviceState>(
                            stream: device.state,
                            initialData: BluetoothDeviceState.disconnected,
                            builder: (context, deviceStateSnapshot) {
                              IconData connectionIconData = deviceStateSnapshot.data == BluetoothDeviceState.connected
                                  ? Icons.check_circle
                                  : Icons.cancel;
                              Color connectionColor = deviceStateSnapshot.data == BluetoothDeviceState.connected
                                  ? Colors.green
                                  : Colors.red;

                              return Card(
                                elevation: 2,
                                child: ListTile(
                                  leading: Icon(Icons.devices),
                                  title: Text(device.name ?? 'Unknown'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("ID: ${device.id.id}"),
                                      Text("State: ${getDeviceStateString(deviceStateSnapshot.data!)}"),
                                    ],
                                  ),
                                  trailing: Icon(
                                    connectionIconData,
                                    color: connectionColor,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  } else {
                    return Center(
                      child: Text("No devices found"),
                    );
                  }
                },
              ),
              SizedBox(height: 10),
              Text(
                hasNewDevices ? 'New devices scanned' : 'No new devices scanned',
                style: TextStyle(
                  fontSize: 18,
                  color: hasNewDevices ? Colors.green : Colors.red,
                ),
              ),
              StreamBuilder<String>(
                stream: controller.deviceAssociationResponse,
                builder: (context, snapshot) {
                  print('StreamBuilder rebuilt with snapshot: ${snapshot.data}');

                  if (snapshot.hasData) {
                    WidgetsBinding.instance!.addPostFrameCallback((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(snapshot.data!),
                        ),
                      );
                    });
                  }
                  if (snapshot.data == null) {
                    return SizedBox.shrink();
                  } else {
                    return Text(snapshot.data!);
                  }
                },
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


Future<String> _showAssociationDialog(BuildContext homeContext, BluetoothDevice device, BluetoothController controller) {
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
        completer.complete("Device ${device.name} associated successfully");
      } catch (e) {
        completer.completeError("Failed to associate with ${device.name}: $e");
        print("Error connecting to the device: $e");
      } finally {
        Navigator.of(homeContext).pop();
      }
    },
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