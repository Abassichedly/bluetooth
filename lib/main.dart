import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'Home.dart';
import 'BluetoothController.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Add this line to create and register the BluetoothController instance
  Get.put(BluetoothController());

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "Bluetooth Demo",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.indigo,
      ),
      home: Devices(),
    );
  }
}