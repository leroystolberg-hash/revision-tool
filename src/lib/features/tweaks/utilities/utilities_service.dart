import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:win32_registry/win32_registry.dart';

import '../../../core/services/win_registry_service.dart';
import '../../../core/trusted_installer/trusted_installer_service.dart';
import '../../../utils.dart';

part 'utilities_service.g.dart';

class TempCleanupReport {
  const TempCleanupReport({
    required this.totalBytes,
    required this.entries,
    required this.cleanedBytes,
    required this.cleanedEntries,
    required this.scannedDirectories,
  });

  final int totalBytes;
  final int entries;
  final int cleanedBytes;
  final int cleanedEntries;
  final List<String> scannedDirectories;

  TempCleanupReport copyWith({
    int? totalBytes,
    int? entries,
    int? cleanedBytes,
    int? cleanedEntries,
    List<String>? scannedDirectories,
  }) {
    return TempCleanupReport(
      totalBytes: totalBytes ?? this.totalBytes,
      entries: entries ?? this.entries,
      cleanedBytes: cleanedBytes ?? this.cleanedBytes,
      cleanedEntries: cleanedEntries ?? this.cleanedEntries,
      scannedDirectories: scannedDirectories ?? this.scannedDirectories,
    );
  }
}

abstract class UtilitiesService {
  bool get statusHibernation;
  Future<void> enableHibernation();
  Future<void> disableHibernation();
  bool get statusFastStartup;
  Future<void> enableFastStartup();
  Future<void> disableFastStartup();
  bool get statusModernStandby;
  Future<void> enableModernStandby();
  Future<void> disableModernStandby();

  bool get statusTMMonitoring;
  Future<void> enableTMMonitoring();
  Future<void> disableTMMonitoring();

  bool get statusUsageReporting;
  Future<void> enableUsageReporting();
  Future<void> disableUsageReporting();

  Future<TempCleanupReport> scanTemporaryFiles();
  Future<TempCleanupReport> cleanupTemporaryFiles();
}

class UtilitiesServiceImpl implements UtilitiesService {
  const UtilitiesServiceImpl();

