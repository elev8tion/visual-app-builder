import 'package:flutter_test/flutter_test.dart';
import 'package:visual_app_builder/core/services/line_offset_tracker.dart';

void main() {
  group('LineOffsetTracker', () {
    late LineOffsetTracker tracker;

    setUp(() {
      tracker = LineOffsetTracker();
    });

    test('should track new line without offset', () {
      final currentLine = tracker.getCurrentLine(10);
      expect(currentLine, 10);
      expect(tracker.trackedLineCount, 1);
    });

    test('should record insertion and update tracked lines', () {
      // Set up: Track lines 5, 10, 15
      tracker.getCurrentLine(5);
      tracker.getCurrentLine(10);
      tracker.getCurrentLine(15);

      // Insert 3 lines at line 8
      tracker.recordInsertion(lineNumber: 8, linesInserted: 3);

      // Lines before insertion point should not change
      expect(tracker.getCurrentLine(5), 5);

      // Lines at/after insertion point should shift down
      expect(tracker.getCurrentLine(10), 13); // 10 + 3
      expect(tracker.getCurrentLine(15), 18); // 15 + 3
    });

    test('should record deletion and update tracked lines', () {
      // Set up: Track lines 5, 10, 15, 20
      tracker.getCurrentLine(5);
      tracker.getCurrentLine(10);
      tracker.getCurrentLine(15);
      tracker.getCurrentLine(20);

      // Delete 3 lines starting at line 12
      tracker.recordDeletion(startLine: 12, linesDeleted: 3);

      // Lines before deletion should not change
      expect(tracker.getCurrentLine(5), 5);
      expect(tracker.getCurrentLine(10), 10);

      // Lines after deletion should shift up
      expect(tracker.getCurrentLine(15), 12); // 15 - 3
      expect(tracker.getCurrentLine(20), 17); // 20 - 3
    });

    test('should remove deleted lines from tracking', () {
      // Set up: Track lines 8, 10, 12, 14
      tracker.getCurrentLine(8);
      tracker.getCurrentLine(10);
      tracker.getCurrentLine(12);
      tracker.getCurrentLine(14);

      expect(tracker.trackedLineCount, 4);

      // Delete lines 10-11 (2 lines starting at 10)
      tracker.recordDeletion(startLine: 10, linesDeleted: 2);

      // Line 10 should be removed from tracking
      expect(tracker.trackedLineCount, 3); // One less line tracked

      // Line 8 before deletion: unchanged
      expect(tracker.getCurrentLine(8), 8);

      // Lines 12, 14 after deletion: shifted up by 2
      expect(tracker.getCurrentLine(12), 10); // 12 - 2
      expect(tracker.getCurrentLine(14), 12); // 14 - 2
    });

    test('should handle multiple insertions', () {
      tracker.getCurrentLine(10);

      // First insertion: 2 lines at line 5
      tracker.recordInsertion(lineNumber: 5, linesInserted: 2);
      expect(tracker.getCurrentLine(10), 12); // 10 + 2

      // Second insertion: 3 lines at line 8
      tracker.recordInsertion(lineNumber: 8, linesInserted: 3);
      expect(tracker.getCurrentLine(10), 15); // 12 + 3
    });

    test('should handle multiple deletions', () {
      tracker.getCurrentLine(20);

      // First deletion: 2 lines at line 5
      tracker.recordDeletion(startLine: 5, linesDeleted: 2);
      expect(tracker.getCurrentLine(20), 18); // 20 - 2

      // Second deletion: 3 lines at line 10
      tracker.recordDeletion(startLine: 10, linesDeleted: 3);
      expect(tracker.getCurrentLine(20), 15); // 18 - 3
    });

    test('should reset all tracking', () {
      tracker.getCurrentLine(5);
      tracker.getCurrentLine(10);
      tracker.recordInsertion(lineNumber: 7, linesInserted: 2);

      expect(tracker.trackedLineCount, 2);
      expect(tracker.getCurrentLine(10), 12);

      tracker.reset();

      expect(tracker.trackedLineCount, 0);
      expect(tracker.lastReset, isNotNull);

      // After reset, line 10 should track as 10 again
      expect(tracker.getCurrentLine(10), 10);
    });

    test('should handle insertions before tracked line', () {
      tracker.getCurrentLine(10);

      tracker.recordInsertion(lineNumber: 5, linesInserted: 3);

      expect(tracker.getCurrentLine(10), 13);
    });

    test('should handle insertions after tracked line', () {
      tracker.getCurrentLine(10);

      tracker.recordInsertion(lineNumber: 15, linesInserted: 3);

      // Line 10 is before insertion, should not change
      expect(tracker.getCurrentLine(10), 10);
    });

    test('should handle real-world scenario: insert then update', () {
      // User selects widget at line 10
      final originalLine = 10;
      tracker.getCurrentLine(originalLine);

      // User inserts new widget at line 5 (3 lines of code)
      tracker.recordInsertion(lineNumber: 5, linesInserted: 3);

      // Widget that was at line 10 is now at line 13
      final currentLine = tracker.getCurrentLine(originalLine);
      expect(currentLine, 13);

      // User updates property on the widget
      // System should use line 13, not line 10
      expect(currentLine, 13);
    });

    test('should handle real-world scenario: delete then select', () {
      // Track multiple widgets
      tracker.getCurrentLine(5);
      tracker.getCurrentLine(10);
      tracker.getCurrentLine(15);

      // Delete widget at lines 8-9 (2 lines)
      tracker.recordDeletion(startLine: 8, linesDeleted: 2);

      // Widget at line 5: unchanged
      expect(tracker.getCurrentLine(5), 5);

      // Widget at line 10: now at line 8
      expect(tracker.getCurrentLine(10), 8);

      // Widget at line 15: now at line 13
      expect(tracker.getCurrentLine(15), 13);
    });

    test('should check if line is being tracked', () {
      expect(tracker.isTracking(10), false);

      tracker.getCurrentLine(10);
      expect(tracker.isTracking(10), true);

      tracker.reset();
      expect(tracker.isTracking(10), false);
    });

    test('should ignore zero-line insertions', () {
      tracker.getCurrentLine(10);
      tracker.recordInsertion(lineNumber: 5, linesInserted: 0);

      expect(tracker.getCurrentLine(10), 10);
    });

    test('should ignore negative-line insertions', () {
      tracker.getCurrentLine(10);
      tracker.recordInsertion(lineNumber: 5, linesInserted: -1);

      expect(tracker.getCurrentLine(10), 10);
    });
  });
}
