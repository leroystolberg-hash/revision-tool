import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/features/tweaks/system_audit/system_audit_models.dart';

void main() {
  test('delayed72Hours removal policy waits exactly 72 hours', () {
    final scannedAt = DateTime(2026, 3, 18, 12, 0);
    final finding = AuditFinding(
      id: 'critical-test',
      title: 'Critical test',
      summary: 'Critical path',
      category: AuditCategory.service,
      currentState: 'Enabled',
      proposedState: 'Disable',
      reason: 'Needed for testing',
      effect: 'Observation window before removal',
      impact: AuditImpact.high,
      isCritical: true,
      requiresRestart: true,
      removalPolicy: RemovalPolicy.delayed72Hours,
      scannedAt: scannedAt,
    );

    expect(finding.removalEligibleAt, scannedAt.add(const Duration(hours: 72)));
  });

  test('immediate removal policy is available at scan time', () {
    final scannedAt = DateTime(2026, 3, 18, 12, 0);
    final finding = AuditFinding(
      id: 'instant-test',
      title: 'Instant test',
      summary: 'Immediate removal',
      category: AuditCategory.registry,
      currentState: 'Enabled',
      proposedState: 'Disable',
      reason: 'Needed for testing',
      effect: 'Can be removed now',
      impact: AuditImpact.low,
      isCritical: false,
      requiresRestart: false,
      removalPolicy: RemovalPolicy.immediate,
      scannedAt: scannedAt,
    );

    expect(finding.removalEligibleAt, scannedAt);
  });
}
