import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:intl/intl.dart';

class MouvementsScreen extends StatefulWidget {
  const MouvementsScreen({super.key});

  @override
  MouvementsScreenState createState() => MouvementsScreenState();
}

class MouvementsScreenState extends State<MouvementsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> mouvements = [];

  @override
  void initState() {
    super.initState();
    _loadMouvements();
  }

  Future<void> _loadMouvements() async {
    final mouvementsData = await _dbHelper.getMouvements();
    setState(() {
      mouvements = mouvementsData;
    });
  }

  void _ajouterMouvement() {
    List<String> options = [
      "Arrivée de l'agent de l'ASSFAM",
      "Arrivée de l'agent de l'OFII",
      "Ouverture de l'infirmerie sous surveillance policière",
      "Fermeture de l'infirmerie sous surveillance policière"
    ];

    showDialog(
      context: context,
      builder: (context) {
        String? selectedMouvement;
        return AlertDialog(
          title: const Text("Ajouter un mouvement"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: selectedMouvement,
                onChanged: (value) {
                  setState(() {
                    selectedMouvement = value;
                  });
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () async {
                if (selectedMouvement != null) {
                  await _dbHelper.addMouvement(selectedMouvement!);
                  Navigator.pop(context);
                  _loadMouvements();
                }
              },
              child: const Text("Ajouter"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mouvements Journaliers")),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterMouvement,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: mouvements.length,
        itemBuilder: (context, index) {
          final mouvement = mouvements[index];
          return ListTile(
            leading: Text(
              DateFormat('HH:mm').format(DateTime.parse(mouvement['heure'])),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            title: Text(mouvement['description']),
          );
        },
      ),
    );
  }
}
