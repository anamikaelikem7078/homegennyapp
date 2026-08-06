import '../../../../design_system/widgets/layout/ds_role_layout.dart';

export '../../../../design_system/widgets/layout/ds_role_layout.dart'
    show DsMenuTileStyle, DsPageScaffold, DsSectionHeader, DsKpiCard, DsHeroAvatar;

/// Staff detail page scaffold — delegates to [DsPageScaffold].
typedef StaffPageScaffold = DsPageScaffold;

/// Staff navigation tile.
class StaffMenuTile extends DsMenuTile {
  const StaffMenuTile({
    super.key,
    required super.icon,
    required super.title,
    super.subtitle,
    required super.onTap,
    super.trailing,
  }) : super(style: DsMenuTileStyle.plain);
}

/// Staff section header.
typedef StaffSectionHeader = DsSectionHeader;
