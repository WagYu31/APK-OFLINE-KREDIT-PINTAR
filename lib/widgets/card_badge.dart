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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, size: 12, color: Color(0xFFE53935)),
            SizedBox(width: 4),
            Text(
              'Diblokir',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE53935),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_rounded, size: 13, color: Colors.black87),
                SizedBox(width: 4),
                Text(
                  'Kartu Kuning',
                  style: TextStyle(
                    fontSize: 11,
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53935).withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block_rounded, size: 13, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Kartu Merah',
                  style: TextStyle(
                    fontSize: 11,
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF10B981)),
                  SizedBox(width: 4),
                  Text(
                    'Status Baik',
                    style: TextStyle(
                      fontSize: 11,
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: badges,
    );
  }
}
