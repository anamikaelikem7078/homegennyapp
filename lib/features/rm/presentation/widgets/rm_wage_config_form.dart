import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';

/// Commercial Calculator-style wage-breakup form — same fields/defaults as
/// Finance's `WageConfigFormModal` (web), minus the unit-code/multi-resource
/// section which doesn't apply to a single staff placement. Debounces every
/// field change into a `POST /placements/calculate-wage` live preview, and
/// reports the current [WageConfig] up to the parent via [onConfigChanged]
/// on every change so the parent can send it as `wage_config` on submit.
class RmWageConfigForm extends ConsumerStatefulWidget {
  const RmWageConfigForm({super.key, required this.onConfigChanged});
  final ValueChanged<WageConfig> onConfigChanged;

  @override
  ConsumerState<RmWageConfigForm> createState() => _RmWageConfigFormState();
}

class _RmWageConfigFormState extends ConsumerState<RmWageConfigForm> {
  final _basicWage = TextEditingController();
  final _da = TextEditingController();
  final _hra = TextEditingController();
  final _skilledAllowance = TextEditingController();
  int _workingHours = 8;

  bool _pfApplicable = true;
  final _employerPfPct = TextEditingController(text: '13');
  final _employerPfMax = TextEditingController(text: '15000');
  final _employeePfPct = TextEditingController(text: '12');

  bool _esicApplicable = true;
  final _employerEsicPct = TextEditingController(text: '3.25');
  final _employeeEsicPct = TextEditingController(text: '0.75');

  bool _bonusApplicable = true;
  final _bonusPct = TextEditingController(text: '8.33');
  String _bonusFrequency = 'monthly';

  final _leaveDays = TextEditingController(text: '32');

  bool _lwfApplicable = true;
  final _lwfAmount = TextEditingController(text: '62');

  bool _uniformApplicable = true;
  final _uniformAllowance = TextEditingController(text: '275');

  bool _relievingApplicable = true;
  final _relievingPct = TextEditingController(text: '16.67');

  final _managementPct = TextEditingController();
  final _professionalTax = TextEditingController(text: '0');

  bool _gstApplicable = true;
  // Must match wage-calculator.util.ts's gst_type enum exactly ('intra'/'inter' was
  // silently ignored server-side, always falling back to intra_state).
  String _gstType = 'intra_state';
  final _gstPct = TextEditingController(text: '18');

  Timer? _debounce;
  WageBreakup? _preview;
  bool _previewLoading = false;
  String? _previewError;

  List<TextEditingController> get _numericControllers => [
        _basicWage,
        _da,
        _hra,
        _skilledAllowance,
        _employerPfPct,
        _employerPfMax,
        _employeePfPct,
        _employerEsicPct,
        _employeeEsicPct,
        _bonusPct,
        _leaveDays,
        _lwfAmount,
        _uniformAllowance,
        _relievingPct,
        _managementPct,
        _professionalTax,
        _gstPct,
      ];

