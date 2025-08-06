import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({Key? key}) : super(key: key);

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController pagesController = TextEditingController();
  bool isRead = false;

  String? userId;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      userId = user.uid;
    }
  }

  void _addBook() async {
    if (userId == null) return;

    final title = titleController.text.trim();
    final author = authorController.text.trim();
    final pages = int.tryParse(pagesController.text.trim()) ?? 0;

    if (title.isNotEmpty && author.isNotEmpty && pages > 0) {
      await _firestore
          .collection('books')
          .doc(userId)
          .collection('kitaplar')
          .add({
        'title': title,
        'author': author,
        'pages': pages,
        'isRead': isRead,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Temizle
      titleController.clear();
      authorController.clear();
      pagesController.clear();
      setState(() {
        isRead = false;
      });

      Navigator.of(context).pop();
    }
  }

  void _showAddBookDialog() {
    showDialog(
      context: context,
      builder: (_) {
        // StatefulBuilder ile checkbox durumu yönetiliyor
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Yeni Kitap Ekle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Kitap Adı'),
                  ),
                  TextField(
                    controller: authorController,
                    decoration: const InputDecoration(labelText: 'Yazar'),
                  ),
                  TextField(
                    controller: pagesController,
                    decoration: const InputDecoration(labelText: 'Sayfa Sayısı'),
                    keyboardType: TextInputType.number,
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: isRead,
                        onChanged: (val) {
                          setState(() {
                            isRead = val ?? false;
                          });
                        },
                      ),
                      const Text('Okundu'),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Temizle
                  titleController.clear();
                  authorController.clear();
                  pagesController.clear();
                  setState(() {
                    isRead = false;
                  });
                },
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: _addBook,
                child: const Text('Ekle'),
              ),
            ],
          );
        });
      },
    );
  }

  void _deleteBook(String docId) {
    if (userId == null) return;

    _firestore
        .collection('books')
        .doc(userId)
        .collection('kitaplar')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kitaplarım')),
        body: const Center(child: Text('Kullanıcı bulunamadı. Giriş yapınız.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Kitaplarım')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('books')
            .doc(userId)
            .collection('kitaplar')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Henüz kitap eklenmedi'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? '';
              final author = data['author'] ?? '';
              final pages = data['pages'] ?? 0;
              final read = data['isRead'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(title),
                  subtitle: Text('$author - $pages sayfa'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        read ? Icons.check_circle : Icons.circle_outlined,
                        color: read ? Colors.green : Colors.grey,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteBook(docs[index].id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBookDialog,
        child: const Icon(Icons.add),
        tooltip: 'Yeni Kitap Ekle',
      ),
    );
  }
}
