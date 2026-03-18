import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/card_highlight.dart';
import '../../../extensions.dart';
import '../../../i18n/generated/strings.g.dart';
import '../../../utils_gui.dart';
import 'auto_optimize_service.dart';
import 'utilities_service.dart';

class UtilitiesPage extends ConsumerWidget {
  const UtilitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hibernationStatus = ref.watch(hibernationStatusProvider);

    return ScaffoldPage.scrollable(
      padding: kScaffoldPagePadding,

      children: [
        const _HibernationCard(),
        if (hibernationStatus || kDebugMode) const _FastStartupCard(),
        const _ModernStandbyCard(),
        const _TMMonitoringCard(),
        const _QuickOptimizeCard(),
        const _TempFilesCard(),
        const _UsageReportingCard(),
      ].withSpacing(5),
    );
  }
}

class _HibernationCard extends ConsumerWidget {
  const _HibernationCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(hibernationStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.sleep_20_regular,
      label: t.tweaksUtilitiesHibernate,
      description: t.tweaksUtilitiesHibernateDescription,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref.read(utilitiesServiceProvider).enableHibernation()
              : await ref.read(utilitiesServiceProvider).disableHibernation();
          ref.invalidate(hibernationStatusProvider);
        },
      ),
    );
  }
}

class _FastStartupCard extends ConsumerWidget {
  const _FastStartupCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(fastStartupStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.flash_20_regular,
      label: t.tweaksUtilitiesFastStartup,
      description: t.tweaksUtilitiesFastStartupDescription,
      action: CardToggleSwitch(
        value: status,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? ref.read(utilitiesServiceProvider).enableFastStartup()
              : await ref.read(utilitiesServiceProvider).disableFastStartup();
          ref.invalidate(fastStartupStatusProvider);
        },
      ),
    );
  }
}

class _ModernStandbyCard extends ConsumerWidget {
  const _ModernStandbyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CardHighlight(
      icon: msicons.FluentIcons.power_20_regular,
      label: t.tweaksUtilitiesModernStandby,
      description: t.tweaksUtilitiesModernStandbyDescription,
      action: CardToggleSwitch(value: false, onChanged: (value) {}),
      children: [
        CardListTile(title: t.tweaksUtilitiesModernStandbyFullDescription),
      ],
    );
  }
}

class _TMMonitoringCard extends ConsumerWidget {
  const _TMMonitoringCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(tmMonitoringStatusProvider);

    return CardHighlight(
      icon: FluentIcons.task_manager,
      label: t.tweaksUtilitiesTMMonitoring,
      description: t.tweaksUtilitiesTMMonitoringDescription,
      action: CardToggleSwitch(
        value: status,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? await ref.read(utilitiesServiceProvider).enableTMMonitoring()
              : await ref.read(utilitiesServiceProvider).disableTMMonitoring();
          ref.invalidate(tmMonitoringStatusProvider);
        },
      ),
    );
  }
}


class _QuickOptimizeCard extends StatefulWidget {
  const _QuickOptimizeCard();

  @override
  State<_QuickOptimizeCard> createState() => _QuickOptimizeCardState();
}

class _QuickOptimizeCardState extends State<_QuickOptimizeCard> {
  final AutoOptimizeService _service = const AutoOptimizeService();
  OptimizationPreset _selectedPreset = OptimizationPreset.safe;
  late Future<OptimizationPreview> _previewFuture;
  OptimizationRunResult? _lastRun;
  bool _isRunning = false;

  bool get _isRussian => Localizations.localeOf(context).languageCode == 'ru';

