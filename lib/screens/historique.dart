import 'package:flutter/material.dart';

class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  _HistoriqueScreenState createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  // Liste des produits suivis
  final List<String> produits = ["Savon", "Dentifrice", "Brosse", "Papier toilette"];

  // Stocke l'historique des clients et des produits pris
  final List<Map<String, dynamic>> historique = [];

  // Stocke le total des produits sortis
  final Map<String, int> totalProduits = {
    "Savon": 0,
    "Dentifrice": 0,
    "Brosse": 0,
    "Papier toilette": 0,
  };

  final TextEditingController _nomController = TextEditingController();
  String? produitSelectionne;
  int quantite = 1;

  void ajouterHistorique() {
    if (_nomController.text.isNotEmpty && produitSelectionne != null) {
      setState(() {
        // Ajouter à l'historique
        historique.add({
          "nom": _nomController.text,
          "produit": produitSelectionne,
          "quantite": quantite,
        });
        // Mettre à jour le total
        totalProduits[produitSelectionne!] = (totalProduits[produitSelectionne!] ?? 0) + quantite;
        _nomController.clear();
        produitSelectionne = null;
        quantite = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nomController,
                    decoration: InputDecoration(labelText: "Nom du client"),
                  ),
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  hint: Text("Produit"),
                  value: produitSelectionne,
                  onChanged: (value) {
                    setState(() {
                      produitSelectionne = value;
                    });
                  },
                  items: produits.map((String produit) {
                    return DropdownMenuItem<String>(
                      value: produit,
                      child: Text(produit),
                    );
                  }).toList(),
                ),
                SizedBox(width: 10),
                DropdownButton<int>(
                  value: quantite,
                  onChanged: (value) {
                    setState(() {
                      quantite = value!;
                    });
                  },
                  items: List.generate(10, (index) => index + 1)
                      .map((int q) => DropdownMenuItem<int>(
                    value: q,
                    child: Text(q.toString()),
                  ))
                      .toList(),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: ajouterHistorique,
                  child: Text("Ajouter"),
                )
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: historique.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text("${historique[index]["nom"]} a pris ${historique[index]["quantite"]} ${historique[index]["produit"]}"),
                );
              },
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text("Total des produits sortis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Column(
                  children: produits.map((produit) {
                    return Text("$produit : ${totalProduits[produit]} unités");
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
