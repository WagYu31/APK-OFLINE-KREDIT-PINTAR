import 'package:flutter/material.dart';

class CardBadge extends StatelessWidget {
  final bool isKuning;
  final bool isMerah;
  final bool isDiblokir;
  final VoidCallback? onKuningTap;
  final VoidCallback? onMerahTap;

  const CardBadge({
    super.key,
    this.isKuning = false,
    this.isMerah = false,
    this.isDiblokir = false,
    this.onKuningTap,
    this.onMerahTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Prioritas Diblokir
    if (isDiblokir) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.6)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, size: 11, color: Color(0xFFEF4444)),
            SizedBox(width: 3),
            Text(
              'Diblokir',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      );
    }

    final List<Widget> badges = [];

    // 2. Kartu Kuning Badge
    if (isKuning) {
      badges.add(
        GestureDetector(
          onTap: onKuningTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_rounded, size: 11, color: Colors.black87),
                SizedBox(width: 3),
                Text(
                  'Kartu Kuning',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Kartu Merah Badge
    if (isMerah) {
      badges.add(
        GestureDetector(
          onTap: onMerahTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block_rounded, size: 11, color: Colors.white),
                SizedBox(width: 3),
                Text(
                  'Kartu Merah',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 4. Jika Tidak Ada Peringatan (Status Baik)
    if (!isKuning && !isMerah) {
      if (onKuningTap != null || onMerahTap != null) {
        badges.add(
          GestureDetector(
            onTap: onKuningTap ?? onMerahTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF10B981)),
                  SizedBox(width: 3),
                  Text(
                    'Status Baik',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: badges,
    );
  }
}
