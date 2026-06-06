import 'package:flutter/material.dart';
import 'package:kafi_app/views/shared/kafi_colors.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

class KafiPasswordStrength extends StatelessWidget {
  const KafiPasswordStrength({super.key, required this.password});

  final String password;

  int get _strength {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score;
  }

  String get _label {
    if (password.isEmpty) return '';
    if (_strength <= 1) return 'Weak';
    if (_strength <= 2) return 'Fair';
    if (_strength <= 3) return 'Good';
    return 'Strong';
  }

  Color get _color {
    if (_strength <= 1) return KafiColors.redD;
    if (_strength <= 2) return Colors.orange;
    if (_strength <= 3) return KafiColors.grnL;
    return KafiColors.grnD;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _strength / 5,
                  backgroundColor: KafiColors.ts.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(_color),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(_label, style: KafiTheme.nunito(12, color: _color, w: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        _check('At least 8 characters', password.length >= 8),
        _check('Uppercase letter', RegExp(r'[A-Z]').hasMatch(password)),
        _check('Number', RegExp(r'[0-9]').hasMatch(password)),
        _check('Special character', RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)),
      ],
    );
  }

  Widget _check(String text, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: ok ? KafiColors.grnD : KafiColors.ts,
          ),
          const SizedBox(width: 6),
          Text(text, style: KafiTheme.nunito(12, color: ok ? KafiColors.td : KafiColors.ts)),
        ],
      ),
    );
  }
}
