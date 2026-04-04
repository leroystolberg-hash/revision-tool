import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/core/settings/tool_update_service.dart';

void main() {
  group('ToolUpdateService.compareVersions', () {
    test('handles double-digit segments correctly', () {
      expect(
        ToolUpdateService.compareVersions('2.10.0', '2.9.10'),
        greaterThan(0),
      );
    });

    test('treats v-prefixed and plain tags as equal', () {
      expect(ToolUpdateService.compareVersions('v2.7.6', '2.7.6'), equals(0));
    });

    test('treats stable versions as newer than pre-release', () {
      expect(
        ToolUpdateService.compareVersions('2.7.6', '2.7.6-rc.1'),
        greaterThan(0),
      );
      expect(
        ToolUpdateService.compareVersions('2.7.6-beta.1', '2.7.6'),
        lessThan(0),
      );
    });

    test('compares pre-release identifiers correctly', () {
      expect(
        ToolUpdateService.compareVersions('2.7.6-rc.2', '2.7.6-rc.1'),
        greaterThan(0),
      );
      expect(
        ToolUpdateService.compareVersions('2.7.6-rc.1', '2.7.6-rc.1'),
        equals(0),
      );
    });

    test('ignores build metadata for precedence', () {
      expect(
        ToolUpdateService.compareVersions('2.7.6+1', '2.7.6+999'),
        equals(0),
      );
    });
  });

  group('ToolUpdateService update state', () {
    test('reports update availability from fetched latest tag', () {
      final service = ToolUpdateService();

      service.data
        ..clear()
        ..addAll(<String, dynamic>{'tag_name': '2.0.0'});
      expect(service.isLatestVersionNewer, isTrue);

      service.data
        ..clear()
        ..addAll(<String, dynamic>{'tag_name': '0.9.9'});
      expect(service.isLatestVersionNewer, isFalse);
    });

    test('returns -1 when latest data has not been fetched', () {
      final service = ToolUpdateService();
      service.data.clear();
      expect(service.getLatestVersion, equals(-1));
      expect(service.isLatestVersionNewer, isFalse);
    });
  });
}
