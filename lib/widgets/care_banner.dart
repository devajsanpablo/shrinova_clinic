import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'clinic_art.dart';

class CareBanner extends StatelessWidget {
  const CareBanner({
    super.key,
    required this.doctor,
    required this.onPrimary,
    required this.onSecondary,
  });
  final bool doctor;
  final VoidCallback onPrimary, onSecondary;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final roomy = constraints.maxWidth >= 620;
      return Container(
        padding: EdgeInsets.all(roomy ? 28 : 22),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3F1),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFDDEBE7)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        size: 15,
                        color: AppColors.teal,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'EVERY VISIT MATTERS',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.4,
                          color: Color(0xFF38746A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Text(
                    doctor
                        ? 'More focus.\nBetter patient care.'
                        : 'A good day for\ngreat patient care.',
                    style: TextStyle(
                      fontFamily: AppTypography.heading,
                      fontSize: roomy ? 28 : 25,
                      letterSpacing: -.8,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF193F3C),
                    ),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    doctor
                        ? 'Your patient history, notes, and next steps. All in one place.'
                        : 'Welcome patients, organize visits, and keep your clinic moving.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF55756F),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 21),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: onPrimary,
                        icon: Icon(
                          doctor
                              ? Icons.arrow_forward_rounded
                              : Icons.add_rounded,
                          size: 18,
                        ),
                        label: Text(doctor ? 'Open my queue' : 'Create ticket'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onSecondary,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFD7E4E1)),
                        ),
                        icon: Icon(
                          doctor
                              ? Icons.check_circle_outline
                              : Icons.person_add_alt_1,
                          size: 18,
                        ),
                        label: Text(
                          doctor ? 'View all visits' : 'Register patient',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (roomy) ...[
              const SizedBox(width: 20),
              SizedBox(
                width: constraints.maxWidth > 900 ? 290 : 215,
                child: const ClinicArt(height: 205),
              ),
            ],
          ],
        ),
      );
    },
  );
}
