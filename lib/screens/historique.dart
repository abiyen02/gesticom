import 'package:flutter/material.dart';

class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  HistoriqueScreenState createState() => HistoriqueScreenState();
}

class HistoriqueScreenState extends State<HistoriqueScreen> {
  final List<String> produits = [
    "Savon",
    "Dentifrice",
    "Brosse",
    "Papier toilette"
  ];
  final List<Map<String, dynamic>> historique = [];
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
        historique.add({
          "nom": _nomController.text,
          "produit": produitSelectionne,
          "quantite": quantite,
        });
        totalProduits[produitSelectionne!] =
            (totalProduits[produitSelectionne!] ?? 0) + quantite;
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
                      produitSelectionne = value!;
                    });
                  },
                  items: produits.map((String produit) {
                    return DropdownMenuItem<String>(
                      value: produit,
                      child: Text(produit),
                    );
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
