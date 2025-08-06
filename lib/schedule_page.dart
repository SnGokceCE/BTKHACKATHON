import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma'];

  String? userId;

  final TextEditingController lessonController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      userId = user.uid;
    }
  }

  Future<void> _addLesson(String day, List<dynamic> currentLessons) async {
    if (userId == null) return;

    final lessonName = lessonController.text.trim();
    final lessonTime = timeController.text.trim();

    if (lessonName.isEmpty || lessonTime.isEmpty) return;

    // Yeni ders objesi
    final newLesson = {'lesson': lessonName, 'time': lessonTime};

    // Günün mevcut dersleri ve yeni dersle güncellenmiş liste
    List<Map<String, String>> updatedLessons = [];

    // Eğer mevcut lessons var ve List<dynamic> tipindeyse dönüştür
    if (currentLessons.isNotEmpty) {
      for (var item in currentLessons) {
        updatedLessons.add(Map<String, String>.from(item));
      }
    }

    updatedLessons.add(newLesson);

    // Firestore'da tek doc olduğu için doğrudan set ile güncelle
    await _firestore.collection('schedules').doc(userId).set({
      'schedule': {day: updatedLessons},
    }, SetOptions(merge: true)); // merge ile var olan diğer günler silinmez

    lessonController.clear();
    timeController.clear();
    Navigator.of(context).pop();
  }

  Future<void> _showAddLessonDialog(String day, List<dynamic> currentLessons) async {
    lessonController.clear();
    timeController.clear();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$day için Ders Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: lessonController,
                decoration: const InputDecoration(labelText: 'Ders Adı'),
              ),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: 'Saat Aralığı'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                lessonController.clear();
                timeController.clear();
                Navigator.pop(context);
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => _addLesson(day, currentLessons),
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  void _deleteLesson(String day, List<dynamic> currentLessons, int index) async {
    if (userId == null) return;

    List<Map<String, String>> updatedLessons = [];

    for (var i = 0; i < currentLessons.length; i++) {
      if (i != index) {
        updatedLessons.add(Map<String, String>.from(currentLessons[i]));
      }
    }

    await _firestore.collection('schedules').doc(userId).set({
      'schedule': {day: updatedLessons},
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ders Programı')),
        body: const Center(child: Text('Kullanıcı bulunamadı. Giriş yapınız.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ders Programı')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('schedules').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          Map<String, dynamic> schedule = {};
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            schedule = Map<String, dynamic>.from(data['schedule'] ?? {});
          }

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: ListView(
              children: days.map((day) {
                final lessonsDynamic = schedule[day] ?? [];
                // List<dynamic> → List<Map<String, String>>
                final lessons = (lessonsDynamic as List<dynamic>)
                    .map((e) => Map<String, String>.from(e))
                    .toList();

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Divider(),
                        if (lessons.isEmpty)
                          const Text('Ders yok',
                              style: TextStyle(color: Colors.grey)),
                        ...lessons.asMap().entries.map((entry) {
                          final index = entry.key;
                          final lesson = entry.value;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(lesson['lesson'] ?? ''),
                            subtitle: Text('Saat: ${lesson['time'] ?? ''}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _deleteLesson(day, lessonsDynamic, index),
                            ),
                          );
                        }).toList(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _showAddLessonDialog(day, lessonsDynamic),
                            icon: const Icon(Icons.add),
                            label: const Text('Ders Ekle'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
