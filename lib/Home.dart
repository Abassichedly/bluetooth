import 'dart:convert';
import 'dart:developer';

import 'package:chedly_pfe_bluetooth/BluetoothController.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

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
                  SizedBox(
                    height: 10,
                  ),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => controller.scanDevices(),
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
                  SizedBox(
                    height: 10,
                  ),
                  StreamBuilder<List<ScanResult>>(
                    stream: controller.scanResults,
                    builder: (context, snapshot) {
                      inspect(snapshot);
                      if (snapshot.data != null && snapshot.data!.isNotEmpty) {
                        print("has data ${snapshot.hasData} ");

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final data = snapshot.data![index];
                            return Card(
                              elevation: 2,
                              child: ListTile(
                                title: Text(data.device.name ??
                                    'Unknown'), // Handling null device name
                                subtitle: Text(data.device.id.id),
                                trailing: Text(data.rssi.toString()),
                              ),
                            );
                          },
                        );
                      } else {
                        return Center(
                          child: Text(
                              "spanshooooooooooooooooooot ${jsonEncode(snapshot.data)} "),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          }),
    );
  }
}
