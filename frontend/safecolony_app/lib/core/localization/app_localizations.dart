import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SafeColonyLocalizations {
  final Locale locale;
  SafeColonyLocalizations(this.locale);

  static const supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('te'),
    Locale('kn'),
    Locale('ta'),
    Locale('ml'),
  ];

  static const _values = <String, Map<String, String>>{
    'en': {
      'language': 'Language',
      'english': 'English',
      'hindi': 'Hindi',
      'telugu': 'Telugu',
      'kannada': 'Kannada',
      'tamil': 'Tamil',
      'malayalam': 'Malayalam',
      'notifications': 'Notifications',
      'maintenanceFinance': 'Maintenance & Finance',
      'communityChat': 'Community Chat',
      'deliveries': 'Deliveries',
      'communityExpenses': 'Community Expenses',
      'recentActivity': 'Recent Activity',
      'viewAll': 'View all',
      'myProfile': 'My Profile',
      'settings': 'Settings',
      'logout': 'Logout',
      'speakToAi': 'Speak to SafeColony AI',
      'readAloud': 'Read aloud',
    },
    'hi': {
      'language': 'भाषा',
      'english': 'अंग्रेज़ी',
      'hindi': 'हिन्दी',
      'telugu': 'तेलुगु',
      'kannada': 'कन्नड़',
      'tamil': 'तमिल',
      'malayalam': 'मलयालम',
      'notifications': 'सूचनाएं',
      'maintenanceFinance': 'रखरखाव और वित्त',
      'communityChat': 'कम्युनिटी चैट',
      'deliveries': 'डिलीवरी',
      'communityExpenses': 'कम्युनिटी खर्च',
      'recentActivity': 'हाल की गतिविधि',
      'viewAll': 'सभी देखें',
      'myProfile': 'मेरी प्रोफ़ाइल',
      'settings': 'सेटिंग्स',
      'logout': 'लॉगआउट',
      'speakToAi': 'SafeColony AI से बोलें',
      'readAloud': 'जोर से पढ़ें',
    },
    'te': {
      'language': 'భాష',
      'english': 'ఆంగ్లం',
      'hindi': 'హిందీ',
      'telugu': 'తెలుగు',
      'kannada': 'కన్నడ',
      'tamil': 'తమిళం',
      'malayalam': 'మలయాళం',
      'notifications': 'నోటిఫికేషన్లు',
      'maintenanceFinance': 'మెయింటెనెన్స్ & ఫైనాన్స్',
      'communityChat': 'కమ్యూనిటీ చాట్',
      'deliveries': 'డెలివరీలు',
      'communityExpenses': 'కమ్యూనిటీ ఖర్చులు',
      'recentActivity': 'ఇటీవలి కార్యకలాపాలు',
      'viewAll': 'అన్నీ చూడండి',
      'myProfile': 'నా ప్రొఫైల్',
      'settings': 'సెట్టింగ్స్',
      'logout': 'లాగ్ అవుట్',
      'speakToAi': 'SafeColony AIతో మాట్లాడండి',
      'readAloud': 'చదివి వినిపించు',
    },
    'kn': {
      'language': 'ಭಾಷೆ',
      'english': 'ಇಂಗ್ಲಿಷ್',
      'hindi': 'ಹಿಂದಿ',
      'telugu': 'ತೆಲುಗು',
      'kannada': 'ಕನ್ನಡ',
      'tamil': 'ತಮಿಳು',
      'malayalam': 'ಮಲಯಾಳಂ',
      'notifications': 'ಅಧಿಸೂಚನೆಗಳು',
      'maintenanceFinance': 'ನಿರ್ವಹಣೆ ಮತ್ತು ಹಣಕಾಸು',
      'communityChat': 'ಸಮುದಾಯ ಚಾಟ್',
      'deliveries': 'ಡೆಲಿವರಿಗಳು',
      'communityExpenses': 'ಸಮುದಾಯ ವೆಚ್ಚಗಳು',
      'recentActivity': 'ಇತ್ತೀಚಿನ ಚಟುವಟಿಕೆ',
      'viewAll': 'ಎಲ್ಲಾ ನೋಡಿ',
      'myProfile': 'ನನ್ನ ಪ್ರೊಫೈಲ್',
      'settings': 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
      'logout': 'ಲಾಗ್ ಔಟ್',
      'speakToAi': 'SafeColony AI ಜೊತೆ ಮಾತನಾಡಿ',
      'readAloud': 'ಓದಿ ಕೇಳಿಸಿ',
    },
    'ta': {
      'language': 'மொழி',
      'english': 'ஆங்கிலம்',
      'hindi': 'இந்தி',
      'telugu': 'தெலுங்கு',
      'kannada': 'கன்னடம்',
      'tamil': 'தமிழ்',
      'malayalam': 'மலையாளம்',
      'notifications': 'அறிவிப்புகள்',
      'maintenanceFinance': 'பராமரிப்பு மற்றும் நிதி',
      'communityChat': 'சமூக அரட்டை',
      'deliveries': 'டெலிவரிகள்',
      'communityExpenses': 'சமூக செலவுகள்',
      'recentActivity': 'சமீபத்திய செயல்பாடு',
      'viewAll': 'அனைத்தையும் காண்க',
      'myProfile': 'என் சுயவிவரம்',
      'settings': 'அமைப்புகள்',
      'logout': 'வெளியேறு',
      'speakToAi': 'SafeColony AI உடன் பேசுங்கள்',
      'readAloud': 'சத்தமாக வாசிக்க',
    },
    'ml': {
      'language': 'ഭാഷ',
      'english': 'ഇംഗ്ലീഷ്',
      'hindi': 'ഹിന്ദി',
      'telugu': 'തെലുങ്ക്',
      'kannada': 'കന്നഡ',
      'tamil': 'തമിഴ്',
      'malayalam': 'മലയാളം',
      'notifications': 'അറിയിപ്പുകൾ',
      'maintenanceFinance': 'മെയിന്റനൻസ് & ഫിനാൻസ്',
      'communityChat': 'കമ്മ്യൂണിറ്റി ചാറ്റ്',
      'deliveries': 'ഡെലിവറികൾ',
      'communityExpenses': 'കമ്മ്യൂണിറ്റി ചെലവുകൾ',
      'recentActivity': 'സമീപകാല പ്രവർത്തനം',
      'viewAll': 'എല്ലാം കാണുക',
      'myProfile': 'എന്റെ പ്രൊഫൈൽ',
      'settings': 'ക്രമീകരണങ്ങൾ',
      'logout': 'ലോഗൗട്ട്',
      'speakToAi': 'SafeColony AIയോട് സംസാരിക്കുക',
      'readAloud': 'വായിച്ച് കേൾപ്പിക്കുക',
    },
  };

  String text(String key) => _values[locale.languageCode]?[key] ?? _values['en']![key] ?? key;

  static SafeColonyLocalizations of(BuildContext context) =>
      Localizations.of<SafeColonyLocalizations>(context, SafeColonyLocalizations)!;
}

class SafeColonyLocalizationsDelegate extends LocalizationsDelegate<SafeColonyLocalizations> {
  const SafeColonyLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => SafeColonyLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);
  @override
  Future<SafeColonyLocalizations> load(Locale locale) async => SafeColonyLocalizations(locale);
  @override
  bool shouldReload(covariant LocalizationsDelegate<SafeColonyLocalizations> old) => false;
}

class AppLocaleController extends ChangeNotifier {
  AppLocaleController._();
  static final instance = AppLocaleController._();
  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('safecolony_locale');
    if (code != null && SafeColonyLocalizations.supportedLocales.any((l) => l.languageCode == code)) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!SafeColonyLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode)) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('safecolony_locale', locale.languageCode);
  }
}
