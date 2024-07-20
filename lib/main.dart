import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Recognition App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  String _recognizedText = '';
  String _selectedLang = 'pt';
  bool _isLoading = false;
  bool _useBeMyAI = false;
  List<String> _languages = [];
  final TextEditingController _textController = TextEditingController();
  Future<String>? _recognitionFuture;

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    try {
      final languages = await ApiService.getLanguages();
      setState(() {
        _languages = languages;
      });
    } catch (e) {
      _showErrorDialog('Failed to load languages: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _recognizedText = '';
        _textController.clear();
      });
    }
  }

  Future<String> _recognizeImage() async {
    if (_image == null) return 'No image selected';
    setState(() {
      _isLoading = true;
    });

    try {
      final bytes = _image!.readAsBytesSync();
      final base64Image = base64Encode(bytes);
      final id = await ApiService.uploadImage(base64Image, _selectedLang, _useBeMyAI ? 1 : 0);

      // Aguardar 5 segundos antes de buscar o resultado
      await Future.delayed(Duration(seconds: 1));

      final result = await ApiService.getResult(id);

      if (result['status'] == 'ok') {
        return result['text'];
      } else {
        return 'Recognition not ready or failed';
      }
    } catch (e) {
      return 'Failed to recognize the image: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startRecognition() {
    setState(() {
      _recognitionFuture = _recognizeImage();
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Recognition App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Selecione a imagem'),
            ),
            if (_languages.isNotEmpty)
              DropdownButton<String>(
                value: _selectedLang,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLang = newValue!;
                  });
                },
                items: _languages.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            Semantics(
              label: 'Usar Be My Ai',
              child: Row(
                children: [
                  Text('Usar Be My Ai'),
                  Switch(
                    value: _useBeMyAI,
                    onChanged: (bool value) {
                      setState(() {
                        _useBeMyAI = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            if (_image != null) Image.file(_image!),
            ElevatedButton(
              onPressed: _startRecognition,
              child: Text('Reconhecer imagem'),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            SizedBox(height: 16),
            FutureBuilder<String>(
              future: _recognitionFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text('Recognition in progress...');
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  _recognizedText = snapshot.data!;
                  _textController.text = _recognizedText;
                  return TextField(
                    readOnly: true,
                    maxLines: null,
                    controller: _textController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Descrição da imagem',
                      hintText: 'The description will be displayed here',
                    ),
                  );
                } else {
                  return Text('No result');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}