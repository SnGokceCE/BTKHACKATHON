import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ToDoPage extends StatefulWidget {
  const ToDoPage({Key? key}) : super(key: key);

  @override
  State<ToDoPage> createState() => _ToDoPageState();
}

class _ToDoPageState extends State<ToDoPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? userId;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      userId = user.uid;
    }
  }

  Future<void> _addTodo(String title) async {
    if (userId == null || title.trim().isEmpty) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('todos')
          .add({'title': title.trim(), 'isDone': false});
      _controller.clear();
    } catch (e) {
      print('Firestore yazma hatası: $e');
      // İstersen burada kullanıcıya hata mesajı gösterebilirsin.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görev eklenirken hata oluştu')),
      );
    }
  }

  Future<void> _toggleDone(DocumentSnapshot doc) async {
    try {
      final current = doc['isDone'] as bool? ?? false;
      await doc.reference.update({'isDone': !current});
    } catch (e) {
      print('Firestore güncelleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görev güncellenirken hata oluştu')),
      );
    }
  }

  Future<void> _deleteTodo(DocumentSnapshot doc) async {
    try {
      await doc.reference.delete();
    } catch (e) {
      print('Firestore silme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görev silinirken hata oluştu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('To-Do List')),
        body: const Center(child: Text('Kullanıcı bulunamadı. Lütfen giriş yapınız.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('To-Do List')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Yeni görev ekle",
                    ),
                    onSubmitted: _addTodo,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addTodo(_controller.text),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('todos')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Henüz görev eklenmedi'));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final title = doc['title'] ?? '';
                    final isDone = doc['isDone'] ?? false;

                    return ListTile(
                      title: Text(
                        title,
                        style: TextStyle(
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      leading: Checkbox(
                        value: isDone,
                        onChanged: (_) => _toggleDone(doc),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteTodo(doc),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
