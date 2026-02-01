import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ReceiptData {
  final double? amount;
  final DateTime? date;
  final String text;
  final String? merchantName;
  final double? confidence; // 0.0 to 1.0
  final String? paymentMethod;

  ReceiptData({
    this.amount,
    this.date,
    required this.text,
    this.merchantName,
    this.confidence,
    this.paymentMethod,
  });

  ReceiptData copyWith({
    double? amount,
    DateTime? date,
    String? text,
    String? merchantName,
    double? confidence,
    String? paymentMethod,
  }) {
    return ReceiptData(
      amount: amount ?? this.amount,
      date: date ?? this.date,
      text: text ?? this.text,
      merchantName: merchantName ?? this.merchantName,
      confidence: confidence ?? this.confidence,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
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
    final List<TextBlock> blocks = recognizedText.blocks;

    // Extract data with improved algorithms
    final amount = _extractAmount(text);
    final date = _extractDate(text);
    final merchantResult = _extractMerchantName(blocks);
    final paymentMethod = _extractPaymentMethod(text);

    // Calculate overall confidence
    double confidence = 0.0;
    int confidenceFactors = 0;

    if (amount != null) {
      confidence += 0.3;
      confidenceFactors++;
    }
    if (date != null) {
      confidence += 0.2;
      confidenceFactors++;
    }
    if (merchantResult['name'] != null) {
      confidence += merchantResult['confidence'] as double;
      confidenceFactors++;
    }

    if (confidenceFactors > 0) {
      confidence = confidence / (confidenceFactors > 1 ? 1.5 : 1.0);
    }

    return ReceiptData(
      amount: amount,
      date: date,
      text: text,
      merchantName: merchantResult['name'] as String?,
      confidence: confidence.clamp(0.0, 1.0),
      paymentMethod: paymentMethod,
    );
  }

  /// Enhanced amount extraction - looks for "TOTAL" keyword and nearby amounts
  double? _extractAmount(String text) {
    final lines = text.split('\n');
    
    // Strategy 1: Look for "TOTAL" keyword and extract nearby amount
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();
      if (line.contains('TOTAL') || line.contains('AMOUNT DUE')) {
        // Look in current line and next 2 lines
        for (int j = i; j < (i + 3).clamp(0, lines.length); j++) {
          final amount = _extractAmountFromLine(lines[j]);
          if (amount != null && amount > 0) return amount;
        }
      }
    }

    // Strategy 2: Find largest amount (likely the total)
    final RegExp regExp = RegExp(r'[$€£¥]?\s?(\d+[.,]\d{2})');
    final Iterable<Match> matches = regExp.allMatches(text);
    
    double maxAmount = 0.0;
    for (final Match m in matches) {
      if (m.group(1) != null) {
        String amountStr = m.group(1)!.replaceAll(',', '.');
        double? val = double.tryParse(amountStr);
        if (val != null && val > maxAmount) {
          maxAmount = val;
        }
      }
    }
    return maxAmount > 0 ? maxAmount : null;
  }

  double? _extractAmountFromLine(String line) {
    final RegExp regExp = RegExp(r'[$€£¥]?\s?(\d+[.,]\d{2})');
    final Match? match = regExp.firstMatch(line);
    if (match != null && match.group(1) != null) {
      String amountStr = match.group(1)!.replaceAll(',', '.');
      return double.tryParse(amountStr);
    }
    return null;
  }

  /// Enhanced date extraction with multiple format support
  DateTime? _extractDate(String text) {
    // Try multiple date formats
    final patterns = [
      RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})'), // DD/MM/YYYY or MM/DD/YYYY
      RegExp(r'(\d{4}[/-]\d{1,2}[/-]\d{1,2})'),   // YYYY-MM-DD
      RegExp(r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2},?\s+\d{4}', caseSensitive: false), // Month DD, YYYY
    ];

    for (final pattern in patterns) {
      final Match? match = pattern.firstMatch(text);
      if (match != null) {
        try {
          String dateStr = match.group(0)!;
          
          // Try parsing with different formats
          final formats = [
            DateFormat('dd/MM/yyyy'),
            DateFormat('MM/dd/yyyy'),
            DateFormat('yyyy-MM-dd'),
            DateFormat('MMM dd, yyyy'),
            DateFormat('MMMM dd, yyyy'),
          ];

          for (final format in formats) {
            try {
              dateStr = dateStr.replaceAll('-', '/');
              return format.parse(dateStr);
            } catch (e) {
              continue;
            }
          }

          // Manual parsing for DD/MM/YYYY
          if (dateStr.contains('/')) {
            List<String> parts = dateStr.split('/');
            if (parts.length == 3) {
              int day = int.parse(parts[0]);
              int month = int.parse(parts[1]);
              int year = int.parse(parts[2]);
              if (year < 100) year += 2000;
              
              // Validate date
              if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
                return DateTime(year, month, day);
              }
            }
          }
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }

  /// Intelligent merchant name extraction
  Map<String, dynamic> _extractMerchantName(List<TextBlock> blocks) {
    if (blocks.isEmpty) {
      return {'name': null, 'confidence': 0.0};
    }

    // Strategy: Merchant name is usually in the top 30% of the receipt
    // and is the longest capitalized text without numbers
    
    final candidates = <Map<String, dynamic>>[];
    
    for (int i = 0; i < (blocks.length * 0.3).ceil(); i++) {
      final block = blocks[i];
      final text = block.text.trim();
      
      // Skip if contains too many numbers
      if (RegExp(r'\d').allMatches(text).length > text.length * 0.3) continue;
      
      // Skip if contains common non-merchant keywords
      final skipKeywords = ['receipt', 'invoice', 'tax', 'total', 'date', 'time', 'phone', 'address'];
      if (skipKeywords.any((kw) => text.toLowerCase().contains(kw))) continue;
      
      // Skip if too short or too long
      if (text.length < 3 || text.length > 50) continue;
      
      // Calculate confidence based on:
      // 1. Position (higher = better)
      // 2. Length (moderate length preferred)
      // 3. Capitalization
      double confidence = 0.0;
      
      // Position score (0.4 max)
      confidence += (1 - (i / blocks.length)) * 0.4;
      
      // Length score (0.3 max) - prefer 10-30 chars
      final lengthScore = text.length >= 10 && text.length <= 30 ? 0.3 : 0.15;
      confidence += lengthScore;
      
      // Capitalization score (0.3 max)
      final upperCount = text.split('').where((c) => c == c.toUpperCase() && c != c.toLowerCase()).length;
      final capRatio = upperCount / text.length;
      if (capRatio > 0.5) confidence += 0.3;
      
      candidates.add({
        'name': text,
        'confidence': confidence,
      });
    }

    // Return the candidate with highest confidence
    if (candidates.isEmpty) {
      return {'name': null, 'confidence': 0.0};
    }

    candidates.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
    return candidates.first;
  }

  /// Extract payment method (Visa, Mastercard, etc.)
  String? _extractPaymentMethod(String text) {
    final methods = {
      'visa': RegExp(r'\bvisa\b', caseSensitive: false),
      'mastercard': RegExp(r'\b(mastercard|mc)\b', caseSensitive: false),
      'amex': RegExp(r'\b(amex|american express)\b', caseSensitive: false),
      'discover': RegExp(r'\bdiscover\b', caseSensitive: false),
      'cash': RegExp(r'\bcash\b', caseSensitive: false),
      'debit': RegExp(r'\bdebit\b', caseSensitive: false),
    };

    for (final entry in methods.entries) {
      if (entry.value.hasMatch(text)) {
        return entry.key.toUpperCase();
      }
    }

    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
