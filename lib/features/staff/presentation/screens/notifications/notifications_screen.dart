import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:go_router/go_router.dart';

import '../../../../../design_system/design_system.dart';
import '../../../../../core/presentation/widgets/paginated_list_view.dart';
import '../../navigation/staff_routes.dart';
import '../../../../../core/presentation/async_value_widget.dart';
import '../../../../../core/di/injection.dart';
import '../../providers/staff_providers.dart';

/// Staff notifications tab.
class StaffNotificationsScreen extends ConsumerWidget {
  const StaffNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(staffNotificationsProvider);

    return Scaffold(
      appBar: const DsAppBar(title: 'Notifications', subtitle: 'Stay updated'),
      body: AsyncValueWidget(
        value: notifications,
        onRetry: () => ref.invalidate(staffNotificationsProvider),
        builder: (list) {
          if (list.isEmpty) {
            return const DsEmptyState(
              title: 'No notifications',
              message: 'You are all caught up!',
              icon: Icons.notifications_none_rounded,
            );
          }
          return DsRefreshIndicator(
            onRefresh: () async => ref.invalidate(staffNotificationsProvider),
            child: PaginatedListView(
              items: list,
              hasMore: false,
              onLoadMore: () {},
              itemBuilder: (context, n, i) => DsNotificationCard(
                title: n.title,
                message: n.message,
                time: n.time,
                isRead: n.isRead,
                icon: _iconFor(n.type),
                onTap: () {
                  ref.read(staffRepositoryProvider).markNotificationRead(n.id);
                  ref.invalidate(staffNotificationsProvider);
                  _navigateForType(context, n.type);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _iconFor(String type) => switch (type) {
        'document' => Icons.folder_outlined,
        'training' => Icons.school_outlined,
        'salary' => Icons.payments_outlined,
        'agreement' => Icons.description_outlined,
        _ => Icons.notifications_outlined,
      };

  void _navigateForType(BuildContext context, String type) {
    switch (type) {
      case 'document':
        context.push(StaffRoutes.documents);
      case 'training':
        context.push(StaffRoutes.training);
      case 'salary':
        context.push(StaffRoutes.salary);
      case 'agreement':
        context.push(StaffRoutes.agreement);
    }
  }
}
