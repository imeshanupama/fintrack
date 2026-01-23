import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../domain/bill_split.dart';
import 'bill_split_provider.dart';

class BillSplitsListScreen extends ConsumerStatefulWidget {
  const BillSplitsListScreen({super.key});

  @override
  ConsumerState<BillSplitsListScreen> createState() => _BillSplitsListScreenState();
}

class _BillSplitsListScreenState extends ConsumerState<BillSplitsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billSplitsAsync = ref.watch(billSplitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Splits'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Settled', icon: Icon(Icons.check_circle)),
            Tab(text: 'All', icon: Icon(Icons.list)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by person name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Content
          Expanded(
            child: billSplitsAsync.when(
              data: (allSplits) {
                // Filter by search
                var filteredSplits = _searchQuery.isEmpty
                    ? allSplits
                    : allSplits.where((split) => split.participants.any((p) =>
                        p.name.toLowerCase().contains(_searchQuery.toLowerCase()))).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSplitsList(filteredSplits.where((s) => !s.isFullySettled).toList()),
                    _buildSplitsList(filteredSplits.where((s) => s.isFullySettled).toList()),
                    _buildSplitsList(filteredSplits),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/bill-split'),
        icon: const Icon(Icons.add),
        label: const Text('New Split'),
      ),
    );
  }

  Widget _buildSplitsList(List<BillSplit> splits) {
    if (splits.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.receipt_long_outlined,
        title: 'No Bill Splits',
        description: 'Split bills with friends and keep track of who owes what.',
        actionLabel: 'Create Split',
        onActionPressed: () => context.push('/bill-split'),
        color: Colors.purple.shade600,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: splits.length,
      itemBuilder: (context, index) {
        final split = splits[index];
        return _buildSplitCard(split);
      },
    );
  }

  Widget _buildSplitCard(BillSplit split) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: split.isFullySettled ? Colors.green : Colors.orange,
          child: Icon(
            split.isFullySettled ? Icons.check : Icons.pending,
            color: Colors.white,
          ),
        ),
        title: Text(split.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${split.currencyCode} ${split.totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(color: Colors.grey)),
            Text('${dateFormat.format(split.date)} • ${split.participants.length} people',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
            if (!split.isFullySettled)
              Text('Pending: ${split.currencyCode} ${split.pendingAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${split.paidCount}/${split.totalParticipants}',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            Text('paid', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey)),
          ],
        ),
        onTap: () => context.push('/bill-split-detail', extra: split),
      ),
    );
  }
}
