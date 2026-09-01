/// Date preset options — mirrors the web `datePresetOptions`.
enum DatePreset {
  thisWeek('This Week'),
  lastWeek('Last Week'),
  thisMonth('This Month'),
  lastMonth('Last Month'),
  thisYear('This Year'),
  lastYear('Last Year'),
  custom('Custom');

  final String label;
  const DatePreset(this.label);
}

/// Computes the [startDate] and [endDate] for a given preset.
class PresetRange {
  final DateTime start;
  final DateTime end;

  const PresetRange(this.start, this.end);

  String get startDateStr => _toIso(start);
  String get endDateStr => _toIso(end);

  /// Human-readable label, e.g. "Jan 1 - Aug 11, 2026"
  String get label {
    final fmt = (DateTime d) =>
        '${_monthShort(d.month)} ${d.day}${d.year != end.year ? ', ${d.year}' : ''}';
    return '${fmt(start)} - ${fmt(end)}, ${end.year}';
  }

  static String _toIso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _monthShort(int m) {
    const names = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return names[m - 1];
  }
}

/// Resolve a [DatePreset] (plus optional custom dates) to a [PresetRange].
PresetRange resolvePreset(DatePreset preset, {DateTime? customStart, DateTime? customEnd}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  switch (preset) {
    case DatePreset.thisWeek:
      final monday = today.subtract(Duration(days: today.weekday - 1));
      return PresetRange(monday, today);
    case DatePreset.lastWeek:
      final thisMonday = today.subtract(Duration(days: today.weekday - 1));
      final lastMonday = thisMonday.subtract(const Duration(days: 7));
      final lastSunday = thisMonday.subtract(const Duration(days: 1));
      return PresetRange(lastMonday, lastSunday);
    case DatePreset.thisMonth:
      return PresetRange(DateTime(now.year, now.month, 1), today);
    case DatePreset.lastMonth:
      final first = DateTime(now.year, now.month - 1, 1);
      final last = DateTime(now.year, now.month, 0);
      return PresetRange(first, last);
    case DatePreset.thisYear:
      return PresetRange(DateTime(now.year, 1, 1), today);
    case DatePreset.lastYear:
      return PresetRange(DateTime(now.year - 1, 1, 1), DateTime(now.year - 1, 12, 31));
    case DatePreset.custom:
      return PresetRange(customStart ?? today, customEnd ?? today);
  }
}
