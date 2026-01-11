import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'report_service.dart';

final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService();
});
