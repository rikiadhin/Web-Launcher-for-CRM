import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> _links = [];
  List<Map<String, String>> _filteredLinks = [];
  List<Map<String, String>> _archivedLinks = [];
  TextEditingController _searchController = TextEditingController();
  bool _viewArchived = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterLinks);
    loadLinksFromSharedPreferences();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterLinks);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadLinksFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Ambil semua kunci dari SharedPreferences
    Set<String> keys = prefs.getKeys();

    List<Map<String, String>> loadedLinks = [];

    // Loop melalui kunci untuk menemukan key yang cocok (title_ dan link_)
    for (String key in keys) {
      if (key.startsWith('title_')) {
        String id = key.replaceFirst('title_', ''); // Ambil ID dari key
        String? title = prefs.getString('title_$id');
        String? link = prefs.getString('link_$id');

        if (title != null && link != null) {
          loadedLinks.add({'id': id, 'title': title, 'link': link});
          print('Key: $key, Title: $title, Link: $link');
        }
      }
    }

    setState(() {
      _links = loadedLinks;
      _filterLinks(); // Filter links berdasarkan pencarian
    });
  }

  Future<void> saveLinkToSharedPreferences(Map<String, String> linkData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String id = linkData['id']!;
    await prefs.setString('title_$id', linkData['title']!);
    await prefs.setString('link_$id', linkData['link']!);
  }

  Future<void> deleteLinkFromSharedPreferences(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('title_$id');
    await prefs.remove('link_$id');
  }

  void _toggleViewArchived() {
    setState(() {
      _viewArchived = !_viewArchived;
      _filterLinks();
    });
  }

  void _filterLinks() {
    String searchTerm = _searchController.text.toLowerCase();
    setState(() {
      if (_viewArchived) {
        _filteredLinks = _archivedLinks
            .where((link) =>
                link['title']!.toLowerCase().contains(searchTerm) ||
                link['link']!.toLowerCase().contains(searchTerm))
            .toList();
      } else {
        _filteredLinks = _links
            .where((link) =>
                link['title']!.toLowerCase().contains(searchTerm) ||
                link['link']!.toLowerCase().contains(searchTerm))
            .toList();
      }
    });
  }

  void _editLink(String id) {
    int index = _links.indexWhere((link) => link['id'] == id);
    if (index != -1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditScreen(
            linkData: _filteredLinks[index],
            onSave: (updatedData) {
              setState(() {
                if (_viewArchived) {
                  _archivedLinks[index] = updatedData;
                } else {
                  _links[index] = updatedData;
                }
                saveLinkToSharedPreferences(
                    updatedData); // Update SharedPreferences
                _filterLinks();
              });
            },
          ),
        ),
      );
    }
  }

  void _deleteLink(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Link'),
          content: const Text('Are you sure you want to delete this link?'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _links.removeWhere((link) => link['id'] == id);
                  _archivedLinks.removeWhere((link) => link['id'] == id);
                  deleteLinkFromSharedPreferences(
                      id); // Delete from SharedPreferences
                  _filterLinks();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _archiveLink(String id) {
    int index = _links.indexWhere((link) => link['id'] == id);
    if (index != -1) {
      setState(() {
        _archivedLinks.add(_links[index]);
        _links.removeAt(index);
        _filterLinks();
      });
    }
  }

  void _unarchiveLink(String id) {
    int index = _archivedLinks.indexWhere((link) => link['id'] == id);
    if (index != -1) {
      setState(() {
        _links.add(_archivedLinks[index]);
        _archivedLinks.removeAt(index);
        _filterLinks();
      });
    }
  }

  Future<void> _launchLink(String url) async {
    Uri uri;

    print('Attempting to launch URL: $url');

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      uri = Uri.parse('https://$url');
    } else {
      uri = Uri.parse(url);
    }

    print('Final URI: $uri');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Could not launch $uri. The URL may be invalid or the scheme might not be supported.';
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Widget _buildCard(Map<String, String> linkData, int index) {
    return GestureDetector(
      onTap: () => _launchLink(linkData['link']!),
      child: Card(
        color: Colors.white,
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  linkData['title']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  linkData['link']!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_viewArchived)
                    _buildIconButton(Icons.unarchive, Colors.green,
                        () => _unarchiveLink(linkData['id']!))
                  else
                    _buildIconButton(Icons.archive, Colors.orange,
                        () => _archiveLink(linkData['id']!)),
                  _buildIconButton(Icons.edit, Colors.blue,
                      () => _editLink(linkData['id']!)),
                  _buildIconButton(Icons.delete, Colors.red,
                      () => _deleteLink(linkData['id']!)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: onPressed,
        customBorder: CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(4),
          child: Icon(icon, color: color, size: 27),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          _viewArchived ? 'Archived Links' : 'Link Manager',
          style: const TextStyle(color: Colors.white), // White text color
        ),
        backgroundColor: const Color(0xFF1F2937),
        iconTheme: const IconThemeData(color: Colors.white), // White icon color
        actions: [
          IconButton(
            icon: Icon(_viewArchived ? Icons.view_list : Icons.archive),
            onPressed: _toggleViewArchived,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              width: 300,
              height: 150,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/kodegiri.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by title',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _filteredLinks.length,
                    itemBuilder: (context, index) {
                      final linkData = _filteredLinks[index];
                      return _buildCard(linkData, index);
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WebLauncherHomePage(),
                  ),
                ).then((result) {
                  if (result != null) {
                    setState(() {
                      _links.addAll(List<Map<String, String>>.from(result));
                      _filterLinks();
                    });
                  }
                });
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.add, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class EditScreen extends StatelessWidget {
  final Map<String, String> linkData;
  final Function(Map<String, String>) onSave;

  const EditScreen({super.key, required this.linkData, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final TextEditingController titleController =
        TextEditingController(text: linkData['title']);
    final TextEditingController linkController =
        TextEditingController(text: linkData['link']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Link'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: linkController,
              decoration: const InputDecoration(labelText: 'Link'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                onSave({
                  'id': linkData['id']!, // Keep the ID unchanged
                  'title': titleController.text,
                  'link': linkController.text,
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
