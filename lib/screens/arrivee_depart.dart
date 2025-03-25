import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pour formater les dates
import 'database_helper.dart'; // Importez votre fichier de base de données
import 'package:pdf/pdf.dart'; // Pour créer des documents PDF
import 'package:pdf/widgets.dart' as pw; // Widgets pour le contenu du PDF
import 'package:printing/printing.dart'; // Pour imprimer le PDF

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
    _loadData(); // Charge les données au démarrage
  }

  // Charge les données des arrivées et des départs depuis la base de données
  Future<void> _loadData() async {
    final arrivesData = await _dbHelper.getArrivees();
    final departsData = await _dbHelper.getDeparts();
    setState(() {
      arrives = arrivesData;
      departs = departsData;
    });
  }

  // Formate une date au format HH:mm
  String _formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return DateFormat('HH:mm').format(parsedDate);
  }

  // Fonction pour ajouter un client (arrivées)
  void _ajouterClient() {
    TextEditingController matriculeController = TextEditingController();
    TextEditingController nomController = TextEditingController();
    TextEditingController chambreController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Ajouter un client"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: matriculeController,
                  decoration: const InputDecoration(labelText: "Matricule"),
                ),
                TextField(
                  controller: nomController,
                  decoration: const InputDecoration(labelText: "Nom"),
                ),
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
              TextButton(
                onPressed: () async {
                  await _dbHelper.addArrivee(
                    matriculeController.text,
                    nomController.text,
                    chambreController.text,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _loadData(); // Recharge les données après ajout
                },
                child: const Text("Ajouter"),
              ),
            ],
          ),
    );
  }

  // Fonction pour supprimer un client (départs)
  void _supprimerClient() {
    TextEditingController matriculeController = TextEditingController();
    String motifDepart = "Lib"; // Valeur par défaut pour le motif de départ

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                  final client = await _dbHelper.getClientByMatricule(
                    matricule,
                  );

                  if (client == null) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Client introuvable dans effectifs"),
                      ),
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    return;
                  }

                  // Affichage du motif de départ
                  if (!context.mounted) return;
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
                                  "Nom: ${client['nom']}\nChambre: ${client['chambre']}",
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  value: motifDepart,
                                  items:
                                      ["Lib", "Transf", "Vol", "Autres"].map((
                                        String value,
                                      ) {
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
                                  await _dbHelper.addDepart(
                                    matricule,
                                    motifDepart,
                                    true,
                                    false,
                                  );
                                  if (!context.mounted) return;
                                  Navigator.pop(
                                    context,
                                  ); // Ferme la confirmation
                                  Navigator.pop(
                                    context,
                                  ); // Ferme l'alerte principale
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

  // Fonction pour générer un PDF contenant les données des arrivées et départs
  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    // Ajouter une page au PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Liste des Arrivées et Départs",
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                "Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}",
              ),
              pw.SizedBox(height: 20),

              // Section des arrivées
              pw.Text(
                "Arrivées",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Heure"),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Nom"),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Matricule"),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Chambre"),
                      ),
                    ],
                  ),
                  ...arrives.map(
                    (item) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            _formatDate(item['date_arrivee'] ?? ''),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(item['nom']),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(item['matricule']),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(item['chambre']),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Section des départs
              pw.Text(
                "Départs",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Heure"),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Type"),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Nom"),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Matricule"),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Chambre"),
                      ),
                    ],
                  ),
                  ...departs.map(
                    (item) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            _formatDate(item['date_depart'] ?? ''),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(item['type']),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(item['nom']),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(item['matricule']),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(item['chambre']),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Imprimer le PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.print), // Icône d'impression
            onPressed: _generatePdf, // Appelle la fonction pour générer le PDF
            tooltip: "Imprimer la page",
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
                        leading: Text(
                          _formatDate(item['date_arrivee'] ?? ''),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        title: Text(
                          "Nom: ${item['nom']} - Matricule: ${item['matricule']}",
                        ),
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
                        leading: Text(
                          _formatDate(item['date_depart'] ?? ''),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        title: Text(
                          "${item['type']} - ${item['nom']} (Matricule: ${item['matricule']})",
                        ),
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
