import '../performance/performance_service.dart';
import '../updates/updates_service.dart';
import 'utilities_service.dart';

enum OptimizationPreset { safe, max }

class OptimizationPreviewItem {
  const OptimizationPreviewItem({
    required this.label,
    required this.currentState,
    required this.targetState,
    required this.reason,
    this.requiresRestart = false,
  });

  final String label;
  final String currentState;
  final String targetState;
  final String reason;
  final bool requiresRestart;
}

class OptimizationPreview {
  const OptimizationPreview({
    required this.preset,
    required this.items,
  });

  final OptimizationPreset preset;
  final List<OptimizationPreviewItem> items;
}

class OptimizationStepResult {
  const OptimizationStepResult({
    required this.label,
    required this.success,
    this.error,
  });

  final String label;
  final bool success;
  final String? error;
}

class OptimizationRunResult {
  const OptimizationRunResult({
    required this.preset,
    required this.steps,
  });

  final OptimizationPreset preset;
  final List<OptimizationStepResult> steps;

  int get successfulSteps => steps.where((step) => step.success).length;
  int get failedSteps => steps.where((step) => !step.success).length;
}

class AutoOptimizeService {
  const AutoOptimizeService({
    PerformanceService performanceService = const PerformanceServiceImpl(),
    UtilitiesService utilitiesService = const UtilitiesServiceImpl(),
    UpdatesService updatesService = const UpdatesServiceImpl(),
  }) : _performanceService = performanceService,
       _utilitiesService = utilitiesService,
       _updatesService = updatesService;

  final PerformanceService _performanceService;
  final UtilitiesService _utilitiesService;
  final UpdatesService _updatesService;

  Future<OptimizationPreview> previewPreset(OptimizationPreset preset) async {
    final TempCleanupReport tempReport = await _utilitiesService.scanTemporaryFiles();
    final List<OptimizationPreviewItem> items = [
      OptimizationPreviewItem(
        label: 'Revision power plan',
        currentState: _performanceService.statusReviPowerPlan ? 'Enabled' : 'Disabled',
        targetState: 'Enabled',
        reason: 'Switches the machine to the project\'s high-performance power profile.',
      ),
      OptimizationPreviewItem(
        label: 'Fullscreen optimizations',
        currentState: _performanceService.statusFullscreenOptimization ? 'Enabled' : 'Disabled',
        targetState: 'Enabled',
        reason: 'Improves game/app presentation path in fullscreen mode.',
      ),
      OptimizationPreviewItem(
        label: 'Windowed game optimizations',
        currentState: _performanceService.statusWindowedOptimization ? 'Enabled' : 'Disabled',
        targetState: 'Enabled',
        reason: 'Uses the newer presentation path for borderless/windowed games.',
      ),
      OptimizationPreviewItem(
        label: 'MPO',
        currentState: _performanceService.statusMPO ? 'Enabled' : 'Disabled',
        targetState: 'Enabled',
        reason: 'Keeps low-latency multiplane overlay enabled for modern GPUs.',
      ),
      OptimizationPreviewItem(
        label: 'Fast Startup',
        currentState: _utilitiesService.statusFastStartup ? 'Enabled' : 'Disabled',
        targetState: 'Disabled',
        reason: 'Prevents hybrid boot side effects and keeps optimization behavior predictable.',
        requiresRestart: true,
      ),
      OptimizationPreviewItem(
        label: 'Usage reporting',
        currentState: _utilitiesService.statusUsageReporting ? 'Enabled' : 'Disabled',
        targetState: 'Disabled',
        reason: 'Reduces telemetry and diagnostic overhead.',
      ),
      OptimizationPreviewItem(
        label: 'Temporary files',
        currentState: '${tempReport.entries} items / ${_formatBytes(tempReport.totalBytes)}',
        targetState: 'Clean removable junk',
        reason: 'Removes reclaimable temporary files from detected temp locations.',
      ),
    ];

    if (preset == OptimizationPreset.max) {
      items.addAll([
        OptimizationPreviewItem(
          label: 'Background apps',
          currentState: _performanceService.statusBackgroundApps ? 'Enabled' : 'Disabled',
          targetState: 'Disabled',
          reason: 'Cuts background activity to prioritize foreground performance.',
        ),
        OptimizationPreviewItem(
          label: 'Memory compression',
          currentState: _performanceService.statusMemoryCompression ? 'Enabled' : 'Disabled',
          targetState: 'Disabled',
          reason: 'Prefers raw responsiveness over background memory savings.',
        ),
        OptimizationPreviewItem(
          label: 'NTFS Last Access',
          currentState: _performanceService.statusLastTimeAccessNTFS ? 'Enabled' : 'Disabled',
          targetState: 'Disabled',
          reason: 'Reduces extra file metadata writes.',
        ),
        OptimizationPreviewItem(
          label: 'NTFS 8.3 names',
          currentState: _performanceService.status8dot3NamingNTFS ? 'Enabled' : 'Disabled',
          targetState: 'Disabled',
          reason: 'Removes legacy naming overhead where not needed.',
        ),
        OptimizationPreviewItem(
          label: 'Task Manager monitoring services',
          currentState: _utilitiesService.statusTMMonitoring ? 'Enabled' : 'Disabled',
          targetState: 'Disabled',
          reason: 'Cuts extra monitoring services for a leaner system.',
          requiresRestart: true,
        ),
        OptimizationPreviewItem(
          label: 'Drivers via Windows Update',
          currentState: _updatesService.statusDriversWU ? 'Enabled' : 'Disabled',
          targetState: 'Enabled',
          reason: 'Keeps a recovery path for difficult or missing drivers.',
        ),
      ]);
    }

    return OptimizationPreview(preset: preset, items: items);
  }

