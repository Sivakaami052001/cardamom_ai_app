import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const CardamomApp());
}

class CardamomApp extends StatelessWidget {
  const CardamomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  XFile? image;
  String result = "";
  String? processedImage;

  // 🔁 REPLACE THIS IP WITH YOUR COMPUTER'S LOCAL IP ADDRESS
final String backendUrl = "http://192.168.29.65:8000/measure";

  // 🟢 Use camera instead of gallery
  Future pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        image = picked;
        result = "Processing...";
        processedImage = null;
      });

      uploadImage();
    }
  }

  Future uploadImage() async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse(backendUrl),
      );

      if (kIsWeb) {
        var bytes = await image!.readAsBytes();

        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: image!.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            image!.path,
          ),
        );
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      var jsonData = json.decode(responseData);

      List lengths = jsonData['lengths'];
      List widths = jsonData['widths'];
      List weights = jsonData['weights'];

      String details = "";

      for (int i = 0; i < lengths.length; i++) {
        details +=
            "Pod ${i+1}: ${lengths[i]} mm x ${widths[i]} mm | ${weights[i]} g\n";
      }

      setState(() {
        processedImage = jsonData['image'];

        result = """
Pods: ${jsonData['pods']}

--- Each Pod ---
$details

Max Length: ${jsonData['max_length'].toStringAsFixed(2)} mm
Min Length: ${jsonData['min_length'].toStringAsFixed(2)} mm
Average Length: ${jsonData['avg_length'].toStringAsFixed(2)} mm

Average Weight: ${jsonData['avg_weight'].toStringAsFixed(3)} g
""";
      });

    } catch (e) {
      setState(() {
        result = "Failed to connect to backend ❌";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cardamom Measurement AI")),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [

              ElevatedButton(
                onPressed: pickImage,
                child: const Text("Take a photo of cardamom"),
              ),

              const SizedBox(height: 20),

              if (processedImage != null)
                Image.memory(
                  base64Decode(processedImage!),
                  height: 250,
                )
              else if (image != null)
                kIsWeb
                    ? Image.network(image!.path, height: 200)
                    : Image.file(File(image!.path), height: 200),

              const SizedBox(height: 20),

              Text(
                result,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}