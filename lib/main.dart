import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  final TextEditingController ipController = TextEditingController();
  final TextEditingController portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      ipController.text = prefs.getString('server_ip') ?? '192.168.1.100';
      portController.text = prefs.getString('server_port') ?? '5000';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', ipController.text);
    await prefs.setString('server_port', portController.text);
  }

  void wakeComputer() async {
    setState(() {
      isLoading = true;
      status = "Отправка запроса...";
    });

    try {
      await _saveSettings();
      String ip = ipController.text.trim();
      String port = portController.text.trim();
      String url = "http://$ip:$port/wake";

      final response = await http.get(Uri.parse(url)).timeout(
        Duration(seconds: 5),
        onTimeout: () => throw Exception('Сервер не отвечает'),
      );

      if (response.statusCode == 200) {
        setState(() {
          status = "✅ Компьютер включается!";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Компьютер включается!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          status = "❌ Ошибка: ${response.statusCode}";
        });
      }
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
              'Убедись, что WOL-сервер запущен на ПК',
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
                    controller: ipController,
                    decoration: InputDecoration(
                      labelText: 'IP адрес сервера',
                      hintText: 'Например: 192.168.1.100',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.dns),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: portController,
                    decoration: InputDecoration(
                      labelText: 'Порт сервера',
                      hintText: '5000',
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