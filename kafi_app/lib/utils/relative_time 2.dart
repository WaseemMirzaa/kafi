import 'package:get/get.dart';
import 'package:kafi_app/l10n/app_strings.dart';

/// Centralized relative-time formatting, replacing the per-screen `Xd/Xh/Xm
/// ago` duplicates that were previously hardcoded in chat, notifications,
/// disputes, support, and the family applicants list.
class RelativeTime {
  const RelativeTime._();

  /// "@n days/hours/minutes ago", or [AppStrings.supportJustNow] under a
  /// minute. Used by notifications, disputes, support tickets, and the
  /// family applicants list.
  static String ago(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) {
      return AppStrings.timeDaysAgo.trParams({'n': '${diff.inDays}'});
    }
    if (diff.inHours > 0) {
      return AppStrings.timeHoursAgo.trParams({'n': '${diff.inHours}'});
    }
    if (diff.inMinutes > 0) {
      return AppStrings.timeMinutesAgo.trParams({'n': '${diff.inMinutes}'});
    }
    return AppStrings.supportJustNow.tr;
  }

  /// Chat-thread-list style: minutes-ago under an hour, a clock time the same
  /// day, [AppStrings.timeYesterday] exactly one day back, else `d/m`.
  static String threadTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return AppStrings.timeMinutesAgo.trParams({'n': '${diff.inMinutes}'});
    }
    if (diff.inHours < 24) return clock(dt);
    if (diff.inDays == 1) return AppStrings.timeYesterday.tr;
    return '${dt.day}/${dt.month}';
  }

  /// 12-hour clock, e.g. "3:45 PM".
  static String clock(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? AppStrings.timeAm.tr : AppStrings.timePm.tr;
    return '$h:$m $ampm';
  }
}

/// Short, localized relative-time string for card/list rows, e.g. "3 d ago",
/// "5 h ago", "12 m ago". Thin wrapper over [RelativeTime.ago].
String formatRelativeTime(DateTime dt) => RelativeTime.ago(dt);
