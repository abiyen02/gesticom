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

  @override
  void initState() {
    super.initState();
    fetchEvents();
    _loadMouvements();
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
    await db.update('main_courante', {column: intValue},
        where: 'id = ?', whereArgs: [id]);
    fetchEvents();
  }

  Future<void> _loadMouvements() async {
    final data = await DatabaseHelper.instance.getMouvements();
    setState(() {
      mouvements = data;
    });
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
                        Text(event['description'],
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
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
      floatingActionButton: FloatingActionButton(
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
                    "Arrivée de l'agent de l'OFII",
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
            _loadMouvements();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
