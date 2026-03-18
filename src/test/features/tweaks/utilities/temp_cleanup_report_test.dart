import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/features/tweaks/utilities/utilities_service.dart';

void main() {
  test('TempCleanupReport.copyWith overrides only provided fields', () {
    const report = TempCleanupReport(
      totalBytes: 1024,
      entries: 5,
      cleanedBytes: 0,
      cleanedEntries: 0,
      scannedDirectories: ['C:/Temp'],
    );

    final updated = report.copyWith(cleanedBytes: 512, cleanedEntries: 2);

    expect(updated.totalBytes, 1024);
    expect(updated.entries, 5);
    expect(updated.cleanedBytes, 512);
    expect(updated.cleanedEntries, 2);
    expect(updated.scannedDirectories, ['C:/Temp']);
  });
}
