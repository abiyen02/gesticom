import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class MainCouranteScreen extends StatefulWidget {
  const MainCouranteScreen({Key? key}) : super(key: key);
  @override
  MainCouranteScreenState createState() => MainCouranteScreenState();
}

class MainCouranteScreenState extends State<MainCouranteScreen> {
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> mouvements = [];
  // Contrôleur pour le champ de texte du mouvement personnalisé
  final TextEditingController _mouvementController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchEvents();
    _loadMouvements();
  }

  // Ne pas oublier de libérer le contrôleur quand l'écran est détruit
  @override
  void dispose() {
    _mouvementController.dispose();
    super.dispose();
  }

  // Fonction pour obtenir tous les événements triés par heure
  List<Map<String, dynamic>> getSortedEvents() {
    List<Map<String, dynamic>> allEvents = [];

    // Ajout des événements principaux
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

    // Ajout des mouvements
    for (var mouvement in mouvements) {
      allEvents.add({
        'description': mouvement['type'],
        'heure': DateTime.parse(mouvement['heure']),
        'type': 'mouvement',
        'id': mouvement['id'], // Important pour l'édition et la suppression
      });
    }

    // Tri par heure
    allEvents.sort((a, b) => a['heure'].compareTo(b['heure']));
    return allEvents;
  }

  // Récupération des événements depuis la base de données
  Future<void> fetchEvents() async {
    final db = await DatabaseHelper.instance.database;
    final events = await db.query('main_courante');
    setState(() {
      _events = events;
    });
  }

  // Mise à jour d'un événement dans la base de données
  Future<void> updateEvent(int id, String column, dynamic value) async {
    final db = await DatabaseHelper.instance.database;
    int intValue =
        (value is bool) ? (value ? 1 : 0) : int.tryParse(value.toString()) ?? 0;
    await db.update('main_courante', {column: intValue},
        where: 'id = ?', whereArgs: [id]);
    fetchEvents();
  }

  // Chargement des mouvements depuis la base de données
  Future<void> _loadMouvements() async {
    final data = await DatabaseHelper.instance.getMouvements();
    setState(() {
      mouvements = data;
    });
  }

  // Fonction pour ajouter un mouvement personnalisé
  Future<void> _showAddMouvementDialog() async {
    _mouvementController.clear(); // Réinitialiser le champ de texte

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

    // Si un mouvement personnalisé a été saisi, on l'ajoute à la base de données
    if (customMouvement != null && customMouvement.isNotEmpty) {
      await DatabaseHelper.instance.addMouvement(customMouvement);
      _loadMouvements();
    }
  }

  // Fonction pour modifier un mouvement existant
  Future<void> _showEditMouvementDialog(int id, String currentText) async {
    _mouvementController.text = currentText; // Pré-remplir avec le texte actuel

    String? updatedMouvement = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Modifier le mouvement"),
          content: TextField(
            controller: _mouvementController,
            decoration: const InputDecoration(
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
              child: const Text("Enregistrer"),
            ),
          ],
        );
      },
    );

    // Si le mouvement a été modifié, on met à jour la base de données
    if (updatedMouvement != null && updatedMouvement.isNotEmpty) {
      await DatabaseHelper.instance.updateMouvement(id, updatedMouvement);
      _loadMouvements();
    }
  }

  // Fonction pour confirmer et supprimer un mouvement
  Future<void> _showDeleteConfirmationDialog(int id) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Supprimer le mouvement"),
          content:
              const Text("Êtes-vous sûr de vouloir supprimer ce mouvement ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Supprimer",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    // Si la suppression est confirmée, on supprime de la base de données
    if (confirmDelete == true) {
      await DatabaseHelper.instance.deleteMouvement(id);
      _loadMouvements();
    }
  }

  // Fonction pour afficher le menu d'options sur un mouvement
  void _showMouvementOptions(int id, String description) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Main Courante")),
      body: getSortedEvents().isEmpty
          ? const Center(child: Text("Aucun événement enregistré."))
          : ListView.builder(
              itemCount: getSortedEvents().length,
              itemBuilder: (context, index) {
                final event = getSortedEvents()[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
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
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            // Bouton d'action pour les mouvements uniquement
                            if (event['type'] == 'mouvement')
                              IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () {
                                  _showMouvementOptions(
                                      event['id'], event['description']);
                                },
                              ),
                          ],
                        ),
                        Text(
                            "Heure: ${DateFormat('HH:mm').format(event['heure'])}",
                            style: const TextStyle(color: Colors.grey)),
                        if (event['type'] == 'event')
                          Row(
                            children: [
                              Checkbox(
                                value: event['paquetage'] == 1,
                                onChanged: (value) {
                                  updateEvent(
                                      event['id'], 'paquetage', value! ? 1 : 0);
                                },
                              ),
                              const Text("Paquetage"),
                              Checkbox(
                                value: event['matelas'] == 1,
                                onChanged: (value) {
                                  updateEvent(
                                      event['id'], 'matelas', value! ? 1 : 0);
                                },
                              ),
                              const Text("Matelas"),
                              Checkbox(
                                value: event['repas'] == 1,
                                onChanged: (value) {
                                  updateEvent(
                                      event['id'], 'repas', value! ? 1 : 0);
                                },
                              ),
                              const Text("Repas"),
                            ],
                          ),
                        if (event['type'] == 'event')
                          TextField(
                            decoration:
                                const InputDecoration(labelText: "Commentaire"),
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
          // Bouton pour ajouter un nouveau mouvement personnalisé
          FloatingActionButton(
            heroTag: "btn_custom",
            onPressed: _showAddMouvementDialog,
            backgroundColor: Colors.green,
            child: const Icon(Icons.add_comment),
          ),
          const SizedBox(height: 10),
          // Bouton pour ajouter un mouvement prédéfini
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

              // Si un mouvement prédéfini a été sélectionné, on l'ajoute à la base de données
              if (selectedMouvement != null) {
                await DatabaseHelper.instance.addMouvement(selectedMouvement);
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
