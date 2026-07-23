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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isKuning || onKuningTap != null)
          GestureDetector(
            onTap: onKuningTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: isKuning
                    ? const Color(0xFFFFB300)
                    : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
                boxShadow: isKuning
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFFB300).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isKuning ? Icons.warning_rounded : Icons.warning_amber_rounded,
                    size: 14,
                    color: isKuning ? Colors.black87 : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Kuning',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isKuning ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (isMerah || onMerahTap != null)
          GestureDetector(
            onTap: onMerahTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isMerah
                    ? const Color(0xFFE53935)
                    : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
                boxShadow: isMerah
                    ? [
                        BoxShadow(
                          color: const Color(0xFFE53935).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isMerah ? Icons.block_rounded : Icons.block_outlined,
                    size: 14,
                    color: isMerah ? Colors.white : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isDiblokir ? 'Blokir' : 'Merah',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isMerah ? Colors.white : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
