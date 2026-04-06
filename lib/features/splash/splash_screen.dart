import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/state/app_providers.dart';
import '../../core/theme/color_palette.dart';
import '../../shared/widgets/app_button.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: AppDurations.medium)..forward();
  late final Animation<double> _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _setLocale(Locale locale) async {
    await ref.read(localeProvider.notifier).setLocale(locale);
    await context.setLocale(locale);
  }

  Future<void> _setTheme(ThemeMode mode) async {
    await ref.read(themeModeProvider.notifier).setThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [ColorPalette.primary, ColorPalette.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(
                      children: [
                        Image.asset(
                          AppStrings.logoAsset,
                          width: 160,
                          height: 160,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.ac_unit_rounded, size: 140, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.appName,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'tagline'.tr(),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.72)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      _SectionLabel(title: 'language'.tr()),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _ChoiceChip(label: 'العربية', selected: locale.languageCode == 'ar', onTap: () => _setLocale(const Locale('ar'))),
                          _ChoiceChip(label: 'Français', selected: locale.languageCode == 'fr', onTap: () => _setLocale(const Locale('fr'))),
                          _ChoiceChip(label: 'English', selected: locale.languageCode == 'en', onTap: () => _setLocale(const Locale('en'))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SectionLabel(title: 'theme'.tr()),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _ChoiceChip(label: 'Light ☀', selected: themeMode == ThemeMode.light, onTap: () => _setTheme(ThemeMode.light)),
                          _ChoiceChip(label: 'Dark 🌙', selected: themeMode == ThemeMode.dark, onTap: () => _setTheme(ThemeMode.dark)),
                        ],
                      ),
                      const SizedBox(height: 28),
                      AppButton(
                        label: 'getStarted'.tr(),
                        onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? ColorPalette.primary : Colors.white;
    final background = selected ? Colors.white : Colors.transparent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: AppDurations.short,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white),
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: foreground, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
    );
  }
}
