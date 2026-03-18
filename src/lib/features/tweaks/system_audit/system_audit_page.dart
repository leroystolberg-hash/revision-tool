import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;

import '../../../core/widgets/card_highlight.dart';
import '../../../core/widgets/subtitle.dart';
import '../../../extensions.dart';
import '../../../utils_gui.dart';
import 'system_audit_models.dart';
import 'system_audit_service.dart';

class SystemAuditPage extends StatefulWidget {
  const SystemAuditPage({super.key});

  @override
  State<SystemAuditPage> createState() => _SystemAuditPageState();
}

class _SystemAuditPageState extends State<SystemAuditPage> {
  final SystemAuditService _auditService = const SystemAuditService();
  late List<AuditFinding> _findings;
  late DateTime _scannedAt;

  bool get _isRussian => Localizations.localeOf(context).languageCode == 'ru';

  @override
  void initState() {
    super.initState();
    _runScan();
  }

  void _runScan() {
    _scannedAt = DateTime.now();
    _findings = _auditService.scan(
      languageCode: WidgetsBinding.instance.platformDispatcher.locale.languageCode,
      now: _scannedAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final int criticalCount = _findings.where((item) => item.isCritical).length;
    final int restartCount = _findings.where((item) => item.requiresRestart).length;
    final int removableNowCount = _findings
        .where((item) => item.removalEligibleAt == item.scannedAt)
        .length;

    return ScaffoldPage.scrollable(
      padding: kScaffoldPagePadding,
      children: [
        CardHighlight(
          icon: msicons.FluentIcons.search_20_regular,
          label: _isRussian ? 'Сканирование и предпросмотр' : 'Scan and preview',
          description: _isRussian
              ? 'Сначала смотри, что найдено и что изменится. Для критичных компонентов удаление разрешается только спустя 72 часа после отключения.'
              : 'Review what was found and what will change first. Critical components can only be removed after 72 hours from disabling them.',
          action: Button(
            onPressed: () => setState(_runScan),
            child: Text(_isRussian ? 'Пересканировать' : 'Rescan'),
          ),
          children: [
            CardListTile(
              title: _isRussian ? 'Последний скан' : 'Last scan',
              description: _formatDate(_scannedAt),
            ),
            CardListTile(
              title: _isRussian ? 'Критичные элементы' : 'Critical items',
              description: '$criticalCount',
            ),
            CardListTile(
              title: _isRussian ? 'Нужен перезапуск' : 'Restart required',
              description: '$restartCount',
            ),
            CardListTile(
              title: _isRussian ? 'Можно удалить сразу' : 'Can be removed immediately',
              description: '$removableNowCount',
            ),
          ],
          initiallyExpanded: true,
        ),
        Subtitle(
          content: Text(
            _isRussian
                ? 'Что будет изменено'
                : 'What will be changed',
          ),
        ),
        ..._findings.map(_buildFindingCard),
      ].withSpacing(5),
    );
  }

  Widget _buildFindingCard(AuditFinding finding) {
    return CardHighlight(
      icon: _categoryIcon(finding.category),
      label: finding.title,
      description: finding.summary,
      action: _ImpactBadge(impact: finding.impact, isRussian: _isRussian),
      children: [
        CardListTile(
          title: _isRussian ? 'Категория' : 'Category',
          description: _categoryLabel(finding.category),
        ),
        CardListTile(
          title: _isRussian ? 'Сейчас' : 'Current state',
          description: finding.currentState,
        ),
        CardListTile(
          title: _isRussian ? 'Планируется' : 'Planned state',
          description: finding.proposedState,
        ),
        CardListTile(
          title: _isRussian ? 'Почему найдено' : 'Why it was flagged',
          description: finding.reason,
        ),
        CardListTile(
          title: _isRussian ? 'Что изменится' : 'What changes',
          description: finding.effect,
        ),
        CardListTile(
          title: _isRussian ? 'Перезапуск' : 'Restart',
          description: finding.requiresRestart
              ? (_isRussian ? 'Требуется' : 'Required')
              : (_isRussian ? 'Не требуется' : 'Not required'),
        ),
        CardListTile(
          title: _isRussian ? 'Удаление' : 'Removal policy',
          description: _removalPolicyLabel(finding),
        ),
      ],
    );
  }

  IconData _categoryIcon(AuditCategory category) => switch (category) {
    AuditCategory.service => FluentIcons.settings,
    AuditCategory.registry => FluentIcons.page,
    AuditCategory.driver => FluentIcons.download,
    AuditCategory.system => FluentIcons.system,
  };

  String _categoryLabel(AuditCategory category) => switch (category) {
    AuditCategory.service => _isRussian ? 'Служба' : 'Service',
    AuditCategory.registry => _isRussian ? 'Реестр' : 'Registry',
    AuditCategory.driver => _isRussian ? 'Драйвер' : 'Driver',
    AuditCategory.system => _isRussian ? 'Система' : 'System',
  };

  String _removalPolicyLabel(AuditFinding finding) {
    return switch (finding.removalPolicy) {
      RemovalPolicy.none => _isRussian
          ? 'Удаление не планируется.'
          : 'Removal is not planned.',
      RemovalPolicy.immediate => _isRussian
          ? 'Можно удалить сразу после отключения, если функция не нужна.'
          : 'Can be removed immediately after disabling if the function is not needed.',
      RemovalPolicy.delayed72Hours => _isRussian
          ? 'Критичный элемент: сначала отключение, затем 72 часа наблюдения. Удаление не раньше ${_formatDate(finding.removalEligibleAt!)}.'
          : 'Critical item: disable first, observe for 72 hours, remove no earlier than ${_formatDate(finding.removalEligibleAt!)}.',
    };
  }

  String _formatDate(DateTime value) {
    final String mm = value.month.toString().padLeft(2, '0');
    final String dd = value.day.toString().padLeft(2, '0');
    final String hh = value.hour.toString().padLeft(2, '0');
    final String min = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$mm-$dd $hh:$min';
  }
}

class _ImpactBadge extends StatelessWidget {
  const _ImpactBadge({required this.impact, required this.isRussian});

  final AuditImpact impact;
  final bool isRussian;

  @override
  Widget build(BuildContext context) {
    final ({String label, Color color}) meta = switch (impact) {
      AuditImpact.low => (
        label: isRussian ? 'Низкий риск' : 'Low risk',
        color: Colors.green,
      ),
      AuditImpact.medium => (
        label: isRussian ? 'Средний риск' : 'Medium risk',
        color: Colors.orange,
      ),
      AuditImpact.high => (
        label: isRussian ? 'Высокий риск' : 'High risk',
        color: Colors.red,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: meta.color.withValues(alpha: 0.35)),
      ),
      child: Text(
        meta.label,
        style: TextStyle(
          color: meta.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
