import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

// 1. GLOBAL SWITCH (The "State" of your app)
// We use a ValueNotifier so updates happen instantly across screens.
final ValueNotifier<bool> isTagalogNotifier = ValueNotifier<bool>(false);

// 2. THE MAGIC WIDGET
class AutoTranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const AutoTranslatedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  @override
  State<AutoTranslatedText> createState() => _AutoTranslatedTextState();
}

class _AutoTranslatedTextState extends State<AutoTranslatedText> {
  final GoogleTranslator translator = GoogleTranslator();
  String? _translatedText;

  @override
  void initState() {
    super.initState();
    // Listen for changes to the global switch
    isTagalogNotifier.addListener(_updateTranslation);
    _updateTranslation(); // Run once on load
  }

  @override
  void dispose() {
    isTagalogNotifier.removeListener(_updateTranslation);
    super.dispose();
  }

  void _updateTranslation() {
    if (!mounted) return;

    if (isTagalogNotifier.value) {
      // If Switch is ON -> Translate to Tagalog
      translator.translate(widget.text, to: 'tl').then((result) {
        if (mounted) {
          setState(() {
            _translatedText = result.text;
          });
        }
      });
    } else {
      // If Switch is OFF -> Show Original (English)
      if (mounted && _translatedText != null) {
        setState(() {
          _translatedText = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _translatedText ?? widget.text, // Show translated or original
      style: widget.style,
      textAlign: widget.textAlign,
      overflow: widget.overflow,
      maxLines: widget.maxLines,
    );
  }
}
