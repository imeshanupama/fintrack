import 'package:hive_flutter/hive_flutter.dart';
import 'split_participant.dart';

part 'bill_split.g.dart';

@HiveType(typeId: 10)
class BillSplit extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double totalAmount;

  @HiveField(3)
  final String currencyCode;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final List<SplitParticipant> participants;

  @HiveField(6)
  final double? myShare;

  @HiveField(7)
  final String? transactionId; // Link to transaction if user's share was added to expenses

  @HiveField(8)
  final String? receiptPath; // Path to receipt image

  @HiveField(9)
  final String? note;

  @HiveField(10)
  final DateTime createdAt;

  BillSplit({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.currencyCode,
    required this.date,
    required this.participants,
    this.myShare,
    this.transactionId,
    this.receiptPath,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isFullySettled {
    return participants.every((p) => p.isPaid);
  }

  double get pendingAmount {
    return participants
        .where((p) => !p.isPaid)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  int get paidCount {
    return participants.where((p) => p.isPaid).length;
  }

  int get totalParticipants {
    return participants.length;
  }

  BillSplit copyWith({
    String? id,
    String? title,
    double? totalAmount,
    String? currencyCode,
    DateTime? date,
    List<SplitParticipant>? participants,
    double? myShare,
    String? transactionId,
    String? receiptPath,
    String? note,
    DateTime? createdAt,
  }) {
    return BillSplit(
      id: id ?? this.id,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      currencyCode: currencyCode ?? this.currencyCode,
      date: date ?? this.date,
      participants: participants ?? this.participants,
      myShare: myShare ?? this.myShare,
      transactionId: transactionId ?? this.transactionId,
      receiptPath: receiptPath ?? this.receiptPath,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
