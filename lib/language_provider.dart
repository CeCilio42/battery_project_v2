import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;
  bool get isRTL => _currentLanguage == 'ar';

  final Map<String, Map<String, String>> _translations = {
    'en': {
      'appTitle': 'Battery Monitor',
      'charging': 'Charging',
      'discharging': 'Discharging',
      'timeRemaining': '{0} hours and {1} minutes remaining',
      'minutesTo50': '{0} minutes to 50%',
      'minutesToFull': 'About {0} minutes to full charge',
      'aboutTimeRemaining': 'About {0}h {1}m remaining',
    },
    'de': {
      'appTitle': 'Batterieüberwachung',
      'charging': 'Wird geladen',
      'discharging': 'Wird entladen',
      'timeRemaining': '{0} Stunden und {1} Minuten verbleibend',
      'minutesTo50': '{0} Minuten bis 50%',
      'minutesToFull': 'Etwa {0} Minuten bis zur vollen Ladung',
      'aboutTimeRemaining': 'Etwa {0}h {1}m verbleibend',
    },
    'es': {
      'appTitle': 'Monitor de Batería',
      'charging': 'Cargando',
      'discharging': 'Descargando',
      'timeRemaining': '{0} horas y {1} minutos restantes',
      'minutesTo50': '{0} minutos hasta 50%',
      'minutesToFull': 'Aproximadamente {0} minutos hasta carga completa',
      'aboutTimeRemaining': 'Aproximadamente {0}h {1}m restantes',
    },
    'ar': {
      'appTitle': 'مراقب البطارية',
      'charging': 'جاري الشحن',
      'discharging': 'جاري التفريغ',
      'timeRemaining': 'متبقي {0} ساعة و {1} دقيقة',
      'minutesTo50': '{0} دقيقة حتى 50%',
      'minutesToFull': 'حوالي {0} دقيقة حتى اكتمال الشحن',
      'aboutTimeRemaining': 'حوالي {0} ساعة و {1} دقيقة متبقية',
    },
  };

  String translate(String key, [List<dynamic> args = const []]) {
    String text = _translations[_currentLanguage]?[key] ?? key;
    
    // Replace placeholders with arguments
    for (var i = 0; i < args.length; i++) {
      text = text.replaceAll('{$i}', args[i].toString());
    }
    
    return text;
  }

  void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
    notifyListeners();
  }
}
