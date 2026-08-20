import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WOL Controller',
      theme: ThemeData.dark(),
      home: WakeScreen(),
    );
  }
}

class WakeScreen extends StatefulWidget {
  @override
  _WakeScreenState createState() => _WakeScreenState();
}

class _WakeScreenState extends State<WakeScreen> {
  bool isLoading = false;
  String status = "Готов к работе";
  final TextEditingController macController = TextEditingController();
  final TextEditingController ipController = TextEditingController();
  final TextEditingController portController = TextEditingController();

  // Метод отправки WOL-пакета
  void sendWOL(String mac, String ip, int port) async {
    try {
      // Очищаем MAC-адрес от лишних символов
      String cleanMac = mac.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
      if (cleanMac.length != 12) {
        throw Exception('Неверный MAC-адрес');
      }

      // Преобразуем MAC в байты
      List<int> macBytes = [];
      for (int i = 0; i < cleanMac.length; i += 2) {
        macBytes.add(int.parse(cleanMac.substring(i, i + 2), radix: 16));
      }

      // Формируем Magic Packet: 6 байт 0xFF + 16 раз MAC-адрес
      Uint8List packet = Uint8List(6 + 16 * 6);
      for (int i = 0; i < 6; i++) {
        packet[i] = 0xFF;
      }
      for (int i = 0; i < 16; i++) {
        for (int j = 0; j < 6; j++) {
          packet[6 + i * 6 + j] = macBytes[j];
        }
      }

      // Отправляем пакет
      RawDatagramSocket socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.send(packet, InternetAddress(ip), port);
      socket.close();

      setState(() {
        status = "✅ Компьютер должен включиться!";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Magic Packet отправлен!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        status = "❌ Ошибка: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      macController.text = prefs.getString('mac') ?? '';
      ipController.text = prefs.getString('ip') ?? '192.168.1.255';
      portController.text = prefs.getString('port') ?? '9';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mac', macController.text);
    await prefs.setString('ip', ipController.text);
    await prefs.setString('port', portController.text);
  }

  void wakeComputer() {
    setState(() {
      isLoading = true;
      status = "Отправка WOL-пакета...";
    });

    try {
      String mac = macController.text.trim();
      String ip = ipController.text.trim();
      int port = int.tryParse(portController.text.trim()) ?? 9;

      if (mac.isEmpty) {
        throw Exception('MAC-адрес не введён');
      }
      if (ip.isEmpty) {
        throw Exception('IP-адрес не введён');
      }

      _saveSettings();
      sendWOL(mac, ip, port);
    } catch (e) {
      setState(() {
        status = "❌ Ошибка: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🖥️ WOL Controller'),
        backgroundColor: Colors.blueGrey[900],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.computer, size: 80, color: Colors.blueGrey[200]),
            SizedBox(height: 10),
            Text(
              'Включи свой компьютер!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Введи MAC и IP-адрес компьютера',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 30),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: macController,
                    decoration: InputDecoration(
                      labelText: 'MAC-адрес',
                      hintText: 'AA:BB:CC:DD:EE:FF',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.settings_ethernet),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: ipController,
                    decoration: InputDecoration(
                      labelText: 'IP-адрес (Broadcast)',
                      hintText: '192.168.1.255',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.dns),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: portController,
                    decoration: InputDecoration(
                      labelText: 'Порт',
                      hintText: '9',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.settings_ethernet),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : wakeComputer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'ВКЛЮЧИТЬ КОМПЬЮТЕР',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 16,
                  color: status.contains('✅') ? Colors.green : Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}