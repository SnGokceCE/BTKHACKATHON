import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test_app/geminichat_page.dart';
import 'attendance_page.dart';
import 'todopage.dart';
import 'bookspage.dart';
import 'examschedule_page.dart';
import 'presentationproject.dart';
import 'schedule_page.dart';
import 'geminichat_page.dart'; // Chatbot sayfası

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğrenci Yardımcı Uygulaması'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ElevatedButton(
              onPressed: () => _navigateTo(context, const AttendancePage()),
              child: const Text('Devamsızlık Durumu'),
            ),
            ElevatedButton(
              onPressed: () => _navigateTo(context, ToDoPage()),
              child: const Text('To-Do Listesi'),
            ),
            ElevatedButton(
              onPressed: () => _navigateTo(context, const BooksPage()),
              child: const Text('Kitaplarım'),
            ),
            ElevatedButton(
              onPressed: () => _navigateTo(context, const ExamSchedulePage()),
              child: const Text('Sınav Takvimi'),
            ),
            ElevatedButton(
              onPressed: () => _navigateTo(context, const PresentationPage()),
              child: const Text('Sunum & Proje Teslim Tarihleri'),
            ),
            ElevatedButton(
              onPressed: () => _navigateTo(context, const SchedulePage()),
              child: const Text('Ders Programı'),
            ),
            ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => _navigateTo(context,  GeminiChatPage()),
            child: const Text('Yapay Zeka Asistanı'),
            ),
          ],
        ),
      ),
    );
  }
}
