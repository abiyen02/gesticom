import 'package:flutter/material.dart';
import 'database_helper.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  CategoriesScreenState createState() => CategoriesScreenState();
}

class CategoriesScreenState extends State<CategoriesScreen> {
  final List<String> categories = ['VIP', 'PREMIUM', 'ECO', 'AUTRE'];
  final Map<String, List<Map<String, dynamic>>> clientsParCategorie = {
    'VIP': [],
    'PREMIUM': [],
    'ECO': [],
    'AUTRE': [],
  };

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    final dbHelper = DatabaseHelper.instance;
    final effectifs = await dbHelper.getEffectifs();

    if (!mounted) return; // Vérifier si le widget est encore monté

    // Réinitialiser les listes
    clientsParCategorie.forEach((key, value) => value.clear());

    // Trier les clients par catégorie
    for (var client in effectifs) {
      final chambre = client['chambre'] ?? '';
      if (categories.contains(chambre)) {
        clientsParCategorie[chambre]!.add(client);
      } else {
        clientsParCategorie['AUTRE']!.add(client);
      }
    }

    setState(() {});
  }

  void _ajouterClient(String categorie) async {
    final dbHelper = DatabaseHelper.instance;
    final effectifs =
        await dbHelper.getEffectifs(); // Récupérer tous les effectifs
    final List<Map<String, dynamic>> clientsSelectionnes = [];
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Ajouter des clients à $categorie'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: effectifs.length,
                  itemBuilder: (context, index) {
                    final client = effectifs[index];
                    final isSelected = clientsSelectionnes.contains(client);

                    return CheckboxListTile(
                      title: Text(
                          '${client['matricule']} - ${client['nom']} - ${client['chambre']}'),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setStateDialog(() {
                          if (value == true) {
                            clientsSelectionnes.add(client);
                          } else {
                            clientsSelectionnes.remove(client);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Annuler'),
                ),
                TextButton(
                  onPressed: () async {
                    for (var client in clientsSelectionnes) {
                      // Ajouter le client à la catégorie localement
                      if (!clientsParCategorie[categorie]!
                          .any((c) => c['matricule'] == client['matricule'])) {
                        clientsParCategorie[categorie]!.add(client);
                      }
                    }

                    // Mettre à jour l'état global
                    setState(() {});

                    // Fermer la boîte de dialogue
                    Navigator.of(context).pop();
                  },
                  child: Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _modifierClient(String categorie, int index) {
    final client = clientsParCategorie[categorie]![index];
    final TextEditingController nomController =
        TextEditingController(text: client['nom']);
    final TextEditingController chambreController =
        TextEditingController(text: client['chambre']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modifier le client'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: chambreController,
                decoration: InputDecoration(labelText: 'Chambre'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  client['nom'] = nomController.text;
                  client['chambre'] = chambreController.text;
                });
                Navigator.of(context).pop();
              },
              child: Text('Modifier'),
            ),
          ],
        );
      },
    );
  }

  void _supprimerClient(String categorie, int index) {
    setState(() {
      clientsParCategorie[categorie]!.removeAt(index);
    });
  }

  void _ajouterNouvelleCategorie() {
    final TextEditingController categorieController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ajouter une nouvelle catégorie'),
          content: TextField(
            controller: categorieController,
            decoration: InputDecoration(labelText: 'Nom de la catégorie'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                final nouvelleCategorie = categorieController.text.trim();
                if (nouvelleCategorie.isNotEmpty &&
                    !categories.contains(nouvelleCategorie)) {
                  setState(() {
                    categories.insert(categories.length - 1, nouvelleCategorie);
                    clientsParCategorie[nouvelleCategorie] = [];
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  void _imprimer() {
    // Logique pour imprimer les données
    debugPrint("Impression des données...");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catégories'),
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: _imprimer, // Appeler la fonction d'impression
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          String categorie = categories[index];
          return ExpansionTile(
            title: Text(
              categorie,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            children: [
              if (categorie == 'AUTRE')
                TextButton(
                  onPressed: _ajouterNouvelleCategorie,
                  child: Text('Ajouter une nouvelle catégorie'),
                )
              else ...[
                ...clientsParCategorie[categorie]!.asMap().entries.map((entry) {
                  int clientIndex = entry.key;
                  Map<String, dynamic> client = entry.value;
                  return ListTile(
                    title: Text(
                        '${client['matricule']} - ${client['nom']} - ${client['chambre']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () =>
                              _modifierClient(categorie, clientIndex),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () =>
                              _supprimerClient(categorie, clientIndex),
                        ),
                      ],
                    ),
                  );
                }),
                TextButton(
                  onPressed: () => _ajouterClient(categorie),
                  child: Text('Ajouter un client'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
