import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({Key? key}) : super(key: key);

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  List<String> absenceDates = [];
  bool isLoading = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadAbsenceDates();
  }

  Future<void> _loadAbsenceDates() async {
    setState(() {
      isLoading = true;
    });

    final user = _auth.currentUser;
    if (user == null) {
      // Kullanıcı giriş yapmamışsa boş liste ile bırak
      setState(() {
        absenceDates = [];
        isLoading = false;
      });
      return;
    }

    final doc = await _firestore.collection('attendances').doc(user.uid).get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['absenceDates'] != null) {
        List<dynamic> dates = data['absenceDates'];
        absenceDates = dates.map((e) => e.toString()).toList();
      }
    } else {
      absenceDates = [];
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _addAbsence() async {
    final now = DateTime.now();
    final formattedDate = "${now.day}/${now.month}/${now.year}";

    if (absenceDates.contains(formattedDate)) {
      // Aynı günü tekrar eklememek için uyarı
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bugün zaten devamsızlık olarak kayıtlı.")),
      );
      return;
    }

    absenceDates.add(formattedDate);

    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('attendances').doc(user.uid).set({
      'absenceDates': absenceDates,
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Devamsızlık Durumu')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Devamsızlık Durumu'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Toplam Devamsızlık: ${absenceDates.length}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(
              child: absenceDates.isEmpty
                  ? Center(child: Text("Henüz devamsızlık günü yok"))
                  : ListView.builder(
                      itemCount: absenceDates.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: Icon(Icons.event_busy, color: Colors.red),
                          title: Text(absenceDates[index]),
                        );
                      },
                    ),
            ),
            ElevatedButton.icon(
              onPressed: _addAbsence,
              icon: Icon(Icons.add),
              label: Text("Bugünü Devamsızlık Olarak Ekle"),
            ),
          ],
        ),
      ),
    );
  }
}
