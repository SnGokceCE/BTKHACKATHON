import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PresentationPage extends StatefulWidget {
  const PresentationPage({Key? key}) : super(key: key);

  @override
  _PresentationPageState createState() => _PresentationPageState();
}

class _PresentationPageState extends State<PresentationPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  void _addPresentation() async {
    String title = titleController.text.trim();
    String description = descriptionController.text.trim();
    String date = dateController.text.trim();

    if (title.isNotEmpty && description.isNotEmpty && date.isNotEmpty) {
      await FirebaseFirestore.instance.collection('presentations').add({
        'title': title,
        'description': description,
        'deliveryDate': date,
        'timestamp': FieldValue.serverTimestamp(), // sıralamak için
      });

      // Temizle
      titleController.clear();
      descriptionController.clear();
      dateController.clear();

      Navigator.of(context).pop(); // dialogu kapat
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sunum Ekle"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Başlık'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Açıklama'),
              ),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Teslim Tarihi'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: _addPresentation,
            child: const Text("Ekle"),
          ),
        ],
      ),
    );
  }

  void _deletePresentation(String docId) {
    FirebaseFirestore.instance.collection('presentations').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sunumlar"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('presentations')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz sunum eklenmemiş."));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['title'] ?? ''),
                  subtitle: Text(
                      "${data['description'] ?? ''}\nTeslim: ${data['deliveryDate'] ?? ''}"),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deletePresentation(doc.id),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
