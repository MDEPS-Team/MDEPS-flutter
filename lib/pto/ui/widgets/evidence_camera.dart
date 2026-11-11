import 'package:flutter/material.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';

/// Prefix of evidence captured by the simulated camera (no device camera
/// plugin is bundled in this static UI build).
const mockEvidencePrefix = 'mock-evidence:';

/// Evidence camera: dark viewfinder with a shutter button. Returns an
/// evidence reference via `Navigator.pop`.
class EvidenceCameraScreen extends StatelessWidget {
  const EvidenceCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 64, 16, 140),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1F2B), Color(0xFF0B1A33)],
                  ),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Center(
                  child: Icon(Icons.center_focus_weak, size: 96, color: Colors.white38),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    tooltip: context.tr('pto_a11y_close_camera'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.tr('pto_camera_title'),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Semantics(
                  button: true,
                  label: context.tr('pto_a11y_capture_evidence_photo'),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(
                      context,
                      '$mockEvidencePrefix${DateTime.now().millisecondsSinceEpoch}',
                    ),
                    child: Container(
                      width: 76,
                      height: 76,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(Icons.camera_alt, color: Vx.blue),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EvidenceThumbnail extends StatelessWidget {
  const EvidenceThumbnail({super.key, required this.path, required this.semanticLabel});

  final String path;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2F7BF5), Color(0xFF0B47B0)],
          ),
        ),
        child: const Icon(Icons.photo, color: Colors.white),
      ),
    );
  }
}
