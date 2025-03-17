import 'package:flutter/material.dart';

class MainCouranteScreen extends StatefulWidget {
  const MainCouranteScreen({super.key});

  @override
  _MainCouranteScreenState createState() => _MainCouranteScreenState();
}

class _MainCouranteScreenState extends State<MainCouranteScreen> {
  List<String> logs = [];

  // Ajouter une entrée dans la main courante
  void ajouterLog(String message) {
    setState(() {
      logs.add("[${DateTime.now().toLocal()}] $message");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('Main Courante', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(logs[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          ajouterLog("Nouvelle entrée enregistrée");
        },
      ),
    );
  }
}
