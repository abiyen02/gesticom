import 'package:flutter/material.dart';
import 'screens/effectifs.dart';
import 'screens/arrivee_depart.dart';
import 'screens/historique.dart';
import 'screens/main_courante.dart';
import 'screens/categories.dart';
import 'screens/database_helper.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  print("🚀 Lancement de l'application...");

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  print("📂 Base de données initialisée !");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestion des Clients',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;

  // Liste des écrans pour chaque onglet
  final List<Widget> _pages = [
    EffectifScreen(),
    ArriveeDepartScreen(),
    HistoriqueScreen(),
    MainCouranteScreen(),
    CategoriesScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text('Gestion des Clients')),
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Effectifs'),
            BottomNavigationBarItem(icon: Icon(Icons.login), label: 'Arrivées/Départs'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historique'),
            BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Main Courante'),
            BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Catégories'),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
