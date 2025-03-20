import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:intl/intl.dart';

class ArriveeDepartScreen extends StatefulWidget {
  const ArriveeDepartScreen({super.key});

  @override
  ArriveeDepartScreenState createState() => ArriveeDepartScreenState();
}

class ArriveeDepartScreenState extends State<ArriveeDepartScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Map<String, dynamic>> arrives = [];
  List<Map<String, dynamic>> departs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final arrivesData = await _dbHelper.getArrivees();
    final departsData = await _dbHelper.getDeparts();

    setState(() {
      arrives = arrivesData;
      departs = departsData;
    });
  }

  String _formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return DateFormat('HH:mm').format(parsedDate);
  }

  void _ajouterClient() {
    TextEditingController matriculeController = TextEditingController();
    TextEditingController nomController = TextEditingController();
    TextEditingController chambreController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajouter un client"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: matriculeController,
                decoration: const InputDecoration(labelText: "Matricule")),
            TextField(
                controller: nomController,
                decoration: const InputDecoration(labelText: "Nom")),
            TextField(
                controller: chambreController,
                decoration: const InputDecoration(labelText: "Chambre")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              await _dbHelper.addArrivee(
                matriculeController.text,
                nomController.text,
                chambreController.text,
              );
              Navigator.pop(context);
              _loadData();
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  void _supprimerClient() {
    TextEditingController matriculeController = TextEditingController();
    String motifDepart = "Lib"; // Valeur par défaut

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer un client"),
        content: TextField(
          controller: matriculeController,
          decoration: const InputDecoration(labelText: "Matricule"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              String matricule = matriculeController.text;
              final client = await _dbHelper.getClientByMatricule(matricule);

              if (client == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Client introuvable dans effectifs")));
                Navigator.pop(context);
                return;
              }

              // Affichage du motif de départ
              showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        title: const Text("Confirmer la suppression"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                "Nom: ${client['nom']}\nChambre: ${client['chambre']}"),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: motifDepart,
                              items: ["Lib", "Transf", "Vol", "Autres"]
                                  .map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  motifDepart = newValue!;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: "Motif de départ",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Annuler"),
                          ),
                          TextButton(
                            onPressed: () async {
                              await _dbHelper.addDepart(matricule, motifDepart);
                              Navigator.pop(context); // Ferme la confirmation
                              Navigator.pop(
                                  context); // Ferme l'alerte principale
                              _loadData(); // Recharge les listes après suppression
                            },
                            child: const Text("Confirmer"),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
            child: const Text("Rechercher"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Arrivées & Départs"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                currentDate,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "ajout",
            onPressed: _ajouterClient,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "suppression",
            onPressed: _supprimerClient,
            backgroundColor: Colors.red,
            child: const Icon(Icons.remove),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.green.shade200,
                  child: const Text(
                    "Arrivées",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: arrives.length,
                    itemBuilder: (context, index) {
                      final item = arrives[index];
                      return ListTile(
                        leading: Text(_formatDate(item['date_arrivee'] ?? ''),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        title: Text(
                            "Nom: ${item['nom']} - Matricule: ${item['matricule']}"),
                        subtitle: Text("Chambre: ${item['chambre']}"),
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.shade200,
                  child: const Text(
                    "Départs",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: departs.length,
                    itemBuilder: (context, index) {
                      final item = departs[index];
                      return ListTile(
                        leading: Text(_formatDate(item['date_depart'] ?? ''),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        title: Text(
                            "${item['type']} - ${item['nom']} (Matricule: ${item['matricule']})"),
                        subtitle: Text("Chambre: ${item['chambre']}"),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
