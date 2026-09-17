import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class PasswordStrengthMeter extends StatelessWidget {
  final String password;

  const PasswordStrengthMeter({
    super.key,
    required this.password,
  });

  bool get _hasMinLength => password.length >= 8;
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(password);
  bool get _hasUpperLower =>
      RegExp(r'[a-z]').hasMatch(password) && RegExp(r'[A-Z]').hasMatch(password);
  bool get _hasSpecial =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

  int get _score {
    if (password.isEmpty) return 0;
    int count = 0;
    if (_hasMinLength) count++;
    if (_hasNumber) count++;
    if (_hasUpperLower) count++;
    if (_hasSpecial) count++;
    return count;
  }

  Color _getStrengthColor(int score) {
    switch (score) {
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.orangeAccent;
      case 3:
        return Colors.amber;
      case 4:
        return const Color(0xFF2ECC71); // Emerald Green
      default:
        return Colors.red.shade300;
    }
  }

  String _getStrengthTextKey(int score) {
    switch (score) {
      case 1:
        return 'strengthVeryWeak';
      case 2:
        return 'strengthWeak';
      case 3:
        return 'strengthMedium';
      case 4:
        return 'strengthStrong';
      default:
        return 'strengthVeryWeak';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final languageProvider = context.watch<LanguageProvider>();
    final score = _score;
    final color = _getStrengthColor(score);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Score Label & Text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Password Strength:',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
                ),
                child: Text(
                  languageProvider.tr(_getStrengthTextKey(score)),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 4-Segment Progress Bar
          Row(
            children: List.generate(4, (index) {
              final isActive = index < score;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 3 ? 4.0 : 0.0),
                  decoration: BoxDecoration(
                    color: isActive ? color : (isDark ? Colors.white12 : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),

          // Criteria Badges / Checklist
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildRuleBadge(context, languageProvider.tr('ruleMinLength'), _hasMinLength),
              _buildRuleBadge(context, languageProvider.tr('ruleNumber'), _hasNumber),
              _buildRuleBadge(context, languageProvider.tr('ruleUpperLower'), _hasUpperLower),
              _buildRuleBadge(context, languageProvider.tr('ruleSpecialChar'), _hasSpecial),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRuleBadge(BuildContext context, String text, bool isMet) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = const Color(0xFF2ECC71);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isMet
            ? activeColor.withValues(alpha: 0.12)
            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isMet
              ? activeColor.withValues(alpha: 0.4)
              : (isDark ? Colors.white10 : Colors.black12),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 11,
            color: isMet ? activeColor : (isDark ? Colors.white38 : Colors.black38),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
              color: isMet
                  ? (isDark ? Colors.white : Colors.black87)
                  : (isDark ? Colors.white38 : Colors.black38),
            ),
          ),
        ],
      ),
    );
  }
}
