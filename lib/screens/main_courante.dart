import 'package:flutter/material.dart';

class MainCouranteScreen extends StatelessWidget {
  const MainCouranteScreen({super.key}); // Converted 'key' to a super parameter

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Main Courante"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Rapports de la journée",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: 10, // Exemple : remplacer par les données réelles
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      title: Text("Événement ${index + 1}"),
                      subtitle: Text("Détail de l’événement"),
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () {
                        // Action à effectuer lors du clic
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
