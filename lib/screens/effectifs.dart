import 'package:flutter/material.dart';
import 'database_helper.dart';

class EffectifScreen extends StatefulWidget {
  const EffectifScreen({super.key});

  @override
  EffectifScreenState createState() => EffectifScreenState();
}

class EffectifScreenState extends State<EffectifScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _effectifs = [];

  @override
  void initState() {
    super.initState();
    _loadEffectifs();
  }

  Future<void> _loadEffectifs() async {
    final data = await _dbHelper.getEffectifs();
    setState(() {
      _effectifs = data;
    });
  }

  Future<void> _updateRepas(
      String matricule, bool repasMidi, bool repasSoir) async {
    await _dbHelper.updateRepas(matricule, repasMidi, repasSoir);
    await _loadEffectifs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Liste des Effectifs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  _buildTableHeader(),
                  ..._effectifs.map((e) => _buildTableRow(e)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 2.0))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _tableText('Matricule', true),
          _tableText('Nom', true),
          _tableText('Chambre', true),
          _tableText('M', true),
          _tableText('S', true),
          _tableText('Commentaire', true),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> effectif) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(width: 1.0, color: Colors.grey))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _tableText(effectif['matricule']?.toString() ?? '', false),
          _tableText(effectif['nom'] ?? '', false),
          _tableText(effectif['chambre'] ?? '', false),
          Checkbox(
            value: (effectif['midi'] ?? 0) == 1,
            onChanged: (value) => _updateRepas(
                effectif['matricule']?.toString() ?? '',
                value!,
                (effectif['soir'] ?? 0) == 1),
          ),
          Checkbox(
            value: (effectif['soir'] ?? 0) == 1,
            onChanged: (value) => _updateRepas(
                effectif['matricule']?.toString() ?? '',
                (effectif['midi'] ?? 0) == 1,
                value!),
          ),
          _tableText(effectif['commentaire'] ?? '', false),
        ],
      ),
    );
  }

  Widget _tableText(String text, bool isHeader) {
    return Flexible(
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
    );
  }
}
