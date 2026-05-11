import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';

class GuestHomeScreen extends StatelessWidget {
  const GuestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: SafeArea(
        child: Stack(
          children: [
            // Content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                child: Column(
                  children: [
                    // Logo & Header
                    Image.asset('assets/images/hfanew.png', width: 120, height: 120),
                    const SizedBox(height: 12),
                    const Text('Academy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF), letterSpacing: 0.5)),
                    const SizedBox(height: 16),
                    Text(l10n.translate('welcome_title'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                    const SizedBox(height: 6),
                    Text(l10n.translate('branch_count'), style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    const SizedBox(height: 32),

                    // Main Card
                    Container(
                      constraints: const BoxConstraints(maxWidth: 360),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
                        boxShadow: [BoxShadow(color: const Color(0xFF0EA5E9).withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8))],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Branch Info
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF00D4FF).withValues(alpha: 0.1)),
                                  child: const Center(child: Text('\u{1F4CD}', style: TextStyle(fontSize: 18))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(l10n.translate('nearest_branch'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF00D4FF))),
                                      const SizedBox(height: 6),
                                      Text(l10n.translate('branch_name'), style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 2),
                                      Text(l10n.translate('practice_time'), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => context.push('/login'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00D4FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                              ),
                              child: Text(l10n.translate('login'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => context.push('/register'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF00D4FF),
                                side: const BorderSide(color: Color(0xFF00D4FF), width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(l10n.translate('register'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // View Branches
                          TextButton(
                            onPressed: () {},
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(l10n.translate('view_branches'), style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w500, fontSize: 13)),
                                const SizedBox(width: 6),
                                const Text('\u{2192}', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Language Toggle - Bottom Left
            Positioned(
              bottom: 32, left: 20,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                elevation: 3,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => localeProvider.toggleLocale(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Text(
                      localeProvider.locale.languageCode == 'en' ? '\u0639\u0631\u0628\u064A' : 'EN',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                  ),
                ),
              ),
            ),

            // Admin Button - Bottom Right
            Positioned(
              bottom: 32, right: 20,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(side: BorderSide(color: Color(0xFFE2E8F0))),
                elevation: 6,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => context.push('/admin-login'),
                  child: const SizedBox(width: 48, height: 48, child: Center(child: Text('\u{2699}\u{FE0F}', style: TextStyle(fontSize: 16)))),
                ),
              ),
            ),

            // Head Coach Button - Top Right
            Positioned(
              top: 50, right: 20,
              child: Material(
                color: Colors.white,
                shape: CircleBorder(side: BorderSide(color: const Color(0xFF00D4FF))),
                elevation: 6,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => context.push('/head-coach-login'),
                  child: const SizedBox(width: 48, height: 48, child: Center(child: Text('\u{1F451}', style: TextStyle(fontSize: 16)))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
