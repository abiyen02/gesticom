import 'package:flutter/material.dart';
import 'database_helper.dart';

class ArriveeDepartScreen extends StatefulWidget {
  const ArriveeDepartScreen({super.key});

  @override
  _ArriveeDepartScreenState createState() => _ArriveeDepartScreenState();
}

class _ArriveeDepartScreenState extends State<ArriveeDepartScreen> {
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
      print("🔄 Chargement des données...");
      final arrivesData = await _dbHelper.getArrivees();
      final departsData = await _dbHelper.getDeparts();

      setState(() {
        arrives = arrivesData;
        departs = departsData;
      });
      print("✅ Données mises à jour : Arrivées = \${arrives.length}, Départs = \${departs.length}");
    } catch (e) {
      print("❌ Erreur lors du chargement des données : \$e");
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
                decoration: InputDecoration(labelText: "Matricule"),
              ),
              if (isArrivee)
                TextField(
                  controller: nomController,
                  decoration: InputDecoration(labelText: "Nom"),
                ),
              if (isArrivee)
                TextField(
                  controller: chambreController,
                  decoration: InputDecoration(labelText: "Chambre"),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (matriculeController.text.isNotEmpty) {
                  print("🔹 Bouton Ajouter cliqué");
                  try {
                    if (isArrivee) {
                      print("🔹 Ajout d'une arrivée : \${matriculeController.text}, \${nomController.text}, \${chambreController.text}");
                      await _dbHelper.addArrivee(
                        matriculeController.text,
                        nomController.text,
                        chambreController.text,
                      );
                    } else {
                      print("🔹 Ajout d'un départ : \${matriculeController.text}");
                      await _dbHelper.addDepart(matriculeController.text);
                    }
                    await _loadData();
                    Navigator.pop(context);
                    print("✅ Enregistrement réussi !");
                  } catch (e) {
                    print("❌ Erreur lors de l'ajout : \$e");
                  }
                }
              },
              child: Text("Ajouter"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Arrivées & Départs")),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text("Arrivées", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: arrives.length,
                    itemBuilder: (context, index) {
                      final item = arrives[index];
                      return ListTile(
                        title: Text("Nom: \${item['nom']} - Matricule: \${item['matricule']}", style: TextStyle(fontSize: 16)),
                        subtitle: Text("Chambre: \${item['chambre']}", style: TextStyle(fontSize: 14)),
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
                Text("Départs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: departs.length,
                    itemBuilder: (context, index) {
                      final item = departs[index];
                      return ListTile(
                        title: Text("Matricule: \${item['matricule']}", style: TextStyle(fontSize: 16)),
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
            child: Icon(Icons.add),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "depart",
            onPressed: () => _showAddDialog(false),
            tooltip: "Ajouter un départ",
            child: Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
