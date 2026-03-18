enum AuditCategory { service, registry, driver, system }

enum AuditImpact { low, medium, high }

enum RemovalPolicy { none, immediate, delayed72Hours }

class AuditFinding {
  const AuditFinding({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.currentState,
    required this.proposedState,
    required this.reason,
    required this.effect,
    required this.impact,
    required this.isCritical,
    required this.requiresRestart,
    required this.removalPolicy,
    required this.scannedAt,
  });

  final String id;
  final String title;
  final String summary;
  final AuditCategory category;
  final String currentState;
  final String proposedState;
  final String reason;
  final String effect;
  final AuditImpact impact;
  final bool isCritical;
  final bool requiresRestart;
  final RemovalPolicy removalPolicy;
  final DateTime scannedAt;

  bool get canDisableNow => proposedState != currentState;

  DateTime? get removalEligibleAt => switch (removalPolicy) {
    RemovalPolicy.none => null,
    RemovalPolicy.immediate => scannedAt,
    RemovalPolicy.delayed72Hours => scannedAt.add(const Duration(hours: 72)),
  };
}
