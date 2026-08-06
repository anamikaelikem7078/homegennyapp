import 'package:flutter/material.dart';

import '../../../../design_system/widgets/layout/ds_role_layout.dart';

export '../../../../design_system/widgets/layout/ds_role_layout.dart'
    show DsMenuTileStyle, DsPageScaffold, DsSectionHeader, DsKpiCard;

/// RM detail page scaffold.
typedef RmPageScaffold = DsPageScaffold;

/// RM navigation tile with gradient icon.
class RmMenuTile extends DsMenuTile {
  const RmMenuTile({
    super.key,
    required super.icon,
    required super.title,
    super.subtitle,
    required super.onTap,
    super.trailing,
    super.badge,
  }) : super(style: DsMenuTileStyle.gradient);
}

typedef RmSectionHeader = DsSectionHeader;

/// RM KPI card — delegates to shared [DsKpiCard].
typedef RmKpiCard = DsKpiCard;
