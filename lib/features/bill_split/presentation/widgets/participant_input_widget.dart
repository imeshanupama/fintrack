import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ParticipantInputWidget extends StatefulWidget {
  final List<Map<String, dynamic>> participants;
  final ValueChanged<List<Map<String, dynamic>>> onParticipantsChanged;
  final bool allowCustomAmounts;
  final double? totalAmount;

  const ParticipantInputWidget({
    super.key,
    required this.participants,
    required this.onParticipantsChanged,
    this.allowCustomAmounts = false,
    this.totalAmount,
  });

  @override
  State<ParticipantInputWidget> createState() => _ParticipantInputWidgetState();
}

class _ParticipantInputWidgetState extends State<ParticipantInputWidget> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _addParticipant() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final amount = widget.allowCustomAmounts
        ? double.tryParse(_amountController.text) ?? 0.0
        : 0.0;

    final newParticipants = List<Map<String, dynamic>>.from(widget.participants)
      ..add({'name': name, 'amount': amount});

    widget.onParticipantsChanged(newParticipants);
    _nameController.clear();
    _amountController.clear();
  }

  void _removeParticipant(int index) {
    final newParticipants = List<Map<String, dynamic>>.from(widget.participants)
      ..removeAt(index);
    widget.onParticipantsChanged(newParticipants);
  }

  void _updateParticipantAmount(int index, double amount) {
    final newParticipants = List<Map<String, dynamic>>.from(widget.participants);
    newParticipants[index]['amount'] = amount;
    widget.onParticipantsChanged(newParticipants);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input Row
        Row(
          children: [
            Expanded(
              flex: widget.allowCustomAmounts ? 2 : 1,
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Person Name',
                  prefixIcon: Icon(Icons.person_add),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => widget.allowCustomAmounts ? null : _addParticipant(),
              ),
            ),
            if (widget.allowCustomAmounts) ...[
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addParticipant(),
                ),
              ),
            ],
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addParticipant,
              icon: const Icon(Icons.add_circle, size: 32),
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Participants List
        if (widget.participants.isNotEmpty) ...[
          Text('Participants (${widget.participants.length})',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...widget.participants.asMap().entries.map((entry) {
            final index = entry.key;
            final participant = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(participant['name'][0].toUpperCase()),
                ),
                title: Text(participant['name'], style: GoogleFonts.outfit()),
                subtitle: widget.allowCustomAmounts
                    ? Text('\$${participant['amount'].toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(color: Colors.grey))
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _removeParticipant(index),
                ),
              ),
            );
          }).toList(),
        ],
      ],
    );
  }
}
