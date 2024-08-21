import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class ApiService {
  Database? _database;

  Future<void> initDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'mydatabase.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, address TEXT)',
        );
      },
      version: 2, // Atualize a versão para forçar a migração
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 2) {
          db.execute('ALTER TABLE items RENAME TO old_items');
          db.execute(
            'CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, address TEXT)',
          );
          db.execute(
            'INSERT INTO items (id, address) SELECT id, name || " - " || cep FROM old_items',
          );
          db.execute('DROP TABLE old_items');
        }
      },
    );
  }

  Future<List<Map<String, dynamic>>> loadItems() async {
    if (_database != null) {
      return await _database!.query('items');
    }
    return [];
  }

  Future<void> saveItem(String cep, String address) async {
    if (_database == null) return;
    String formattedAddress = '$cep - $address';
    await _database!.insert(
      'items',
      {'address': formattedAddress},
    );
  }

  Future<void> updateItem(int id, String oldCep, String newCep) async {
    if (_database == null) return;
    final List<Map<String, dynamic>> items = await _database!.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (items.isNotEmpty) {
      String newAddress = items[0]['address'].replaceFirst(oldCep, newCep);
      await _database!.update(
        'items',
        {'address': newAddress},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> deleteItem(int id) async {
    if (_database == null) return;
    await _database!.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> fetchAddressFromCEP(String cep, BuildContext context) async {
    final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String address = '${data['logradouro']}, ${data['bairro']}, ${data['localidade']} - ${data['uf']}';
      saveItem(cep, address);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CEP não encontrado')),
      );
    }
  }

  TextInputFormatter getCepInputFormatter() {
    return _CepInputFormatter();
  }
}

class _CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll('-', '');

    if (text.length > 5) {
      text = '${text.substring(0, 5)}-${text.substring(5)}';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

