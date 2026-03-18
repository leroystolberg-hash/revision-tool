import '../updates/updates_service.dart';
import '../utilities/utilities_service.dart';
import 'system_audit_models.dart';

class SystemAuditService {
  const SystemAuditService({
    UtilitiesService utilitiesService = const UtilitiesServiceImpl(),
    UpdatesService updatesService = const UpdatesServiceImpl(),
  }) : _utilitiesService = utilitiesService,
       _updatesService = updatesService;

  final UtilitiesService _utilitiesService;
  final UpdatesService _updatesService;

  List<AuditFinding> scan({
    required String languageCode,
    DateTime? now,
  }) {
    final bool isRussian = languageCode.toLowerCase().startsWith('ru');
    final DateTime scannedAt = now ?? DateTime.now();

    return [
      AuditFinding(
        id: 'fast-startup',
        title: isRussian ? 'Быстрый запуск' : 'Fast Startup',
        summary: isRussian
            ? 'Системная функция, которую лучше сначала отключить, а удалять только после периода наблюдения.'
            : 'A core Windows feature that should be disabled first and only removed after an observation period.',
        category: AuditCategory.registry,
        currentState: _utilitiesService.statusFastStartup
            ? (isRussian ? 'Включено' : 'Enabled')
            : (isRussian ? 'Выключено' : 'Disabled'),
        proposedState: _utilitiesService.statusFastStartup
            ? (isRussian ? 'Отключить' : 'Disable')
            : (isRussian ? 'Оставить выключенным' : 'Keep disabled'),
        reason: isRussian
            ? 'На ReviOS быстрый запуск часто мешает чистой диагностике, dual-boot и предсказуемому применению оптимизаций.'
            : 'On ReviOS, Fast Startup often gets in the way of clean diagnostics, dual-boot setups, and predictable optimization flows.',
        effect: isRussian
            ? 'Система будет стартовать чуть медленнее, но поведение станет стабильнее и понятнее. Если спустя 72 часа проблем не возникнет, можно думать об удалении связанного мусора.'
            : 'Boot may be a bit slower, but behavior becomes more predictable. If nothing regresses after 72 hours, related leftovers can be considered for removal.',
        impact: AuditImpact.medium,
        isCritical: true,
        requiresRestart: true,
        removalPolicy: RemovalPolicy.delayed72Hours,
        scannedAt: scannedAt,
      ),
      AuditFinding(
        id: 'usage-reporting',
        title: isRussian ? 'Отчёт об использовании' : 'Usage Reporting',
        summary: isRussian
            ? 'Фоновые диагностические службы и телеметрия, которые можно отключить без удаления.'
            : 'Background diagnostics and telemetry that can usually be disabled without immediate removal.',
        category: AuditCategory.service,
        currentState: _utilitiesService.statusUsageReporting
            ? (isRussian ? 'Включено' : 'Enabled')
            : (isRussian ? 'Выключено' : 'Disabled'),
        proposedState: _utilitiesService.statusUsageReporting
            ? (isRussian ? 'Отключить' : 'Disable')
            : (isRussian ? 'Ничего не менять' : 'Leave as is'),
        reason: isRussian
            ? 'Этот блок грузит систему диагностикой и сбором использования, а в игровом или минимальном профиле редко даёт пользу.'
            : 'This block adds diagnostic overhead and usage collection, which rarely helps on gaming or minimal profiles.',
        effect: isRussian
            ? 'Меньше фоновой нагрузки и диагностического шума. Если после отключения всё работает, можно удалить сразу.'
            : 'Less background overhead and less diagnostic noise. If the system works fine after disabling it, it can be removed immediately.',
        impact: AuditImpact.low,
        isCritical: false,
        requiresRestart: false,
        removalPolicy: RemovalPolicy.immediate,
        scannedAt: scannedAt,
      ),
      AuditFinding(
        id: 'task-manager-monitoring',
        title: isRussian ? 'Мониторинг сети и GPU' : 'Network and GPU Monitoring',
        summary: isRussian
            ? 'Службы мониторинга для Диспетчера задач. Нужны не всем, но их состояние должно быть прозрачным перед отключением.'
            : 'Task Manager monitoring services. Not everyone needs them, but the impact should be visible before disabling.',
        category: AuditCategory.service,
        currentState: _utilitiesService.statusTMMonitoring
            ? (isRussian ? 'Включено' : 'Enabled')
            : (isRussian ? 'Выключено' : 'Disabled'),
        proposedState: _utilitiesService.statusTMMonitoring
            ? (isRussian ? 'Отключить' : 'Disable')
            : (isRussian ? 'Ничего не менять' : 'Leave as is'),
        reason: isRussian
            ? 'Если пользователь не пользуется этими метриками, их можно держать выключенными и не тащить лишние службы.'
            : 'If the user does not rely on these metrics, they can stay disabled to avoid extra service overhead.',
        effect: isRussian
            ? 'Уменьшает лишние фоновые службы, но часть показателей в Диспетчере задач может стать недоступной.'
            : 'Reduces extra background services, but some Task Manager counters may disappear.',
        impact: AuditImpact.low,
        isCritical: false,
        requiresRestart: true,
        removalPolicy: RemovalPolicy.immediate,
        scannedAt: scannedAt,
      ),
      AuditFinding(
        id: 'driver-delivery',
        title: isRussian
            ? 'Установка драйверов через Windows Update'
            : 'Drivers via Windows Update',
        summary: isRussian
            ? 'Канал получения драйверов. Критичен для восстановления устройств, поэтому удалять его сразу нельзя.'
            : 'Driver delivery path. Critical for device recovery, so it should not be removed immediately.',
        category: AuditCategory.driver,
        currentState: _updatesService.statusDriversWU
            ? (isRussian ? 'Разрешено' : 'Allowed')
            : (isRussian ? 'Запрещено' : 'Blocked'),
        proposedState: _updatesService.statusDriversWU
            ? (isRussian ? 'Оставить доступным' : 'Keep available')
            : (isRussian ? 'Разрешить для сканирования и восстановления' : 'Allow for scanning and recovery'),
        reason: isRussian
            ? 'Перед жёсткой оптимизацией важно оставить путь для поиска и возврата драйверов, особенно редких или сломанных.'
            : 'Before aggressive optimization, keep a recovery path for rare or broken drivers.',
        effect: isRussian
            ? 'Даёт шанс восстановить проблемные устройства. Даже если потом решите отключить канал, удаление можно разрешать только спустя 72 часа стабильной работы.'
            : 'Provides a recovery path for problematic devices. Even if you later disable it, removal should only be allowed after 72 hours of stable operation.',
        impact: AuditImpact.high,
        isCritical: true,
        requiresRestart: false,
        removalPolicy: RemovalPolicy.delayed72Hours,
        scannedAt: scannedAt,
      ),
    ];
  }
}
