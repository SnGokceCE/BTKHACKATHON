import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExamSchedulePage extends StatefulWidget {
  const ExamSchedulePage({Key? key}) : super(key: key);

  @override
  State<ExamSchedulePage> createState() => _ExamSchedulePageState();
}

class _ExamSchedulePageState extends State<ExamSchedulePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? userId;

  final TextEditingController examNameController = TextEditingController();
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      userId = user.uid;
    }
  }

  void _showAddExamDialog() {
    examNameController.clear();
    selectedDate = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          Future<void> _pickDate() async {
            DateTime now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: now,
              firstDate: now.subtract(const Duration(days: 365)),
              lastDate: now.add(const Duration(days: 365 * 5)),
            );
            if (picked != null) {
              setState(() {
                selectedDate = picked;
              });
            }
          }

          void _addExam() async {
            if (userId == null) return;

            if (examNameController.text.isEmpty || selectedDate == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lütfen sınav adı ve tarih seçin')),
              );
              return;
            }

            await _firestore
                .collection('examSchedules')
                .doc(userId)
                .collection('exams')
                .add({
              'name': examNameController.text.trim(),
              'date': Timestamp.fromDate(selectedDate!),
              'timestamp': FieldValue.serverTimestamp(),
            });

            Navigator.of(context).pop();
          }

          return AlertDialog(
            title: const Text('Yeni Sınav Ekle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: examNameController,
                    decoration: const InputDecoration(labelText: 'Sınav Adı'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(selectedDate == null
                            ? 'Tarih seçilmedi'
                            : 'Seçilen Tarih: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
                      ),
                      ElevatedButton(
                        onPressed: _pickDate,
                        child: const Text('Tarih Seç'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: _addExam,
                child: const Text('Ekle'),
              ),
            ],
          );
        });
      },
    );
  }

  void _deleteExam(String docId) {
    if (userId == null) return;

    _firestore
        .collection('examSchedules')
        .doc(userId)
        .collection('exams')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sınav Takvimi')),
        body: const Center(child: Text('Kullanıcı bulunamadı. Giriş yapınız.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sınav Takvimi'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('examSchedules')
            .doc(userId)
            .collection('exams')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Henüz sınav eklenmedi'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? '';
              final Timestamp timestamp = data['date'] ?? Timestamp.now();
              final date = timestamp.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.event_note),
                  title: Text(name),
                  subtitle:
                      Text('${date.day}/${date.month}/${date.year}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteExam(docs[index].id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExamDialog,
        child: const Icon(Icons.add),
        tooltip: 'Yeni Sınav Ekle',
      ),
    );
  }
}
