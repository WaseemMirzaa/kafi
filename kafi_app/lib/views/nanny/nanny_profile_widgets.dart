import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_input.dart';

class NannyExperienceDraft {
  final employerController = TextEditingController();
  final locationController = TextEditingController();
  final childrenController = TextEditingController();
  final dutiesController = TextEditingController();

  void dispose() {
    employerController.dispose();
    locationController.dispose();
    childrenController.dispose();
    dutiesController.dispose();
  }
}

class NannyReferenceDraft {
  final yearsController = TextEditingController();
  final confirmsController = TextEditingController();

  void dispose() {
    yearsController.dispose();
    confirmsController.dispose();
  }
}

/// HTML `.exp-card`
class NannyExperienceCard extends StatelessWidget {
  const NannyExperienceCard({
    super.key,
    required this.index,
    required this.entry,
    required this.onDelete,
  });

  final int index;
  final NannyExperienceDraft entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KafiColors.cardBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [KafiColors.rose, KafiColors.roseDark],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.fredoka(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Previous job',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: KafiColors.textDark,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.close, size: 14, color: KafiColors.rose),
              ),
            ],
          ),
          const SizedBox(height: 8),
          KafiInput(
            label: 'Family / Employer name',
            controller: entry.employerController,
            hint: 'Employer name',
          ),
          const SizedBox(height: 8),
          KafiInput(
            label: 'City & Country',
            controller: entry.locationController,
            hint: 'Dubai, UAE',
          ),
          const SizedBox(height: 8),
          KafiInput(
            label: 'Children cared for',
            controller: entry.childrenController,
            hint: 'Ages and count',
          ),
          const SizedBox(height: 8),
          KafiInput(
            label: 'Main duties',
            controller: entry.dutiesController,
            maxLines: 3,
            hint: 'Describe your duties',
          ),
        ],
      ),
    );
  }
}

/// HTML `.ref-card`
class NannyReferenceCard extends StatelessWidget {
  const NannyReferenceCard({
    super.key,
    required this.index,
    required this.entry,
  });

  final int index;
  final NannyReferenceDraft entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KafiColors.cardBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [KafiColors.green, KafiColors.greenDark],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.fredoka(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Reference #${index + 1}',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: KafiColors.textDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: KafiColors.greenLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, size: 8, color: KafiColors.greenDark),
                    const SizedBox(width: 2),
                    Text(
                      'Callable',
                      style: GoogleFonts.fredoka(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: KafiColors.greenDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          KafiInput(
            label: 'Year(s) worked',
            controller: entry.yearsController,
            hint: '2022 – 2024',
          ),
          const SizedBox(height: 8),
          KafiInput(
            label: 'What they can confirm',
            controller: entry.confirmsController,
            hint: 'Skills and character',
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: KafiColors.greenLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'You will share this contact directly during your interview or trial',
              style: GoogleFonts.nunito(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: KafiColors.greenDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// HTML `.doc-item`
class NannyDocItem extends StatelessWidget {
  const NannyDocItem({
    super.key,
    required this.name,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBg,
    this.iconColor = KafiColors.roseDark,
    this.iconBg = KafiColors.rosePale,
    this.highlight = false,
    this.onUpload,
  });

  final String name;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;
  final Color statusBg;
  final Color iconColor;
  final Color iconBg;
  final bool highlight;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFFFFBF0) : Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: highlight ? const Color(0xFFFFD080) : KafiColors.cardBorder,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.description_outlined, size: 16, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: KafiColors.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: highlight ? const Color(0xFFA06010) : KafiColors.textSoft,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.fredoka(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              if (onUpload != null) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onUpload,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: KafiColors.purpleLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Upload',
                      style: GoogleFonts.fredoka(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: KafiColors.purple,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// HTML `.add-btn`
class NannyAddButton extends StatelessWidget {
  const NannyAddButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: KafiColors.rosePale,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: KafiColors.roseLight, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 14, color: KafiColors.roseDark),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: KafiColors.roseDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
