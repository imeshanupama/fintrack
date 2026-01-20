import 'package:hive/hive.dart';

part 'split_participant.g.dart';

@HiveType(typeId: 9)
class SplitParticipant extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final bool isPaid;

  @HiveField(3)
  final DateTime? paidDate;

  SplitParticipant({
    required this.name,
    required this.amount,
    this.isPaid = false,
    this.paidDate,
  });

  SplitParticipant copyWith({
    String? name,
    double? amount,
    bool? isPaid,
    DateTime? paidDate,
  }) {
    return SplitParticipant(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
    );
  }

  SplitParticipant markAsPaid() {
    return copyWith(
      isPaid: true,
      paidDate: DateTime.now(),
    );
  }
}
