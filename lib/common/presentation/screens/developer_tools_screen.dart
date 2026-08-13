import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/data/seed_data_service.dart';
import '../../presentation/providers/auth_provider.dart';

class DeveloperToolsScreen extends ConsumerWidget {
  const DeveloperToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Tools'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final hiveService = ref.read(hiveServiceProvider);
                final seedDataService = SeedDataService(hiveService);
                await seedDataService.resetDemoData();
                ref.read(authProvider.notifier).logout();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demo Data Reset! Please login again.')),
                );
              },
              child: const Text('Reset Demo Data'),
            ),
          ],
        ),
      ),
    );
  }
}
