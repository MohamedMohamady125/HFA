import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'welcome_title': 'Welcome to HFA!',
      'branch_count': 'We have 9 branches across Cairo and Giza!',
      'nearest_branch': 'Nearest Branch',
      'branch_name': 'Main Branch - Downtown',
      'practice_time': 'Practice Time: Mon-Fri, 4PM-6PM',
      'login': 'Login',
      'register': "Don't have an account? Register",
      'view_branches': 'View Our Branches',
      'admin_login': 'Admin Login',
      'switch_language': 'Switch to Arabic',
    },
    'ar': {
      'welcome_title': '\u0645\u0631\u062d\u0628\u064b\u0627 \u0628\u0643 \u0641\u064a HFA!',
      'branch_count': '\u0644\u062f\u064a\u0646\u0627 \u0669 \u0641\u0631\u0648\u0639 \u0641\u064a \u0627\u0644\u0642\u0627\u0647\u0631\u0629 \u0648\u0627\u0644\u062c\u064a\u0632\u0629!',
      'nearest_branch': '\u0623\u0642\u0631\u0628 \u0641\u0631\u0639',
      'branch_name': '\u0627\u0644\u0641\u0631\u0639 \u0627\u0644\u0631\u0626\u064a\u0633\u064a - \u0648\u0633\u0637 \u0627\u0644\u0628\u0644\u062f',
      'practice_time': '\u0645\u0648\u0627\u0639\u064a\u062f \u0627\u0644\u062a\u0645\u0631\u064a\u0646: \u0645\u0646 \u0627\u0644\u0625\u062b\u0646\u064a\u0646 \u0625\u0644\u0649 \u0627\u0644\u062c\u0645\u0639\u0629\u060c \u0664 \u0625\u0644\u0649 \u0666 \u0645\u0633\u0627\u0621\u064b',
      'login': '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644',
      'register': '\u0644\u064a\u0633 \u0644\u062f\u064a\u0643 \u062d\u0633\u0627\u0628\u061f \u0633\u062c\u0644 \u0627\u0644\u0622\u0646',
      'view_branches': '\u0639\u0631\u0636 \u062c\u0645\u064a\u0639 \u0627\u0644\u0641\u0631\u0648\u0639',
      'admin_login': '\u062a\u0633\u062c\u064a\u0644 \u062f\u062e\u0648\u0644 \u0645\u062f\u0631\u0628',
      'switch_language': '\u0627\u0644\u062a\u0628\u062f\u064a\u0644 \u0625\u0644\u0649 \u0627\u0644\u0625\u0646\u062c\u0644\u064a\u0632\u064a\u0629',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void toggleLocale() {
    _locale = _locale.languageCode == 'en' ? const Locale('ar') : const Locale('en');
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}
