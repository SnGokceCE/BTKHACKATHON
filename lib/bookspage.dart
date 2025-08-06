import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'pdf_viewer_page.dart';

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
  PlatformFile? selectedFile;

  String? userId;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      userId = user.uid;
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt', 'epub'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedFile = result.files.first;
      });
    }
  }

  Future<String?> _uploadFile(PlatformFile file) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('books/${userId!}/${file.name}');
      await ref.putFile(File(file.path!));
      return await ref.getDownloadURL();
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<void> _deleteFileFromStorage(String fileUrl) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      print('Dosya silme hatası: $e');
    }
  }

  void _addBook() async {
    if (userId == null) return;

    final title = titleController.text.trim();
    final author = authorController.text.trim();
    final pages = int.tryParse(pagesController.text.trim()) ?? 0;

    if (title.isNotEmpty && author.isNotEmpty && pages > 0) {
      String? fileUrl;

      if (selectedFile != null) {
        fileUrl = await _uploadFile(selectedFile!);
      }

      await _firestore
          .collection('books')
          .doc(userId)
          .collection('kitaplar')
          .add({
        'title': title,
        'author': author,
        'pages': pages,
        'isRead': isRead,
        'fileUrl': fileUrl,
        'fileName': selectedFile?.name,
        'timestamp': FieldValue.serverTimestamp(),
      });

      titleController.clear();
      authorController.clear();
      pagesController.clear();
      setState(() {
        isRead = false;
        selectedFile = null;
      });

      Navigator.of(context).pop();
    }
  }

  void _showAddBookDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (context, setStateDialog) {
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
                          setStateDialog(() {
                            isRead = val ?? false;
                          });
                        },
                      ),
                      const Text('Okundu'),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _pickFile();
                      setStateDialog(() {});
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Dosya Seç (PDF, DOCX...)"),
                  ),
                  if (selectedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        selectedFile!.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  titleController.clear();
                  authorController.clear();
                  pagesController.clear();
                  setState(() {
                    isRead = false;
                    selectedFile = null;
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

  void _deleteBook(String docId, String? fileUrl) async {
    if (userId == null) return;

    if (fileUrl != null) {
      await _deleteFileFromStorage(fileUrl);
    }

    await _firestore
        .collection('books')
        .doc(userId)
        .collection('kitaplar')
        .doc(docId)
        .delete();
  }

  Future<void> _openPdfInApp(String url) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/temp.pdf';

      final response = await Dio().download(url, tempPath);

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerPage(filePath: tempPath),
          ),
        );
      } else {
        throw Exception("Dosya indirilemedi");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF açılamadı: $e")),
      );
    }
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
              final fileUrl = data['fileUrl'];
              final docId = docs[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$author - $pages sayfa'),
                      if (fileUrl != null)
                        TextButton.icon(
                          onPressed: () => _openPdfInApp(fileUrl),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text("Dosyayı Aç"),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        read ? Icons.check_circle : Icons.circle_outlined,
                        color: read ? Colors.green : Colors.grey,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteBook(docId, fileUrl),
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