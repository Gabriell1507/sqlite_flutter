import 'package:flutter/material.dart';
import 'services/api_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consulta CEP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ApiService _apiService = ApiService();
  TextEditingController _cepController = TextEditingController();
  String? _editingItem;
  String? _editingCep;

  @override
  void initState() {
    super.initState();
    _apiService.initDatabase();
  }

  void _clearFields() {
    _cepController.clear();
    _editingItem = null;
    _editingCep = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: const Text('Consulta CEP')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _cepController,
              decoration: InputDecoration(
                labelText: 'CEP',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () async {
                    if (_editingItem == null) {
                      await _apiService.fetchAddressFromCEP(
                          _cepController.text.replaceAll('-', ''), context);
                      _clearFields();
                      setState(() {});
                    }
                  },
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                _apiService.getCepInputFormatter(),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_editingItem == null) {
                      await _apiService.fetchAddressFromCEP(
                          _cepController.text.replaceAll('-', ''), context);
                      _clearFields();
                      setState(() {});
                    }
                  },
              child: Text('Salvar'),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _apiService.loadItems(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final items = snapshot.data!;
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        title: Text(item['address']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                setState(() {
                                  _cepController.text =
                                      item['address'].split(' - ')[0];
                                  _editingItem = item['id'].toString();
                                  _editingCep = _cepController.text;
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () async {
                                await _apiService.deleteItem(item['id']);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
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
