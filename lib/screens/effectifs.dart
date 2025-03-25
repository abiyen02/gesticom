import 'package:flutter/material.dart';
import 'package:printing/printing.dart'; // Import for printing functionality
import 'package:pdf/pdf.dart'; // Import for PDF generation
import 'package:pdf/widgets.dart' as pw; // Import for PDF widgets
import 'dart:typed_data'; // Import for Uint8List
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
    String matricule,
    bool repasMidi,
    bool repasSoir,
  ) async {
    await _dbHelper.updateRepas(matricule, repasMidi, repasSoir);
    await _loadEffectifs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Effectifs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              await Printing.layoutPdf(
                onLayout: (PdfPageFormat format) async => _generatePdf(format),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Liste des Effectifs',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
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

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('Liste des Effectifs', style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text(
                        'Matricule',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Nom',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Chambre',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Repas Midi',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Repas Soir',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Commentaire',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  ..._effectifs.map((effectif) {
                    return pw.TableRow(
                      children: [
                        pw.Text(effectif['matricule']?.toString() ?? ''),
                        pw.Text(effectif['nom'] ?? ''),
                        pw.Text(effectif['chambre'] ?? ''),
                        pw.Text(
                          (effectif['repas_midi'] ?? 0) == 1 ? 'Oui' : 'Non',
                        ),
                        pw.Text(
                          (effectif['repas_soir'] ?? 0) == 1 ? 'Oui' : 'Non',
                        ),
                        pw.Text(effectif['commentaire'] ?? ''),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ],
          );
        },
      ),
    );
    return pdf.save(); // Ensure the return statement is present
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(width: 2.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _tableText('Matricule', true),
          _tableText('Nom & Prenom', true),
          _tableText('Chambre', true),
          _tableText('       M', true),
          _tableText('          S', true),
          _tableText('Commentaire', true),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> effectif) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(width: 1.0, color: Colors.grey)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _tableText(effectif['matricule']?.toString() ?? '', false),
          _tableText(effectif['nom'] ?? '', false),
          _tableText(effectif['chambre'] ?? '', false),
          Checkbox(
            value: (effectif['repas_midi'] ?? 0) == 1,
            onChanged:
                (value) => _updateRepas(
                  effectif['matricule']?.toString() ?? '',
                  value!,
                  (effectif['repas_soir'] ?? 0) == 1,
                ),
          ),
          Checkbox(
            value: (effectif['repas_soir'] ?? 0) == 1,
            onChanged:
                (value) => _updateRepas(
                  effectif['matricule']?.toString() ?? '',
                  (effectif['repas_midi'] ?? 0) == 1,
                  value!,
                ),
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
