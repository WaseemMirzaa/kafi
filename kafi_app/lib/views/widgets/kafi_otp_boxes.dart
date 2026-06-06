import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kafi_app/utils/constants/auth_constants.dart';
import 'package:kafi_app/views/shared/kafi_colors.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

class KafiOtpBoxes extends StatefulWidget {
  const KafiOtpBoxes({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<KafiOtpBoxes> createState() => _KafiOtpBoxesState();
}

class _KafiOtpBoxesState extends State<KafiOtpBoxes> {
  final _controllers = List.generate(AuthConstants.otpLength, (_) => TextEditingController());
  final _focusNodes = List.generate(AuthConstants.otpLength, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _notify() {
    widget.onChanged(_controllers.map((c) => c.text).join());
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(AuthConstants.otpLength, (i) {
        return Container(
          width: 48,
          height: 52,
          margin: EdgeInsets.only(right: i < AuthConstants.otpLength - 1 ? 8 : 0),
          child: TextField(
            controller: _controllers[i],
            focusNode: _focusNodes[i],
            textAlign: TextAlign.center,
            maxLength: 1,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: KafiTheme.nunito(20, color: KafiColors.td, w: FontWeight.w900),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: KafiColors.inputBg,
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: KafiColors.cardBorder, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: KafiColors.roseD, width: 2),
              ),
            ),
            onChanged: (v) {
              if (v.isNotEmpty && i < AuthConstants.otpLength - 1) {
                _focusNodes[i + 1].requestFocus();
              }
              _notify();
            },
          ),
        );
      }),
    );
  }
}