  Future<OptimizationRunResult> applyPreset(OptimizationPreset preset) async {
    final List<OptimizationStepResult> results = [];

    Future<void> runStep(String label, Future<void> Function() action) async {
      try {
        await action();
        results.add(OptimizationStepResult(label: label, success: true));
      } catch (error) {
        results.add(
          OptimizationStepResult(
            label: label,
            success: false,
            error: error.toString(),
          ),
        );
      }
    }

    await runStep('Enable Revision power plan', () {
      return _performanceService.enableReviPowerPlan();
    });
    await runStep('Enable fullscreen optimizations', () {
      return _performanceService.enableFullscreenOptimization();
    });
    await runStep('Enable windowed game optimizations', () {
      return _performanceService.enableWindowedOptimization();
    });
    await runStep('Enable MPO', () {
      return _performanceService.enableMPO();
    });
    await runStep('Disable Fast Startup', () {
      return _utilitiesService.disableFastStartup();
    });
    await runStep('Disable usage reporting', () {
      return _utilitiesService.disableUsageReporting();
    });
    await runStep('Clean temporary files', () async {
      await _utilitiesService.cleanupTemporaryFiles();
    });

    if (preset == OptimizationPreset.max) {
      await runStep('Disable background apps', () {
        return _performanceService.disableBackgroundApps();
      });
      await runStep('Disable memory compression', () {
        return _performanceService.disableMemoryCompression();
      });
      await runStep('Disable NTFS last access', () {
        return _performanceService.disableLastTimeAccessNTFS();
      });
      await runStep('Disable NTFS 8.3 naming', () {
        return _performanceService.disable8dot3NamingNTFS();
      });
      await runStep('Apply recommended service grouping', () {
        return _performanceService.recommendedServicesGrouping();
      });
      await runStep('Disable Task Manager monitoring services', () {
        return _utilitiesService.disableTMMonitoring();
      });
      await runStep('Enable drivers via Windows Update', () {
        return _updatesService.enableDriversWU();
      });
    }

    return OptimizationRunResult(preset: preset, steps: results);
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
