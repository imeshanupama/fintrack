class NotificationSettings {
  // Budget Alerts
  final bool budgetAlertsEnabled;
  final int budgetAlertThreshold; // Percentage (e.g., 80)
  
  // Bill Reminders
  final bool billRemindersEnabled;
  final int billReminderDaysBefore; // Days before due date
  
  // Anomaly Alerts
  final bool anomalyAlertsEnabled;
  final double anomalyThresholdMultiplier; // e.g., 2.0 = 2x average
  
  // Summaries
  final bool weeklySummaryEnabled;
  final bool monthlySummaryEnabled;
  final int summaryHour; // Hour of day (0-23)
  
  // General
  final bool notificationsEnabled;

  NotificationSettings({
    this.budgetAlertsEnabled = true,
    this.budgetAlertThreshold = 80,
    this.billRemindersEnabled = true,
    this.billReminderDaysBefore = 3,
    this.anomalyAlertsEnabled = true,
    this.anomalyThresholdMultiplier = 2.0,
    this.weeklySummaryEnabled = true,
    this.monthlySummaryEnabled = true,
    this.summaryHour = 18, // 6 PM
    this.notificationsEnabled = true,
  });

  NotificationSettings copyWith({
    bool? budgetAlertsEnabled,
    int? budgetAlertThreshold,
    bool? billRemindersEnabled,
    int? billReminderDaysBefore,
    bool? anomalyAlertsEnabled,
    double? anomalyThresholdMultiplier,
    bool? weeklySummaryEnabled,
    bool? monthlySummaryEnabled,
    int? summaryHour,
    bool? notificationsEnabled,
  }) {
    return NotificationSettings(
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      budgetAlertThreshold: budgetAlertThreshold ?? this.budgetAlertThreshold,
      billRemindersEnabled: billRemindersEnabled ?? this.billRemindersEnabled,
      billReminderDaysBefore: billReminderDaysBefore ?? this.billReminderDaysBefore,
      anomalyAlertsEnabled: anomalyAlertsEnabled ?? this.anomalyAlertsEnabled,
      anomalyThresholdMultiplier: anomalyThresholdMultiplier ?? this.anomalyThresholdMultiplier,
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
      monthlySummaryEnabled: monthlySummaryEnabled ?? this.monthlySummaryEnabled,
      summaryHour: summaryHour ?? this.summaryHour,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'budgetAlertsEnabled': budgetAlertsEnabled,
      'budgetAlertThreshold': budgetAlertThreshold,
      'billRemindersEnabled': billRemindersEnabled,
      'billReminderDaysBefore': billReminderDaysBefore,
      'anomalyAlertsEnabled': anomalyAlertsEnabled,
      'anomalyThresholdMultiplier': anomalyThresholdMultiplier,
      'weeklySummaryEnabled': weeklySummaryEnabled,
      'monthlySummaryEnabled': monthlySummaryEnabled,
      'summaryHour': summaryHour,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      budgetAlertsEnabled: json['budgetAlertsEnabled'] ?? true,
      budgetAlertThreshold: json['budgetAlertThreshold'] ?? 80,
      billRemindersEnabled: json['billRemindersEnabled'] ?? true,
      billReminderDaysBefore: json['billReminderDaysBefore'] ?? 3,
      anomalyAlertsEnabled: json['anomalyAlertsEnabled'] ?? true,
      anomalyThresholdMultiplier: json['anomalyThresholdMultiplier'] ?? 2.0,
      weeklySummaryEnabled: json['weeklySummaryEnabled'] ?? true,
      monthlySummaryEnabled: json['monthlySummaryEnabled'] ?? true,
      summaryHour: json['summaryHour'] ?? 18,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
    );
  }
}
