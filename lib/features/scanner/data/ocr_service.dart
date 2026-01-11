import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ReceiptData {
  final double? amount;
  final DateTime? date;
  final String text;

  ReceiptData({this.amount, this.date, required this.text});
}

final ocrServiceProvider = Provider((ref) => OCRService());

class OCRService {
  final _picker = ImagePicker();
  final _textRecognizer = TextRecognizer();

  Future<String?> pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    return image?.path;
  }

  Future<ReceiptData> scanReceipt(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    final String text = recognizedText.text;

    double? amount = _extractAmount(text);
    DateTime? date = _extractDate(text);

    return ReceiptData(amount: amount, date: date, text: text);
  }

  double? _extractAmount(String text) {
    // Regex for currency: $12.99 or 12.99
    // Looks for numbers with decimal points, optionally preceded by currency symbol
    // Prioritize the largest number found as it's usually the total
    final RegExp regExp = RegExp(r'[$€£¥]?\s?(\d+\.\d{2})');
    final Iterable<Match> matches = regExp.allMatches(text);
    
    double maxAmount = 0.0;
    for (final Match m in matches) {
      if (m.group(1) != null) {
        double? val = double.tryParse(m.group(1)!);
        if (val != null && val > maxAmount) {
          maxAmount = val;
        }
      }
    }
    return maxAmount > 0 ? maxAmount : null;
  }

  DateTime? _extractDate(String text) {
    // Basic date patterns: DD/MM/YYYY, YYYY-MM-DD
    // Note: Parsing can be complex due to DD/MM vs MM/DD ambiguity.
    // We'll try common formats.
    final RegExp dateRegExp = RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})');
    final Match? match = dateRegExp.firstMatch(text);
    
    if (match != null) {
      String dateStr = match.group(0)!;
      // Normalizing separators
      dateStr = dateStr.replaceAll('-', '/');
      try {
        // Try parsing assuming DD/MM/YYYY
        List<String> parts = dateStr.split('/');
        if (parts.length == 3) {
           int day = int.parse(parts[0]);
           int month = int.parse(parts[1]);
           int year = int.parse(parts[2]);
           if (year < 100) year += 2000;
           return DateTime(year, month, day);
        }
      } catch (e) {
        // parsing failed
      }
    }
    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