  @override
  void initState() {
    super.initState();
    _previewFuture = _service.previewPreset(_selectedPreset);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OptimizationPreview>(
      future: _previewFuture,
      builder: (context, snapshot) {
        final OptimizationPreview? preview = snapshot.data;

        return CardHighlight(
          icon: msicons.FluentIcons.flash_20_regular,
          label: t.tweaksUtilitiesQuickOptimizeLabel,
          description: t.tweaksUtilitiesQuickOptimizeDescription,
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ComboBox<OptimizationPreset>(
                value: _selectedPreset,
                items: const [
                  ComboBoxItem(value: OptimizationPreset.safe, child: Text('Safe')),
                  ComboBoxItem(value: OptimizationPreset.max, child: Text('Max')),
                ],
                onChanged: _isRunning
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedPreset = value;
                          _previewFuture = _service.previewPreset(value);
                        });
                      },
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isRunning
                    ? null
                    : () async {
                        setState(() => _isRunning = true);
                        final result = await _service.applyPreset(_selectedPreset);
                        if (!mounted) return;
                        setState(() {
                          _lastRun = result;
                          _isRunning = false;
                          _previewFuture = _service.previewPreset(_selectedPreset);
                        });
                      },
                child: Text(_isRunning
                    ? (_isRussian ? 'Запуск...' : 'Running...')
                    : (_isRussian ? 'Применить' : 'Apply')),
              ),
            ],
          ),
          children: [
            CardListTile(
              title: _isRussian ? 'Профиль' : 'Preset',
              description: _selectedPreset == OptimizationPreset.safe
                  ? (_isRussian ? 'Безопасный' : 'Safe')
                  : (_isRussian ? 'Максимальный' : 'Max'),
            ),
            CardListTile(
              title: _isRussian ? 'Последний запуск' : 'Last run',
              description: _lastRun == null
                  ? (_isRussian ? 'Ещё не запускалось' : 'Not run yet')
                  : '${_lastRun!.successfulSteps}/${_lastRun!.steps.length} ${_isRussian ? 'шагов успешно' : 'steps succeeded'}',
            ),
            if (preview == null)
              CardListTile(
                title: _isRussian ? 'Предпросмотр' : 'Preview',
                description: _isRussian ? 'Сканирование...' : 'Scanning...',
              )
            else
              for (final item in preview.items)
                CardListTile(
                  title: item.label,
                  description: '${item.currentState} → ${item.targetState}. ${item.reason}${item.requiresRestart ? (_isRussian ? ' Требуется перезагрузка.' : ' Restart required.') : ''}',
                ),
            if (_lastRun != null)
              for (final step in _lastRun!.steps)
                CardListTile(
                  title: step.label,
                  description: step.success
                      ? (_isRussian ? 'Успешно' : 'Success')
                      : '${_isRussian ? 'Ошибка' : 'Failed'}: ${step.error}',
                ),
          ],
          initiallyExpanded: true,
        );
      },
    );
  }
}

class _TempFilesCard extends ConsumerStatefulWidget {
  const _TempFilesCard();

  @override
  ConsumerState<_TempFilesCard> createState() => _TempFilesCardState();
}

class _TempFilesCardState extends ConsumerState<_TempFilesCard> {
  late Future<TempCleanupReport> _reportFuture;
  bool _isCleaning = false;

  bool get _isRussian => Localizations.localeOf(context).languageCode == 'ru';

  @override
  void initState() {
    super.initState();
    _reportFuture = ref.read(utilitiesServiceProvider).scanTemporaryFiles();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TempCleanupReport>(
      future: _reportFuture,
      builder: (context, snapshot) {
        final TempCleanupReport? report = snapshot.data;

        return CardHighlight(
          icon: msicons.FluentIcons.delete_20_regular,
          label: _isRussian ? 'Очистка временных файлов' : 'Temporary files cleanup',
          description: _isRussian
              ? 'Сканирует временные папки и позволяет безопасно удалить накопившийся мусор.'
              : 'Scans temporary folders and lets you safely delete accumulated junk.',
          action: Button(
            onPressed: _isCleaning
                ? null
                : () async {
                    setState(() => _isCleaning = true);
                    final TempCleanupReport cleaned = await ref
                        .read(utilitiesServiceProvider)
                        .cleanupTemporaryFiles();
                    if (!mounted) return;
                    setState(() {
                      _reportFuture = Future<TempCleanupReport>.value(cleaned);
                      _isCleaning = false;
                    });
                  },
            child: Text(
              _isCleaning
                  ? (_isRussian ? 'Очистка...' : 'Cleaning...')
                  : (_isRussian ? 'Очистить' : 'Clean'),
            ),
          ),
          children: [
            CardListTile(
              title: _isRussian ? 'Найдено временных данных' : 'Detected temporary data',
              description: report == null
                  ? (_isRussian ? 'Сканирование...' : 'Scanning...')
                  : _formatBytes(report.totalBytes),
            ),
            CardListTile(
              title: _isRussian ? 'Найдено элементов' : 'Detected entries',
              description: report == null ? '—' : '${report.entries}',
            ),
            CardListTile(
              title: t.freedAfterCleanupLabel,
              description: report == null
                  ? '—'
                  : '${_formatBytes(report.cleanedBytes)} / ${report.cleanedEntries}',
            ),
            CardListTile(
              title: t.scannedFoldersLabel,
              description: report == null || report.scannedDirectories.isEmpty
                  ? '—'
                  : report.scannedDirectories.join('\n'),
            ),
          ],
          initiallyExpanded: true,
        );
      },
    );
  }

  String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    double value = bytes.toDouble();
    int index = 0;
    while (value >= 1024 && index < units.length - 1) {
      value /= 1024;
      index += 1;
    }
    return '${value.toStringAsFixed(index == 0 ? 0 : 1)} ${units[index]}';
  }
}

class _UsageReportingCard extends ConsumerWidget {
  const _UsageReportingCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(usageReportingStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.battery_checkmark_20_regular,
      label: t.tweaksUtilitiesUsageReporting,
      description: t.tweaksUtilitiesUsageReportingDescription,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref.read(utilitiesServiceProvider).enableUsageReporting()
              : await ref
                    .read(utilitiesServiceProvider)
                    .disableUsageReporting();
          ref.invalidate(usageReportingStatusProvider);
        },
      ),
    );
  }
}