  @override
  bool get statusHibernation {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SYSTEM\ControlSet001\Control\Power',
          'HibernateEnabled',
        ) ==
        1;
  }

  @override
  Future<void> enableHibernation() async {
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\System',
        'ShowHibernateOption',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Power',
        'HibernateEnabled',
        1,
      ),
      shell.run(r'''
                       powercfg -h on
                       powercfg /h /type full
                      '''),
    ]);
  }

  @override
  Future<void> disableHibernation() async {
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\System',
        'ShowHibernateOption',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Power',
        'HibernateEnabled',
        0,
      ),
      shell.run(r'''
powercfg -h off
'''),
    ]);
  }

  @override
  bool get statusFastStartup {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'System\ControlSet001\Control\Session Manager\Power',
          'HiberbootEnabled',
        ) ==
        1;
  }

  @override
  Future<void> enableFastStartup() async {
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'System\ControlSet001\Control\Session Manager\Power',
        'HiberbootEnabled',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\System',
        'HiberbootEnabled',
        1,
      ),
    ]);
  }

  @override
  Future<void> disableFastStartup() async {
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'System\ControlSet001\Control\Session Manager\Power',
        'HiberbootEnabled',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\System',
        'HiberbootEnabled',
        0,
      ),
    ]);
  }

  @override
  bool get statusModernStandby {
    return WinRegistryService.readInt(
          .localMachine,
          r'System\CurrentControlSet\Control\Power',
          'PlatformAoAcOverride',
        ) !=
        0;
  }

  @override
  Future<void> enableModernStandby() {
    return WinRegistryService.deleteValue(
      Registry.localMachine,
      r'System\CurrentControlSet\Control\Power',
      'PlatformAoAcOverride',
    );
  }

  @override
  Future<void> disableModernStandby() {
    return WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'System\CurrentControlSet\Control\Power',
      'PlatformAoAcOverride',
      0,
    );
  }

  @override
  bool get statusTMMonitoring {
    return WinRegistryService.readInt(
              RegistryHive.localMachine,
              r'SYSTEM\ControlSet001\Services\GraphicsPerfSvc',
              'Start',
            ) ==
            2 &&
        WinRegistryService.readInt(
              RegistryHive.localMachine,
              r'SYSTEM\ControlSet001\Services\Ndu',
              'Start',
            ) ==
            2;
  }

  @override
  Future<void> enableTMMonitoring() async {
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\GraphicsPerfSvc',
        'Start',
        2,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\Ndu',
        'Start',
        2,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\DPS',
        'Start',
        2,
      ),
    ]);
  }

  @override
  Future<void> disableTMMonitoring() async {
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\GraphicsPerfSvc',
        'Start',
        4,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\Ndu',
        'Start',
        4,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\DPS',
        'Start',
        4,
      ),
    ]);
  }

  @override
  bool get statusUsageReporting {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SYSTEM\ControlSet001\Services\DPS',
          'Start',
        ) !=
        4;
  }

  @override
  Future<void> enableUsageReporting() async {
    await Future.wait([
      TrustedInstallerServiceImpl().executeCommand('wevtutil', [
        'sl',
        'Microsoft-Windows-SleepStudy/Diagnostic',
        '/q:true',
      ]),
      TrustedInstallerServiceImpl().executeCommand('wevtutil', [
        'sl',
        'Microsoft-Windows-Kernel-Processor-Power/Diagnostic',
        '/q:true',
      ]),
      TrustedInstallerServiceImpl().executeCommand('wevtutil', [
        'sl',
        'Microsoft-Windows-UserModePowerService/Diagnostic',
        '/q:true',
      ]),
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Session Manager\Power',
        'SleepStudyDisabled',
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\DPS',
        'Start',
        2,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\diagsvc',
        'Start',
        2,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\WdiServiceHost',
        'Start',
        2,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\WdiSystemHost',
        'Start',
        2,
      ),
    ]);
  }

  @override
  Future<void> disableUsageReporting() async {
    await Future.wait([
      TrustedInstallerServiceImpl().executeCommand('wevtutil', [
        'sl',
        'Microsoft-Windows-SleepStudy/Diagnostic',
        '/q:false',
      ]),
      TrustedInstallerServiceImpl().executeCommand('wevtutil', [
        'sl',
        'Microsoft-Windows-Kernel-Processor-Power/Diagnostic',
        '/q:false',
      ]),
      TrustedInstallerServiceImpl().executeCommand('wevtutil', [
        'sl',
        'Microsoft-Windows-UserModePowerService/Diagnostic',
        '/q:false',
      ]),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Session Manager\Power',
        'SleepStudyDisabled',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\DPS',
        'Start',
        4,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\diagsvc',
        'Start',
        4,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\WdiServiceHost',
        'Start',
        4,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\WdiSystemHost',
        'Start',
        4,
      ),
    ]);
  }

  @override
  Future<TempCleanupReport> scanTemporaryFiles() async {
    final List<String> targets = _existingTempTargets();
    int totalBytes = 0;
    int entries = 0;

    for (final target in targets) {
      final Directory root = Directory(target);
      if (!root.existsSync()) continue;

      final List<FileSystemEntity> children = _listChildren(root);
      for (final entity in children) {
        entries += 1;
        totalBytes += _measureEntity(entity);
      }
    }

    return TempCleanupReport(
      totalBytes: totalBytes,
      entries: entries,
      cleanedBytes: 0,
      cleanedEntries: 0,
      scannedDirectories: targets,
    );
  }

  @override
  Future<TempCleanupReport> cleanupTemporaryFiles() async {
    final TempCleanupReport scan = await scanTemporaryFiles();
    int cleanedBytes = 0;
    int cleanedEntries = 0;

    for (final target in scan.scannedDirectories) {
      final Directory root = Directory(target);
      if (!root.existsSync()) continue;

      for (final entity in _listChildren(root)) {
        final int entityBytes = _measureEntity(entity);
        if (_deleteEntity(entity)) {
          cleanedEntries += 1;
          cleanedBytes += entityBytes;
        }
      }
    }

    return scan.copyWith(
      cleanedBytes: cleanedBytes,
      cleanedEntries: cleanedEntries,
      totalBytes: (scan.totalBytes - cleanedBytes).clamp(0, scan.totalBytes),
      entries: (scan.entries - cleanedEntries).clamp(0, scan.entries),
    );
  }

  List<String> _existingTempTargets() {
    final Set<String> candidates = {
      Directory.systemTemp.path,
      Platform.environment['TEMP'] ?? '',
      Platform.environment['TMP'] ?? '',
      r'C:\Windows\Temp',
      tempReviPath,
    };

    return candidates
        .where((path) => path.isNotEmpty && Directory(path).existsSync())
        .toList(growable: false);
  }

  List<FileSystemEntity> _listChildren(Directory root) {
    try {
      return root.listSync(followLinks: false).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  int _measureEntity(FileSystemEntity entity) {
    try {
      if (entity is File) {
        return entity.lengthSync();
      }
      if (entity is Directory) {
        int total = 0;
        for (final child in entity.listSync(recursive: true, followLinks: false)) {
          if (child is File) {
            total += child.lengthSync();
          }
        }
        return total;
      }
    } catch (_) {
      return 0;
    }
    return 0;
  }

  bool _deleteEntity(FileSystemEntity entity) {
    try {
      if (entity is Directory) {
        entity.deleteSync(recursive: true);
        return true;
      }
      entity.deleteSync();
      return true;
    } catch (_) {
      return false;
    }
  }
}

@Riverpod(keepAlive: true)
UtilitiesService utilitiesService(Ref ref) {
  return const UtilitiesServiceImpl();
}

@riverpod
bool hibernationStatus(Ref ref) {
  return ref.watch(utilitiesServiceProvider).statusHibernation;
}

@riverpod
bool fastStartupStatus(Ref ref) {
  return ref.watch(utilitiesServiceProvider).statusFastStartup;
}

@riverpod
bool tmMonitoringStatus(Ref ref) {
  return ref.watch(utilitiesServiceProvider).statusTMMonitoring;
}

@riverpod
bool usageReportingStatus(Ref ref) {
  return ref.watch(utilitiesServiceProvider).statusUsageReporting;
}
