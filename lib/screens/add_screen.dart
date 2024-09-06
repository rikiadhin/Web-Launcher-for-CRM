import 'dart:convert'; // Untuk encode dan decode JSON
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class WebLauncherHomePage extends StatefulWidget {
  const WebLauncherHomePage({super.key});

  @override
  _WebLauncherHomePageState createState() => _WebLauncherHomePageState();
}

class _WebLauncherHomePageState extends State<WebLauncherHomePage> {
  List<Map<String, dynamic>> _links = []; // Format JSON List
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  int? _editingIndex;
  int? _editingId;

  @override
  void initState() {
    super.initState();
    _loadLinksFromSharedPreferences(); // Load JSON data saat app dimulai
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Link',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F172A),
        leading: _editingIndex != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _cancelEdit,
              )
            : null,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _linkController,
                    decoration: const InputDecoration(labelText: 'Link'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a link';
                      } else if (!value.contains('.')) {
                        return 'Please enter a valid link with a "."';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveLink,
                    child: Text(
                        _editingIndex == null ? 'Add Link' : 'Update Link'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _links.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_links[index]['title']),
                    subtitle: Text(_links[index]['url']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editLink(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteLink(index),
                        ),
                      ],
                    ),
                    onTap: () => _launchLink(_links[index]['url']),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk menyimpan atau mengupdate link
  void _saveLink() async {
    if (_formKey.currentState!.validate()) {
      final newLink = {
        'id': _editingIndex == null ? _generateId() : _editingId,
        'title': _titleController.text,
        'url': _linkController.text,
      };

      setState(() {
        if (_editingIndex == null) {
          // Tambah link baru
          _links.add(newLink);
        } else {
          // Update link yang ada
          _links[_editingIndex!] = newLink;
          _editingIndex = null;
          _editingId = null;
        }
      });

      // Simpan list ke SharedPreferences dalam format JSON
      await _saveLinksToSharedPreferences();

      _titleController.clear();
      _linkController.clear();

      Navigator.pop(context, _links);
    }
  }

  // Fungsi untuk mengedit link
  void _editLink(int index) {
    setState(() {
      _titleController.text = _links[index]['title'];
      _linkController.text = _links[index]['url'];
      _editingIndex = index;
      _editingId = _links[index]['id']; // Menyimpan ID untuk update
    });
  }

  // Fungsi untuk menghapus link
  void _deleteLink(int index) async {
    setState(() {
      _links.removeAt(index);
    });

    // Simpan perubahan ke SharedPreferences
    await _saveLinksToSharedPreferences();
  }

  // Fungsi untuk membuka URL
  void _launchLink(String url) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: false, forceWebView: false);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Fungsi untuk membatalkan edit
  void _cancelEdit() {
    setState(() {
      _editingIndex = null;
      _titleController.clear();
      _linkController.clear();
    });
  }

  // Fungsi untuk menyimpan seluruh link dalam format JSON ke SharedPreferences
  Future<void> _saveLinksToSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonLinks = jsonEncode(_links); // Konversi list ke JSON string
    await prefs.setString(
        'links', jsonLinks); // Simpan JSON ke SharedPreferences
    print('ini adalah data link : $jsonLinks');
  }

  // Fungsi untuk memuat link dari SharedPreferences
  Future<void> _loadLinksFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('links');
    if (jsonString != null) {
      setState(() {
        _links = List<Map<String, dynamic>>.from(
            jsonDecode(jsonString)); // Konversi JSON ke list
      });
    }
  }

  // Fungsi untuk menghasilkan ID unik
  int _generateId() {
    if (_links.isEmpty) {
      return 1;
    } else {
      return _links.map((e) => e['id'] as int).reduce(max) + 1;
    }
  }
}
