import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class PdfPreviewScreen extends StatefulWidget {
  final String title;
  final Uint8List pdfBytes;
  final String fileName;

  const PdfPreviewScreen({
    super.key,
    required this.title,
    required this.pdfBytes,
    required this.fileName,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      _currentScale = (_currentScale + 0.25).clamp(0.5, 5.0);
      _transformationController.value = Matrix4.identity()..scale(_currentScale);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentScale = (_currentScale - 0.25).clamp(0.5, 5.0);
      _transformationController.value = Matrix4.identity()..scale(_currentScale);
    });
  }

  void _resetZoom() {
    setState(() {
      _currentScale = 1.0;
      _transformationController.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out, color: Colors.white70),
            tooltip: 'Zoom Out (-)',
            onPressed: _zoomOut,
          ),
          Center(
            child: Text(
              '${(_currentScale * 100).toInt()}%',
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in, color: Colors.white70),
            tooltip: 'Zoom In (+)',
            onPressed: _zoomIn,
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt, color: Colors.white70),
            tooltip: 'Reset Zoom (100%)',
            onPressed: _resetZoom,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Informative Zoom Tip Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF1E293B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pinch_outlined,
                    color: Color(0xFFD4AF37), size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Gunakan 2 jari (pinch) atau tombol atas untuk Zoom In/Out',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 5.0,
              onInteractionUpdate: (details) {
                setState(() {
                  _currentScale = _transformationController.value.getMaxScaleOnAxis();
                });
              },
              child: PdfPreview(
                build: (format) async => widget.pdfBytes,
                pdfFileName: widget.fileName,
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                scrollViewDecoration: const BoxDecoration(
                  color: Color(0xFF0A0E1A),
                ),
                loadingWidget: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
