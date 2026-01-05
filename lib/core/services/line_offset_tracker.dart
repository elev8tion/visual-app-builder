import 'package:flutter/foundation.dart';

/// Line Offset Tracker
///
/// Utility to track line number changes after code modifications.
/// Solves the problem where widget insertions/deletions shift line numbers
/// but the system still uses old line numbers.
///
/// Example problem:
/// - User selects widget at line 10
/// - Inserts new widget at line 5
/// - Widget that was at line 10 is now at line 11
/// - Without tracking, system still tries to access line 10 → wrong widget!
///
/// Thread-safe for async operations.
class LineOffsetTracker {
  /// Map of original line number → current line number
  final Map<int, int> _lineOffsets = {};

  /// Track when the tracker was last reset (for debugging)
  DateTime? _lastReset;

  /// Record an insertion operation
  ///
  /// When lines are inserted, all lines after the insertion point shift down.
  ///
  /// Example:
  /// ```
  /// recordInsertion(lineNumber: 5, linesInserted: 2)
  /// // Lines 5+ shift down by 2
  /// // Line 10 becomes line 12
  /// ```
  void recordInsertion({
    required int lineNumber,
    required int linesInserted,
  }) {
    if (linesInserted <= 0) return;

    debugPrint('[LineOffsetTracker] Recording insertion: $linesInserted lines at line $lineNumber');

    // Update all tracked lines that come after the insertion point
    final updatedOffsets = <int, int>{};

    for (final entry in _lineOffsets.entries) {
      final originalLine = entry.key;
      final currentLine = entry.value;

      if (currentLine >= lineNumber) {
        // This line is after the insertion, shift it down
        updatedOffsets[originalLine] = currentLine + linesInserted;
        debugPrint('[LineOffsetTracker]   Line $originalLine: $currentLine → ${currentLine + linesInserted}');
      } else {
        // This line is before the insertion, no change
        updatedOffsets[originalLine] = currentLine;
      }
    }

    _lineOffsets.clear();
    _lineOffsets.addAll(updatedOffsets);

    debugPrint('[LineOffsetTracker] Tracking ${_lineOffsets.length} lines');
  }

  /// Record a deletion operation
  ///
  /// When lines are deleted, all lines after the deletion point shift up.
  /// Lines within the deleted range are removed from tracking.
  ///
  /// Example:
  /// ```
  /// recordDeletion(startLine: 5, linesDeleted: 2)
  /// // Lines 5-6 are deleted
  /// // Lines 7+ shift up by 2
  /// // Line 10 becomes line 8
  /// ```
  void recordDeletion({
    required int startLine,
    required int linesDeleted,
  }) {
    if (linesDeleted <= 0) return;

    debugPrint('[LineOffsetTracker] Recording deletion: $linesDeleted lines starting at line $startLine');

    final endLine = startLine + linesDeleted - 1;
    final updatedOffsets = <int, int>{};

    for (final entry in _lineOffsets.entries) {
      final originalLine = entry.key;
      final currentLine = entry.value;

      if (currentLine >= startLine && currentLine <= endLine) {
        // This line was deleted, remove it from tracking
        debugPrint('[LineOffsetTracker]   Line $originalLine (at $currentLine): DELETED');
      } else if (currentLine > endLine) {
        // This line is after the deletion, shift it up
        final newLine = currentLine - linesDeleted;
        updatedOffsets[originalLine] = newLine;
        debugPrint('[LineOffsetTracker]   Line $originalLine: $currentLine → $newLine');
      } else {
        // This line is before the deletion, no change
        updatedOffsets[originalLine] = currentLine;
      }
    }

    _lineOffsets.clear();
    _lineOffsets.addAll(updatedOffsets);

    debugPrint('[LineOffsetTracker] Tracking ${_lineOffsets.length} lines');
  }

  /// Get the current line number for an original line number
  ///
  /// If the line hasn't been tracked yet, it starts tracking it.
  /// This allows lazy tracking - we only track lines that are actually used.
  ///
  /// Returns the current line number after all insertions/deletions.
  int getCurrentLine(int originalLine) {
    if (_lineOffsets.containsKey(originalLine)) {
      final currentLine = _lineOffsets[originalLine]!;
      debugPrint('[LineOffsetTracker] getCurrentLine($originalLine) → $currentLine (tracked)');
      return currentLine;
    }

    // Line hasn't been tracked yet, start tracking it now
    _lineOffsets[originalLine] = originalLine;
    debugPrint('[LineOffsetTracker] getCurrentLine($originalLine) → $originalLine (new tracking)');
    return originalLine;
  }

  /// Check if a line is currently being tracked
  bool isTracking(int originalLine) {
    return _lineOffsets.containsKey(originalLine);
  }

  /// Reset all tracking
  ///
  /// Should be called after the AST is re-parsed, since the new AST
  /// will have fresh, accurate line numbers.
  void reset() {
    debugPrint('[LineOffsetTracker] Reset: clearing ${_lineOffsets.length} tracked lines');
    _lineOffsets.clear();
    _lastReset = DateTime.now();
  }

  /// Get number of currently tracked lines
  int get trackedLineCount => _lineOffsets.length;

  /// Get when the tracker was last reset (for debugging)
  DateTime? get lastReset => _lastReset;

  /// Get all tracked offsets (for debugging)
  Map<int, int> get offsets => Map.unmodifiable(_lineOffsets);

  /// Debug print all tracked lines
  void debugPrintState() {
    debugPrint('[LineOffsetTracker] State:');
    debugPrint('  Tracked lines: ${_lineOffsets.length}');
    debugPrint('  Last reset: ${_lastReset ?? "never"}');
    if (_lineOffsets.isNotEmpty) {
      debugPrint('  Mappings:');
      for (final entry in _lineOffsets.entries) {
        debugPrint('    Line ${entry.key} → ${entry.value}');
      }
    }
  }
}
