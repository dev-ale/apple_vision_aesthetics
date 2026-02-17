import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:apple_vision_aesthetics/apple_vision_aesthetics.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apple Vision Aesthetics Demo',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
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
  final _plugin = AppleVisionAestheticsPlatform.instance;
  bool? _isSupported;
  String? _currentAsset;
  ImageAestheticsResult? _result;
  String? _error;
  bool _loading = false;

  static const _samples = [
    ('Sharp (Nikon D3400)', 'sample_sharp.jpg'),
    ('Defocused Blur (Nikon D3400)', 'sample_defocused.jpg'),
    ('Motion Blur (Nikon D3400)', 'sample_motion_blur.jpg'),
  ];

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    final supported = await _plugin.isSupported();
    setState(() => _isSupported = supported);
  }

  Future<void> _analyzeAsset(String assetName) async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _currentAsset = assetName;
    });

    try {
      final data = await rootBundle.load('assets/$assetName');
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/$assetName');
      await tempFile.writeAsBytes(data.buffer.asUint8List());

      final result = await _plugin.analyzeFile(tempFile.path);
      setState(() => _result = result);

      await tempFile.delete();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _analyzeBatch() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _currentAsset = null;
    });

    try {
      final paths = <String>[];
      final tempDir = Directory.systemTemp;

      for (final (_, asset) in _samples) {
        final data = await rootBundle.load('assets/$asset');
        final tempFile = File('${tempDir.path}/$asset');
        await tempFile.writeAsBytes(data.buffer.asUint8List());
        paths.add(tempFile.path);
      }

      final results = await _plugin.analyzeBatch(paths);

      for (final path in paths) {
        await File(path).delete();
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Batch Results'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < results.length; i++) ...[
                Text(
                  _samples[i].$1,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Score: ${results[i].overallScore.toStringAsFixed(3)}'
                  ' | Utility: ${results[i].isUtility}'
                  ' | Low quality: ${results[i].isLowQuality()}',
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Aesthetics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Support status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _isSupported == true
                          ? Icons.check_circle
                          : Icons.cancel,
                      color:
                          _isSupported == true ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isSupported == null
                            ? 'Checking support...'
                            : _isSupported!
                                ? 'iOS 18+ Vision API supported'
                                : 'Not supported (requires iOS 18+)',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Image preview
            if (_currentAsset != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/$_currentAsset',
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 16),

            // Individual analysis buttons
            ...List.generate(_samples.length, (i) {
              final (label, asset) = _samples[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : () => _analyzeAsset(asset),
                  icon: Icon(
                    i == 0
                        ? Icons.photo
                        : i == 1
                            ? Icons.blur_on
                            : Icons.motion_photos_on,
                  ),
                  label: Text('Analyze: $label'),
                ),
              );
            }),

            const SizedBox(height: 8),

            // Batch button
            OutlinedButton.icon(
              onPressed: _loading ? null : _analyzeBatch,
              icon: const Icon(Icons.batch_prediction),
              label: const Text('Batch Analyze All 3'),
            ),

            const SizedBox(height: 24),

            if (_loading) const Center(child: CircularProgressIndicator()),

            // Result card
            if (_result != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score: ${_result!.overallScore.toStringAsFixed(3)}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      _ScoreBar(score: _result!.overallScore),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _InfoChip(
                            label: 'Utility',
                            value: _result!.isUtility,
                            trueColor: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          _InfoChip(
                            label: 'Low quality',
                            value: _result!.isLowQuality(),
                            trueColor: Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            if (_error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red)),
                ),
              ),

            const SizedBox(height: 24),

            const Text(
              'Sample images from Kwentar/blur_dataset (GitHub)\n'
              'Triplet: Sharp / Defocused / Motion blur — Nikon D3400 35mm',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.score});
  final double score;

  @override
  Widget build(BuildContext context) {
    final normalized = (score + 1) / 2;
    final color = Color.lerp(Colors.red, Colors.green, normalized)!;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: normalized,
            minHeight: 12,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 4),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('-1.0', style: TextStyle(fontSize: 10)),
            Text('0.0', style: TextStyle(fontSize: 10)),
            Text('1.0', style: TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
    required this.trueColor,
  });
  final String label;
  final bool value;
  final Color trueColor;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        value ? Icons.warning_rounded : Icons.check,
        size: 18,
        color: value ? trueColor : Colors.green,
      ),
      label: Text('$label: $value'),
    );
  }
}
