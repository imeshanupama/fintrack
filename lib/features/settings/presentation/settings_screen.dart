import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../application/data_export_service.dart';
import '../../security/data/biometric_service.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../../core/backup/backup_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final authUser = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(authStateProvider);
        },
        child: ListView(
          children: [
            // Profile Header
            if (authUser.asData?.value != null)
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                     CircleAvatar(
                       radius: 30,
                       backgroundColor: Theme.of(context).primaryColor,
                       child: Text(
                         authUser.asData!.value!.email![0].toUpperCase(),
                         style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                       ),
                     ),
                     const SizedBox(width: 16),
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           authUser.asData!.value!.displayName ?? 'User',
                           style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                         ),
                         Text(
                           authUser.asData!.value!.email!,
                           style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                         ),
                       ],
                     ),
                     const Spacer(),
                     IconButton(
                       icon: const Icon(Icons.edit),
                       onPressed: () => _showEditNameDialog(context, ref, authUser.asData!.value!.displayName),
                     ),
                  ],
                ),
              ),
            const Divider(),
            const SizedBox(height: 10),
  
            ListTile(
              leading: const Icon(Icons.category),
              title: Text('Manage Categories', style: GoogleFonts.outfit()),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                context.push('/manage-categories');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.repeat),
              title: Text('Recurring Transactions', style: GoogleFonts.outfit()),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                context.push('/recurring');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.splitscreen),
              title: Text('Bill Splits', style: GoogleFonts.outfit()),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                context.push('/bill-splits');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: Text('Financial Insights', style: GoogleFonts.outfit()),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                context.push('/insights');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text('Theme', style: GoogleFonts.outfit()),
              subtitle: Text(settings.themeMode.name.toUpperCase(), style: GoogleFonts.outfit(color: Colors.grey)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                showModalBottomSheet(context: context, builder: (context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       ListTile(title: const Text('System'), onTap: () { notifier.setThemeMode(ThemeMode.system); context.pop(); }),
                       ListTile(title: const Text('Light'), onTap: () { notifier.setThemeMode(ThemeMode.light); context.pop(); }),
                       ListTile(title: const Text('Dark'), onTap: () { notifier.setThemeMode(ThemeMode.dark); context.pop(); }),
                    ],
                  );
                });
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.currency_exchange),
              title: Text('Currency', style: GoogleFonts.outfit()),
              subtitle: Text(settings.currency, style: GoogleFonts.outfit(color: Colors.grey)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                showModalBottomSheet(context: context, builder: (context) {
                  final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'INR', 'LKR'];
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: currencies.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(currencies[index]),
                          onTap: () {
                            notifier.setCurrency(currencies[index]);
                            context.pop();
                          },
                          trailing: settings.currency == currencies[index] ? const Icon(Icons.check) : null,
                        );
                      },
                    ),
                  );
                });
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: Text('App Lock', style: GoogleFonts.outfit()),
              subtitle: Text(settings.isBiometricsEnabled ? 'Enabled' : 'Disabled', style: GoogleFonts.outfit(color: Colors.grey)),
              trailing: Switch(
                value: settings.isBiometricsEnabled,
                onChanged: (val) async {
                  if (val) {
                    final canCheck = await ref.read(biometricServiceProvider).canCheckBiometrics();
                    if (!canCheck) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometrics not available on this device')));
                      }
                      return;
                    }
                    final authenticated = await ref.read(biometricServiceProvider).authenticate();
                    if (authenticated) {
                      ref.read(settingsProvider.notifier).setBiometricsEnabled(true);
                    }
                  } else {
                    ref.read(settingsProvider.notifier).setBiometricsEnabled(false);
                  }
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text('Daily Reminder', style: GoogleFonts.outfit()),
              subtitle: Text(settings.isDailyReminderEnabled ? 'Enabled at ${settings.dailyReminderTime}' : 'Disabled', style: GoogleFonts.outfit(color: Colors.grey)),
              trailing: Switch(
                value: settings.isDailyReminderEnabled,
                onChanged: (val) async {
                  await notifier.setDailyReminderEnabled(val);
                  if (val) {
                    await ref.read(notificationServiceProvider).requestPermissions();
                    final timeParts = settings.dailyReminderTime.split(':');
                    final hour = int.parse(timeParts[0]);
                    final minute = int.parse(timeParts[1]);
                    await ref.read(notificationServiceProvider).scheduleDailyReminder(hour, minute);
                  } else {
                    await ref.read(notificationServiceProvider).cancelReminder();
                  }
                },
              ),
            ),
             if (settings.isDailyReminderEnabled)
              ListTile(
                leading: const SizedBox(), // Indent
                title: Text('Reminder Time', style: GoogleFonts.outfit()),
                subtitle: Text(settings.dailyReminderTime, style: GoogleFonts.outfit(color: Colors.grey)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final timeParts = settings.dailyReminderTime.split(':');
                  final initialTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
                  
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: initialTime,
                  );

                  if (picked != null) {
                    final newTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                    await notifier.setDailyReminderTime(newTime);
                    await ref.read(notificationServiceProvider).scheduleDailyReminder(picked.hour, picked.minute);
                  }
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text('Reports & Export', style: GoogleFonts.outfit()),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                context.push('/reports');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: Text('Backup Data', style: GoogleFonts.outfit()),
              subtitle: Text('Export to JSON', style: GoogleFonts.outfit(color: Colors.grey)),
              onTap: () async {
                await ref.read(backupServiceProvider).createBackup(context);
              },
            ),
             ListTile(
              leading: const Icon(Icons.restore_page_outlined),
              title: Text('Restore Data', style: GoogleFonts.outfit()),
              subtitle: Text('Import from JSON', style: GoogleFonts.outfit(color: Colors.grey)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Restore Backup?'),
                    content: const Text(
                      'WARNING: This will overwrite CURRENT data with the backup data. This action cannot be undone.',
                      style: TextStyle(color: Colors.red),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ref.read(backupServiceProvider).restoreBackup(context);
                        },
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Restore'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text('Log Out', style: GoogleFonts.outfit(color: Colors.red)),
              onTap: () {
                ref.read(authControllerProvider.notifier).signOut();
              },
            ),
          ],
        ),
      ),
    );
  }


  void _showEditNameDialog(BuildContext context, WidgetRef ref, String? currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Updated Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Display Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ref.read(authControllerProvider.notifier).updateProfile(displayName: controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
