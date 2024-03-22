import 'package:chedly_pfe_bluetooth/BluetoothController.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}
class _HomeState extends State<Home> {
  final BluetoothController _bluetoothController = Get.put(BluetoothController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<BluetoothController>(
        init: _bluetoothController,
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
                SizedBox(height: 10,),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Check if Bluetooth is enabled, if not, enable it
                      bool isBluetoothEnabled = await controller.isBluetoothEnabled();
                      if (!isBluetoothEnabled) {
                        print('Bluetooth is not enabled');
                        return; // Stop further execution if Bluetooth is not enabled
                      }

                      // Proceed with scanning for devices
                      try {
                        await controller.requestBluetoothScanPermission();
                        controller.scanDevices();
                      } catch(e) {
                        print('Error starting scan: $e');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      minimumSize: Size(350, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                    child: Text("Scan", style: TextStyle(fontSize: 18),),
                  ),
                ),
                SizedBox(height: 10,),
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
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      print("No data received from scanResults stream");
                      return Center(
                        child: Text("No devices found"),
                      );
                    } else {
                      print("Received ${snapshot.data!.length} devices");
                      return Column(
                        children: [
                          Text(
                            "Found ${snapshot.data!.length} devices",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: ListTileTheme(
                              tileColor: Colors.blueGrey.shade100,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) {
                                  final data = snapshot.data![index];
                                  return Card(
                                    elevation: 2,
                                    child: ListTile(
                                      title: Text(data.device.name ?? 'Unknown'), // Handling null device name
                                      subtitle: Text(data.device.id.id),
                                      trailing: Text(data.rssi.toString()),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}