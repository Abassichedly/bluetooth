import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import 'BluetoothController.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => Column(
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
                  // Check location permission
                  var locationStatus = await Permission.location.status;
                  if (!locationStatus.isGranted) {
                    // If location permission is not granted, show warning dialog
                    showPermissionDeniedDialog(context, "Location");
                    return;
                  }

                  // Check Bluetooth status
                  bool isBluetoothOn = await FlutterBlue.instance.isOn;
                  if (!isBluetoothOn) {
                    // If Bluetooth is off, show warning dialog
                    showBluetoothOffDialog(context);
                    return;
                }

                  // If everything is okay, start scanning
                  Get.find<BluetoothController>().scanDevices();
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
                  "Scan",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            SizedBox(height: 10),
            StreamBuilder<List<ScanResult>>(
              stream: Get.find<BluetoothController>().scanResults,
              builder: (context, snapshot) {
                if (snapshot.data != null && snapshot.data!.isNotEmpty) {
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final data = snapshot.data![index];
                      BluetoothDevice device = data.device;

                      return GestureDetector(
                        onTap: () => _showAssociationDialog(context, device, Get.find<BluetoothController>()),
                        child: StreamBuilder<BluetoothDeviceState>(
                          stream: device.state,
                          initialData: BluetoothDeviceState.disconnected,
                          builder: (context, deviceStateSnapshot) {
                            IconData connectionIconData =
                                deviceStateSnapshot.data == BluetoothDeviceState.connected
                                    ? Icons.check_circle
                                    : Icons.cancel;
                            Color connectionColor =
                                deviceStateSnapshot.data == BluetoothDeviceState.connected
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
                                    Text(
                                        "State: ${getDeviceStateString(deviceStateSnapshot.data!)}"),
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
            StreamBuilder<String>(
              stream: Get.find<BluetoothController>().deviceAssociationResponse,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  // Show a SnackBar to display the response message to the user
                  WidgetsBinding.instance!.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(snapshot.data!),
                      ),
                    );
                  });
                }
                // Return an empty SizedBox to avoid displaying anything when there's no data
                return SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
      // Snackbar to display feedback
      bottomNavigationBar: GetBuilder<BluetoothController>(
        init: BluetoothController(),
        builder: (controller) {
          return SizedBox.shrink();
        },
      ),
    );
  }

  void _showAssociationDialog(BuildContext context, BluetoothDevice device, BluetoothController controller) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      title: 'Associate Device',
      desc: 'Do you want to associate with ${device.name}?',
btnCancelOnPress: () {
        Navigator.of(context).pop();
      },
      btnOkOnPress: () async {
        // Connect to the device
        try {
          await device.connect();
          // Perform actions after successful connection
          controller.updateAssociationResponse("Device ${device.name} associated successfully");
        } catch (e) {
          controller.updateAssociationResponse("Failed to associate with ${device.name}: $e");
          print("Error connecting to the device: $e");
        }
        Navigator.of(context).pop();
      },
    ).show();
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
        Navigator.of(context).pop();
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
        Navigator.of(context).pop();
      },
    ).show();
  }
}
