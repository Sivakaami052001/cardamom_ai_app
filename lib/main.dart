import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

void main() {
  runApp(const CardamomApp());
}

class CardamomApp extends StatelessWidget {
  const CardamomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cardamom AI',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

// Custom painter for organic pod background
class PodBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF2E5E3E),
          const Color(0xFF1B3B2A),
          const Color(0xFF0F2A1E),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final podPaint = Paint()
      ..color = const Color(0xFFE8D6A8).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final random = Random(42);
    for (int i = 0; i < 30; i++) {
      final path = Path();
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final w = 30 + random.nextDouble() * 80;
      final h = 20 + random.nextDouble() * 50;
      path.addOval(Rect.fromCenter(center: Offset(x, y), width: w, height: h));
      canvas.drawPath(path, podPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  XFile? image;
  String result = "";
  String? processedImage;
  bool isLoading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final String backendUrl = "http://192.168.29.65:8000/measure";

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        image = picked;
        result = "";
        processedImage = null;
        isLoading = true;
      });
      await uploadImage();
      setState(() {
        isLoading = false;
      });
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
        details += "Pod ${i + 1}: Width ${widths[i]} mm, Length ${lengths[i]} mm | ${weights[i]} g\n";
      }

      setState(() {
        processedImage = jsonData['image'];
        result = """
📊 Pods: ${jsonData['pods']}

--- Each Pod ---
$details

📏 Length Stats:
Max: ${jsonData['max_length'].toStringAsFixed(2)} mm
Min: ${jsonData['min_length'].toStringAsFixed(2)} mm
Avg: ${jsonData['avg_length'].toStringAsFixed(2)} mm

📐 Width Stats:
Average Width: ${jsonData['avg_width'].toStringAsFixed(2)} mm

⚖️ Average Weight: ${jsonData['avg_weight'].toStringAsFixed(3)} g
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
      body: CustomPaint(
        painter: PodBackgroundPainter(),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Unique logo area
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      builder: (_, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFF4C542),
                              const Color(0xFFDAA520),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.grass,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Cardamom\nIntelligence',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(blurRadius: 10, color: Colors.black38, offset: Offset(2, 2)),
                        ],
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Measure pods with AI precision',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Animated capture button
                    GestureDetector(
                      onTap: pickImage,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD966), Color(0xFFFFB347)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap to capture',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Loading indicator
                    if (isLoading)
                      Column(
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF4C542)),
                          ),
                          const SizedBox(height: 12),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(seconds: 2),
                            builder: (_, value, __) {
                              return Opacity(
                                opacity: value,
                                child: const Text(
                                  'Analyzing pods...',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                    // Processed Image
                    if (processedImage != null)
                      Card(
                        elevation: 16,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.memory(
                          base64Decode(processedImage!),
                          height: 280,
                          fit: BoxFit.cover,
                        ),
                      )
                    else if (image != null && !isLoading)
                      Card(
                        elevation: 16,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: kIsWeb
                            ? Image.network(image!.path, height: 280, fit: BoxFit.cover)
                            : Image.file(File(image!.path), height: 280, fit: BoxFit.cover),
                      ),

                    const SizedBox(height: 40),

                    // Glass‑morphism result card
                    if (result.isNotEmpty)
                      ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.auto_awesome, color: Colors.amber.shade300),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'AI Results',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.white54),
                                const SizedBox(height: 16),
                                Text(
                                  result,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.4,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Floating decorative element
              Positioned(
                top: 80,
                right: 20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF4C542).withOpacity(0.2),
                  ),
                  child: const Icon(Icons.eco, color: Colors.white54, size: 32),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}