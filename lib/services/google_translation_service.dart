import 'package:google_translator/google_translator.dart';

class GoogleTranslationService {
  final GoogleTranslator _translator = GoogleTranslator();

  /// Translates text between English (en) and Tagalog (tl)
  Future<String> translate(String text, {required String to}) async {
    try {
      // Ensure target is valid
      String targetLang = (to == 'Tagalog' || to == 'tl') ? 'tl' : 'en';

      var translation = await _translator.translate(text, to: targetLang);
      return translation.text;
    } catch (e) {
      print('Google Translate API Error: $e');
      return text; // Fallback to original
    }
  }
}
