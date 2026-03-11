import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import 'scan_history_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverAppBar(
          floating: true,
          snap: true,
          title: Text(
            'Settings',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Appearance', isDark),
                _buildSettingCard(
                  title: 'Dark Mode',
                  subtitle: 'Enable dark theme for the app',
                  icon: Icons.dark_mode_rounded,
                  isDark: isDark,
                  trailing: Switch(
                    value: provider.isDarkMode,
                    onChanged: (value) => provider.toggleDarkMode(),
                  ),
                ),
                const SizedBox(height: 12),
                _buildLanguageSelector(provider, isDark),
                const SizedBox(height: 32),
                _buildSectionHeader('Security', isDark),
                _buildSettingCard(
                  title: 'App PIN Lock',
                  subtitle: 'Require a PIN to access your inventory',
                  icon: Icons.security_rounded,
                  isDark: isDark,
                  trailing: Switch(
                    value: provider.usePinLock,
                    onChanged: (value) => _handlePinToggle(context, provider, value),
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('Data Management', isDark),
                _buildSettingCard(
                  title: 'Export to CSV',
                  subtitle: 'Save your inventory as a spreadsheet',
                  icon: Icons.table_view_rounded,
                  isDark: isDark,
                  onTap: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Generating CSV...')),
                    );
                    await provider.exportToCSV();
                  },
                ),
                const SizedBox(height: 12),
                _buildSettingCard(
                  title: 'Export to PDF',
                  subtitle: 'Generate a printable PDF report',
                  icon: Icons.picture_as_pdf_rounded,
                  isDark: isDark,
                  onTap: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Generating PDF...')),
                    );
                    await provider.exportToPDF();
                  },
                ),
                const SizedBox(height: 12),
                _buildSettingCard(
                  title: 'Import from CSV',
                  subtitle: 'Bulk add boxes and items from CSV',
                  icon: Icons.upload_file_rounded,
                  isDark: isDark,
                  onTap: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['csv'],
                    );
                    if (result != null) {
                      await provider.importFromCSV(result.files.single.path!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import complete!')));
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildSettingCard(
                  title: 'Scan History',
                  subtitle: 'View all previously scanned QR codes',
                  icon: Icons.qr_code_scanner_rounded,
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScanHistoryScreen()),
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('General', isDark),
                _buildSettingCard(
                  title: 'Data Privacy & Security',
                  subtitle: 'All your data stays completely offline',
                  icon: Icons.lock_rounded,
                  isDark: isDark,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Boxwise is 100% offline and secure!')),
                    );
                  },
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('Future-Ready', isDark),
                _buildSettingCard(
                  title: 'Cloud Sync',
                  subtitle: 'Coming soon — sync inventory across devices',
                  icon: Icons.cloud_sync_rounded,
                  isDark: isDark,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Soon', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.accentColor)),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSettingCard(
                  title: 'Multi-User Collaboration',
                  subtitle: 'Coming soon — share inventory with your team',
                  icon: Icons.group_rounded,
                  isDark: isDark,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Soon', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.warningColor)),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSettingCard(
                  title: 'API Backend',
                  subtitle: 'Coming soon — connect to external systems',
                  icon: Icons.api_rounded,
                  isDark: isDark,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Soon', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                  ),
                ),
                const SizedBox(height: 32),
                // App info
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_rounded, color: AppTheme.primaryColor.withAlpha(102), size: 32),
                      const SizedBox(height: 8),
                      const Text('Boxwise v1.0.0', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Smart Inventory Management', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector(InventoryProvider provider, bool isDark) {
    return _buildSettingCard(
      title: 'App Language',
      subtitle: 'Choose your preferred language',
      icon: Icons.language_rounded,
      isDark: isDark,
      trailing: DropdownButton<String>(
        value: provider.language,
        underline: const SizedBox(),
        onChanged: (String? newValue) {
          if (newValue != null) provider.setLanguage(newValue);
        },
        items: const [
          DropdownMenuItem(value: 'en', child: Text('English')),
          DropdownMenuItem(value: 'hi', child: Text('Hindi')),
          DropdownMenuItem(value: 'te', child: Text('Telugu')),
        ],
      ),
    );
  }

  void _handlePinToggle(BuildContext context, InventoryProvider provider, bool value) {
    if (value) {
      _showSetPinDialog(context, provider);
    } else {
      provider.togglePinLock(false);
    }
  }

  void _showSetPinDialog(BuildContext context, InventoryProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set App PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter 4-digit PIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.length == 4) {
                provider.setPin(controller.text);
                provider.togglePinLock(true);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white.withAlpha(128) : Colors.black.withAlpha(128),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 51 : 13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white.withAlpha(153) : Colors.black.withAlpha(153),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
