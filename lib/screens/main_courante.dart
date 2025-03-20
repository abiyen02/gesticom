import 'package:flutter/material.dart';
import 'database_helper.dart';

class MainCouranteScreen extends StatefulWidget {
  @override
  _MainCouranteScreenState createState() => _MainCouranteScreenState();
}

class _MainCouranteScreenState extends State<MainCouranteScreen> {
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    fetchEvents();
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

    // Convertir value en int si c'est une case à cocher (Checkbox)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Main Courante")),
      body: _events.isEmpty
          ? Center(child: Text("Aucun événement enregistré."))
          : ListView.builder(
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['description'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: event['paquetage'] == 1,
                              onChanged: (value) {
                                updateEvent(
                                    event['id'], 'paquetage', value! ? 1 : 0);
                              },
                            ),
                            Text("Paquetage"),
                            Checkbox(
                              value: event['matelas'] == 1,
                              onChanged: (value) {
                                updateEvent(
                                    event['id'], 'matelas', value! ? 1 : 0);
                              },
                            ),
                            Text("Matelas"),
                            Checkbox(
                              value: event['repas'] == 1,
                              onChanged: (value) {
                                updateEvent(
                                    event['id'], 'repas', value! ? 1 : 0);
                              },
                            ),
                            Text("Repas"),
                          ],
                        ),
                        TextField(
                          decoration: InputDecoration(labelText: "Commentaire"),
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
    );
  }
}