  @override
  void initState() {
    super.initState();
    for (final c in _numericControllers) {
      c.addListener(_onFieldChanged);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onConfigChanged(_config));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in _numericControllers) {
      c.dispose();
    }
    super.dispose();
  }

  num _num(TextEditingController c, [num fallback = 0]) => num.tryParse(c.text.trim()) ?? fallback;

  WageConfig get _config => WageConfig(
        basicWage: _num(_basicWage),
        da: _num(_da),
        hra: _num(_hra),
        skilledAllowance: _num(_skilledAllowance),
        workingHours: _workingHours,
        pfApplicable: _pfApplicable,
        employerPfPct: _num(_employerPfPct, 13),
        employerPfMax: _num(_employerPfMax, 15000),
        employeePfPct: _num(_employeePfPct, 12),
        esicApplicable: _esicApplicable,
        employerEsicPct: _num(_employerEsicPct, 3.25),
        employeeEsicPct: _num(_employeeEsicPct, 0.75),
        bonusApplicable: _bonusApplicable,
        bonusPct: _num(_bonusPct, 8.33),
        bonusFrequency: _bonusFrequency,
        leaveDays: _num(_leaveDays, 32),
        lwfApplicable: _lwfApplicable,
        lwfAmount: _num(_lwfAmount, 62),
        uniformApplicable: _uniformApplicable,
        uniformAllowance: _num(_uniformAllowance, 275),
        relievingApplicable: _relievingApplicable,
        relievingPct: _num(_relievingPct, 16.67),
        managementPct: _num(_managementPct),
        professionalTax: _num(_professionalTax),
        gstApplicable: _gstApplicable,
        gstType: _gstType,
        gstPct: _num(_gstPct, 18),
      );

  void _onFieldChanged() {
    widget.onConfigChanged(_config);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _fetchPreview);
  }

  Future<void> _fetchPreview() async {
    final config = _config;
    if (config.basicWage <= 0 || config.managementPct <= 0) {
      setState(() {
        _preview = null;
        _previewError = null;
        _previewLoading = false;
      });
      return;
    }
    setState(() => _previewLoading = true);
    final result = await ref.read(rmRepositoryProvider).calculateWage(config.toJson());
    if (!mounted) return;
    setState(() {
      _previewLoading = false;
      result.fold(
        onSuccess: (b) {
          _preview = b;
          _previewError = null;
        },
        onError: (f) => _previewError = f.message,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Earnings', [
          _numField(_basicWage, 'Basic Wage (monthly) *'),
          const SizedBox(height: 12),
          _numField(_da, 'DA'),
          const SizedBox(height: 12),
          _numField(_hra, 'HRA'),
          const SizedBox(height: 12),
          _numField(_skilledAllowance, 'Skilled Allowance'),
          const SizedBox(height: 12),
          Text('Working Hours', style: RmTheme.body(context).copyWith(fontSize: 12)),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 8, label: Text('8 hrs')),
              ButtonSegment(value: 12, label: Text('12 hrs')),
            ],
            selected: {_workingHours},
            onSelectionChanged: (s) {
              setState(() => _workingHours = s.first);
              _onFieldChanged();
            },
          ),
        ]),
        _section('Provident Fund (PF)', [
          _toggleField('PF Applicable', _pfApplicable, (v) {
            setState(() => _pfApplicable = v);
            _onFieldChanged();
          }),
          if (_pfApplicable) ...[
            const SizedBox(height: 12),
            _numField(_employerPfPct, 'Employer PF %'),
            const SizedBox(height: 12),
            _numField(_employerPfMax, 'PF Ceiling (₹)'),
            const SizedBox(height: 12),
            _numField(_employeePfPct, 'Employee PF %'),
          ],
        ]),
        _section('ESIC', [
          _toggleField('ESIC Applicable', _esicApplicable, (v) {
            setState(() => _esicApplicable = v);
            _onFieldChanged();
          }),
          if (_esicApplicable) ...[
            const SizedBox(height: 12),
            _numField(_employerEsicPct, 'Employer ESIC %'),
            const SizedBox(height: 12),
            _numField(_employeeEsicPct, 'Employee ESIC %'),
          ],
        ]),
        _section('Bonus', [
          _toggleField('Bonus Applicable', _bonusApplicable, (v) {
            setState(() => _bonusApplicable = v);
            _onFieldChanged();
          }),
          if (_bonusApplicable) ...[
            const SizedBox(height: 12),
            _numField(_bonusPct, 'Bonus %'),
            const SizedBox(height: 12),
            Text('Bonus Frequency', style: RmTheme.body(context).copyWith(fontSize: 12)),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'monthly', label: Text('Monthly')),
                ButtonSegment(value: 'yearly', label: Text('Annual')),
              ],
              selected: {_bonusFrequency},
              onSelectionChanged: (s) {
                setState(() => _bonusFrequency = s.first);
                _onFieldChanged();
              },
            ),
          ],
        ]),
        _section('Leave & Allowances', [
          _numField(_leaveDays, 'Leave Days (per year)'),
          const SizedBox(height: 16),
          _toggleField('LWF Applicable', _lwfApplicable, (v) {
            setState(() => _lwfApplicable = v);
            _onFieldChanged();
          }),
          if (_lwfApplicable) ...[
            const SizedBox(height: 12),
            _numField(_lwfAmount, 'LWF Amount (₹)'),
          ],
          const SizedBox(height: 16),
          _toggleField('Uniform Applicable', _uniformApplicable, (v) {
            setState(() => _uniformApplicable = v);
            _onFieldChanged();
          }),
          if (_uniformApplicable) ...[
            const SizedBox(height: 12),
            _numField(_uniformAllowance, 'Uniform Allowance (₹)'),
          ],
          const SizedBox(height: 16),
          _toggleField('Relieving Applicable', _relievingApplicable, (v) {
            setState(() => _relievingApplicable = v);
            _onFieldChanged();
          }),
          if (_relievingApplicable) ...[
            const SizedBox(height: 12),
            _numField(_relievingPct, 'Relieving %'),
          ],
        ]),
        _section('Management Fee & Tax', [
          _numField(_managementPct, 'Management Fee % *'),
          const SizedBox(height: 12),
          _numField(_professionalTax, 'Professional Tax (₹)'),
        ]),
        _section('GST', [
          _toggleField('GST Applicable', _gstApplicable, (v) {
            setState(() => _gstApplicable = v);
            _onFieldChanged();
          }),
          if (_gstApplicable) ...[
            const SizedBox(height: 12),
            Text('GST Type', style: RmTheme.body(context).copyWith(fontSize: 12)),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'intra_state', label: Text('Intra-state')),
                ButtonSegment(value: 'inter_state', label: Text('Inter-state')),
              ],
              selected: {_gstType},
              onSelectionChanged: (s) {
                setState(() => _gstType = s.first);
                _onFieldChanged();
              },
            ),
            const SizedBox(height: 12),
            _numField(_gstPct, 'GST %'),
          ],
        ]),
        _buildPreviewCard(context),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RmTheme.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RmTheme.borderSubtle.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: RmTheme.headline(context).copyWith(fontSize: 15)),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _numField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
    );
  }

  Widget _toggleField(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: RmTheme.body(context).copyWith(fontSize: 13.5))),
        Switch(value: value, onChanged: onChanged, activeThumbColor: RmTheme.electricBlue),
      ],
    );
  }

  Widget _buildPreviewCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RmTheme.electricBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RmTheme.electricBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Live Preview', style: RmTheme.headline(context).copyWith(fontSize: 15)),
              const SizedBox(width: 10),
              if (_previewLoading) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 12),
          if (_previewError != null)
            Text(_previewError!, style: RmTheme.body(context).copyWith(fontSize: 12, color: RmTheme.crimsonDanger))
          else if (_preview == null)
            Text('Fill Basic Wage and Management Fee % to see a live preview.', style: RmTheme.body(context).copyWith(fontSize: 12.5))
          else ...[
            _previewRow(context, 'Staff Take-Home', _preview!.netSalary),
            _previewRow(context, 'Management Fee', _preview!.managementFee),
            if (_preview!.ctc != null) _previewRow(context, 'CTC', _preview!.ctc!),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
            Text('Components — verify before submitting', style: RmTheme.body(context).copyWith(fontSize: 11.5, fontWeight: FontWeight.w600, color: RmTheme.textSecondary)),
            const SizedBox(height: 8),
            if (_preview!.employerPfAmount != null) _previewRow(context, 'PF (Employer)', _preview!.employerPfAmount!),
            if (_preview!.employeePfAmount != null) _previewRow(context, 'PF (Employee)', _preview!.employeePfAmount!),
            if (_preview!.employerEsicAmount != null) _previewRow(context, 'ESIC (Employer)', _preview!.employerEsicAmount!),
            if (_preview!.employeeEsicAmount != null) _previewRow(context, 'ESIC (Employee)', _preview!.employeeEsicAmount!),
            if (_preview!.bonusAmount != null) _previewRow(context, 'Bonus (monthly)', _preview!.bonusAmount!),
            if (_preview!.gstAmount != null) _previewRow(context, 'GST (${_gstType == 'inter_state' ? 'IGST' : 'CGST+SGST'})', _preview!.gstAmount!),
            if (_preview!.grossSalary != null) _previewRow(context, 'Gross Earnings', _preview!.grossSalary!),
          ],
        ],
      ),
    );
  }

  Widget _previewRow(BuildContext context, String label, num value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: RmTheme.body(context).copyWith(fontSize: 13)),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: RmTheme.body(context).copyWith(fontSize: 13, fontWeight: FontWeight.bold, color: RmTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}
