import 'package:flutter/material.dart';

class CategoriesScreen extends StatelessWidget {
  final List<String> categories = ['VIP', 'PREMIUM', 'ECO'];
  final Map<String, List<String>> clientsParCategorie = {
    'VIP': ['Jean Dupont'],
    'PREMIUM': ['Marie Curie'],
    'ECO': ['Albert Einstein'],
  };

   CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          String categorie = categories[index];
          return ExpansionTile(
            title: Text(categorie, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            children: clientsParCategorie[categorie]!.map((client) {
              return ListTile(
                title: Text(client),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
