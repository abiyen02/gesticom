import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'database_helper.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class MainCouranteScreen extends StatefulWidget {
  const MainCouranteScreen({super.key}); // Utilisation du super paramètre

  @override
  MainCouranteScreenState createState() => MainCouranteScreenState();
}

class MainCouranteScreenState extends State<MainCouranteScreen> {
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> mouvements = [];
  List<Map<String, dynamic>> effectifs = [];

  final TextEditingController _mouvementController = TextEditingController();
  final TextEditingController _commentaireController = TextEditingController();
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    fetchEvents();
    _loadMouvements();
    //
    // _loadEffectifs();
  }

  @override
  void dispose() {
    _mouvementController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> getSortedEvents() {
    List<Map<String, dynamic>> allEvents = [];

    for (var event in _events) {
      allEvents.add({
        'description': event['description'],
        'heure': DateTime.parse(event['heure']),
        'type': 'event',
        'id': event['id'],
        'paquetage': event['paquetage'],
        'matelas': event['matelas'],
        'repas': event['repas'],
        'commentaire': event['commentaire'],
      });
    }

    for (var mouvement in mouvements) {
      allEvents.add({
        'description': mouvement['type'],
        'heure': DateTime.parse(mouvement['heure']),
        'type': 'mouvement',
        'id': mouvement['id'],
        'refus': mouvement['refus'],
        'commentaire': mouvement['commentaire'],
      });
    }

    allEvents.sort((a, b) => a['heure'].compareTo(b['heure']));
    return allEvents;
  }

  Future<void> fetchEvents() async {
    final db = await DatabaseHelper.instance.database;
    final events = await db.query('main_courante');
    setState(() {
      _events = events;
    });
  }

  Future<void> updateEvent(int id, String column, dynamic value) async {
    final db = await DatabaseHelper.instance.database;
    int intValue =
        (value is bool) ? (value ? 1 : 0) : int.tryParse(value.toString()) ?? 0;
    await db.update(
      'main_courante',
      {column: intValue},
      where: 'id = ?',
      whereArgs: [id],
    );
    fetchEvents();
  }

  Future<void> _loadMouvements() async {
    final data = await DatabaseHelper.instance.getMouvements();
    _logger.i("Mouvements récupérés : $data");
    setState(() {
      mouvements = data;
    });
  }

  Future<void> _showAddMouvementDialog() async {
    _mouvementController.clear();

    String? customMouvement = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ajouter un mouvement"),
          content: TextField(
            controller: _mouvementController,
            decoration: const InputDecoration(
              hintText: "Entrez votre mouvement ici...",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                if (_mouvementController.text.isNotEmpty) {
                  Navigator.pop(context, _mouvementController.text);
                }
              },
              child: const Text("Ajouter"),
            ),
          ],
        );
      },
    );

    if (customMouvement != null && customMouvement.isNotEmpty) {
      await DatabaseHelper.instance.addMouvement(customMouvement);
      _logger.i("Mouvement ajouté : $customMouvement");
      _loadMouvements();
    }
  }

  Future<void> _showRefusRepasDialog(
    int mouvementId,
    String refusActuel,
  ) async {
    Map<int, bool> refusMap = {};
    List<String> refusActuels =
        refusActuel.isNotEmpty ? refusActuel.split('; ') : [];

    for (var effectif in effectifs) {
      String identifiant = "${effectif['nom']} ${effectif['matricule']}";
      refusMap[effectif['id']] = refusActuels.contains(identifiant);
    }

    _commentaireController.clear();

    Map<String, dynamic>? mouvement;
    for (var m in mouvements) {
      if (m['id'] == mouvementId) {
        mouvement = m;
        break;
      }
    }

    if (mouvement != null && mouvement['commentaire'] != null) {
      _commentaireController.text = mouvement['commentaire'];
    }

    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Gestion des refus de repas"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: effectifs.length,
                        itemBuilder: (context, index) {
                          final effectif = effectifs[index];
                          return CheckboxListTile(
                            title: Text(
                              "${effectif['nom']} - ${effectif['matricule']}",
                            ),
                            value: refusMap[effectif['id']] ?? false,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                refusMap[effectif['id']] = value ?? false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _commentaireController,
                      decoration: const InputDecoration(
                        labelText: "Commentaire",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Enregistrer"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      List<String> refusNoms = [];
      for (var effectif in effectifs) {
        if (refusMap[effectif['id']] == true) {
          refusNoms.add("${effectif['nom']} ${effectif['matricule']}");
        }
      }

      String refusString = refusNoms.join('; ');
      String commentaire = _commentaireController.text;

      await DatabaseHelper.instance.updateMouvementRefus(
        mouvementId,
        refusString,
        commentaire,
      );
      _loadMouvements();
    }
  }

  Future<void> _showDeleteConfirmationDialog(int id) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Supprimer le mouvement"),
          content: const Text(
            "Êtes-vous sûr de vouloir supprimer ce mouvement ?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                "Supprimer",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      await DatabaseHelper.instance.deleteMouvement(id);
      _loadMouvements();
    }
  }

  void _showMouvementOptions(int id, String description, {String? refus}) {
    bool isFermetureRefectoire =
        description == "Fermeture du refectoire sous surveillance policière";

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFermetureRefectoire)
                ListTile(
                  leading: const Icon(Icons.no_food, color: Colors.orange),
                  title: Text(
                    refus != null && refus.isNotEmpty
                        ? "${refus.split('; ').length.toString()} - Refus"
                        : "0 - Refus",
                  ),
                  onTap: () {
                    Navigator.pop(context); // Ferme le BottomSheet
                    _showRefusRepasDialog(
                      id,
                      refus ?? "",
                    ); // Appelle le dialogue
                  },
                ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text("Modifier"),
                onTap: () {
                  Navigator.pop(context);
                  _showEditMouvementDialog(id, description);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Supprimer"),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text("Annuler"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditMouvementDialog(int id, String description) {
    // Implémentez la logique pour afficher le dialogue de modification ici
    _logger.i(
      "Modifier le mouvement avec l'ID: $id et la description: $description",
    );
  }

  // Fonction pour générer un PDF contenant les données
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
                "Liste des Événements et Mouvements",
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                "Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}",
              ),
              pw.SizedBox(height: 20),

              // Section des événements
              pw.Text(
                "Événements",
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
                        child: pw.Text("Description"),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Commentaire"),
                      ),
                    ],
                  ),
                  ..._events.map(
                    (event) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            DateFormat(
                              'HH:mm',
                            ).format(DateTime.parse(event['heure'])),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(event['description']),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(event['commentaire'] ?? ''),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Section des mouvements
              pw.Text(
                "Mouvements",
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
                        child: pw.Text("Description"),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Refus"),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Commentaire"),
                      ),
                    ],
                  ),
                  ...mouvements.map(
                    (mouvement) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            DateFormat(
                              'HH:mm',
                            ).format(DateTime.parse(mouvement['heure'])),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(mouvement['type']),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(mouvement['refus'] ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(mouvement['commentaire'] ?? ''),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Main Courante"),
        actions: [
          IconButton(
            icon: const Icon(Icons.print), // Icône d'impression
            onPressed: _generatePdf, // Appelle la fonction pour générer le PDF
            tooltip: "Imprimer la page",
          ),
        ],
      ),
      body:
          getSortedEvents().isEmpty
              ? const Center(child: Text("Aucun événement enregistré."))
              : ListView.builder(
                itemCount: getSortedEvents().length,
                itemBuilder: (context, index) {
                  final event = getSortedEvents()[index];
                  final bool isFermetureRefectoire =
                      event['description'] ==
                      "Fermeture du refectoire sous surveillance policière";

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 10,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  event['description'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (event['type'] == 'mouvement')
                                IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () {
                                    _showMouvementOptions(
                                      event['id'],
                                      event['description'],
                                      refus: event['refus'],
                                    );
                                  },
                                ),
                            ],
                          ),
                          Text(
                            "Heure: ${DateFormat('HH:mm').format(event['heure'])}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          if (isFermetureRefectoire &&
                              event['refus'] != null &&
                              event['refus'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${event['refus'].split('; ').length} - Refus:",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  Text(
                                    event['refus'],
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          if (event['type'] == 'mouvement' &&
                              event['commentaire'] != null &&
                              event['commentaire'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                "Commentaire: ${event['commentaire']}",
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          if (event['type'] == 'event')
                            Row(
                              children: [
                                Checkbox(
                                  value: event['paquetage'] == 1,
                                  onChanged: (value) {
                                    updateEvent(
                                      event['id'],
                                      'paquetage',
                                      value! ? 1 : 0,
                                    );
                                  },
                                ),
                                const Text("Paquetage"),
                                Checkbox(
                                  value: event['matelas'] == 1,
                                  onChanged: (value) {
                                    updateEvent(
                                      event['id'],
                                      'matelas',
                                      value! ? 1 : 0,
                                    );
                                  },
                                ),
                                const Text("Matelas"),
                                Checkbox(
                                  value: event['repas'] == 1,
                                  onChanged: (value) {
                                    updateEvent(
                                      event['id'],
                                      'repas',
                                      value! ? 1 : 0,
                                    );
                                  },
                                ),
                                const Text("Repas"),
                              ],
                            ),
                          if (event['type'] == 'event')
                            TextField(
                              decoration: const InputDecoration(
                                labelText: "Commentaire",
                              ),
                              onSubmitted: (value) {
                                updateEvent(event['id'], 'commentaire', value);
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "btn_custom",
            onPressed: _showAddMouvementDialog,
            backgroundColor: Colors.green,
            child: const Icon(Icons.add_comment),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "btn_preset",
            onPressed: () async {
              String? selectedMouvement = await showDialog<String>(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: const Text("Sélectionner un mouvement"),
                    children: [
                      for (String option in [
                        "Prise de service de [....]",
                        "Fin de service de [....]",
                        "Depart VIP",
                        "Depart ECO",
                        "Depart PREMIUM",
                        "Debut des distribution des rasoirs",
                        "Fin des distribution des rasoirs",
                        "Arrivée de l'agent de l'ASSFAM",
                        "Depart de l'agent de l'ASSFAM",
                        "Arrivée de l'agent de l'OFII",
                        "Depart de l'agent de l'OFII",
                        "Ouverture de l'infirmerie sous surveillance policière",
                        "Fermeture de l'infirmerie sous surveillance policière",
                        "Debut des consultations médicales",
                        "Fin des consultations médicales",
                        "Ouverture du refectoire sous surveillance policière",
                        "Fermeture du refectoire sous surveillance policière",
                      ])
                        SimpleDialogOption(
                          onPressed: () => Navigator.pop(context, option),
                          child: Text(option),
                        ),
                    ],
                  );
                },
              );

              if (selectedMouvement != null) {
                await DatabaseHelper.instance.addMouvement(selectedMouvement);
                _logger.i("Mouvement sélectionné : $selectedMouvement");
                _loadMouvements();
              }
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
