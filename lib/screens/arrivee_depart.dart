import 'package:flutter/material.dart';
import 'database_helper.dart';

class ArriveeDepartScreen extends StatefulWidget {
  const ArriveeDepartScreen({super.key});

  @override
  ArriveeDepartScreenState createState() => ArriveeDepartScreenState();
}

class ArriveeDepartScreenState extends State<ArriveeDepartScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> arrives = [];
  List<Map<String, dynamic>> departs = [];

  final TextEditingController matriculeController = TextEditingController();
  final TextEditingController nomController = TextEditingController();
  final TextEditingController chambreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      debugPrint("🔄 Chargement des données...");
      final arrivesData = await _dbHelper.getArrivees();
      final departsData = await _dbHelper.getDeparts();

      setState(() {
        arrives = arrivesData;
        departs = departsData;
      });
      debugPrint(
          "✅ Données mises à jour : Arrivées = \${arrives.length}, Départs = \${departs.length}");
    } catch (e) {
      debugPrint("❌ Erreur lors du chargement des données : \$e");
    }
  }

  void _showAddDialog(bool isArrivee) {
    matriculeController.clear();
    nomController.clear();
    chambreController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isArrivee ? "Ajouter une arrivée" : "Ajouter un départ"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: matriculeController,
                decoration: const InputDecoration(labelText: "Matricule"),
              ),
              if (isArrivee)
                TextField(
                  controller: nomController,
                  decoration: const InputDecoration(labelText: "Nom"),
                ),
              if (isArrivee)
                TextField(
                  controller: chambreController,
                  decoration: const InputDecoration(labelText: "Chambre"),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (matriculeController.text.isNotEmpty) {
                  debugPrint("🔹 Bouton Ajouter cliqué");
                  try {
                    if (isArrivee) {
                      await _dbHelper.addArrivee(
                        matriculeController.text,
                        nomController.text,
                        chambreController.text,
                      );
                    } else {
                      await _dbHelper.addDepart(matriculeController.text);
                    }
                    await _loadData();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    debugPrint("✅ Enregistrement réussi !");
                  } catch (e) {
                    debugPrint("❌ Erreur lors de l'ajout : \$e");
                  }
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
      appBar: AppBar(title: const Text("Arrivées & Départs")),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Text("Arrivées",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: arrives.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                            "Nom: \${item['nom']} - Matricule: \${item['matricule']}",
                            style: const TextStyle(fontSize: 16)),
                        subtitle: Text("Chambre: \${item['chambre']}",
                            style: const TextStyle(fontSize: 14)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Text("Départs",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: departs.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text("Matricule: \${item['matricule']}",
                            style: const TextStyle(fontSize: 16)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "arrivee",
            onPressed: () => _showAddDialog(true),
            tooltip: "Ajouter une arrivée",
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "depart",
            onPressed: () => _showAddDialog(false),
            tooltip: "Ajouter un départ",
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
