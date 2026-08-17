import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';

/// Client picker for the S4 Agreements stage — `GET /finance/customers`.
/// Agreements (A1/A2/A3) all require a `client_id`, so this is selected
/// once per staff and carried into each instrument screen. Returns the
/// selected [FinanceCustomer] via `Navigator.pop`.
class RmStage4A2ClientScreen extends ConsumerStatefulWidget {
  const RmStage4A2ClientScreen({super.key, required this.staffId});
  final String staffId;

  @override
  ConsumerState<RmStage4A2ClientScreen> createState() => _RmStage4A2ClientScreenState();
}

class _RmStage4A2ClientScreenState extends ConsumerState<RmStage4A2ClientScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(financeCustomersProvider(_search.isEmpty ? null : _search));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(backgroundColor: RmTheme.offWhite, elevation: 0, title: const Text('Select Client')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search clients',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: RmTheme.cardSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: AsyncValueWidget<List<FinanceCustomer>>(
              value: customersAsync,
              onRetry: () => ref.invalidate(financeCustomersProvider(_search.isEmpty ? null : _search)),
              builder: (customers) {
                if (customers.isEmpty) return const Center(child: Text('No clients found.'));
                return ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final c = customers[index];
                    return ListTile(
                      title: Text(c.customerName),
                      subtitle: Text([c.city, c.unitCode].where((e) => e != null && e.isNotEmpty).join(' · ')),
                      onTap: () => context.pop(c),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
