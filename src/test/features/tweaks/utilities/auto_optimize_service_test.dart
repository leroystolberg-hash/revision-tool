import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/features/tweaks/utilities/auto_optimize_service.dart';

void main() {
  test('OptimizationRunResult exposes success and failure counts', () {
    const result = OptimizationRunResult(
      preset: OptimizationPreset.safe,
      steps: [
        OptimizationStepResult(label: 'A', success: true),
        OptimizationStepResult(label: 'B', success: false, error: 'boom'),
        OptimizationStepResult(label: 'C', success: true),
      ],
    );

    expect(result.successfulSteps, 2);
    expect(result.failedSteps, 1);
  });
}
