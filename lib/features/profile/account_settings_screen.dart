// lib/features/profile/account_settings_screen.dart
//
// Halaman Pengaturan Akun — TERPISAH dari Edit Profile.
// Berisi: ubah email, ubah password, notifikasi, privasi, nonaktifkan/hapus akun.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_client.dart';
import '../../core/network/auth_storage.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/permission_service.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/app_widgets.dart';
import 'edit_profile_screen.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  final UserModel user;
  const AccountSettingsScreen({super.key, required this.user});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  // ── Email change ──────────────────────────────────────────────────────────
  bool _savingEmail = false;

  // ── Password change ────────────────────────────────────────────────────────
  bool _savingPassword = false;

  // ── Notification prefs ─────────────────────────────────────────────────────
  bool _notifEnabled = true;
  bool _loadingNotifState = true;

  @override
  void initState() {
    super.initState();
    _loadNotifState();
  }

  Future<void> _loadNotifState() async {
    final has = await NotificationService.instance.hasPermission();
    if (mounted)
      setState(() {
        _notifEnabled = has;
        _loadingNotifState = false;
      });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade700 : null,
    ));
  }

  // ── Email ──────────────────────────────────────────────────────────────────

  Future<void> _showChangeEmailDialog() async {
    final ctrl = TextEditingController(text: widget.user.email);
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ubah Email'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email baru',
              hintText: 'contoh@email.com',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
              if (!v.contains('@')) return 'Format email tidak valid';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final newEmail = ctrl.text.trim();
    if (newEmail == widget.user.email) return;

    setState(() => _savingEmail = true);
    try {
      await ApiClient.patch<Map<String, dynamic>>(
        '/api/users/profile',
        data: {'email': newEmail},
      );
      _showSnack('Email berhasil diperbarui. Cek inbox untuk konfirmasi.');
    } catch (e) {
      _showSnack('Gagal mengubah email: $e', error: true);
    } finally {
      if (mounted) setState(() => _savingEmail = false);
    }
  }

  // ── Password ───────────────────────────────────────────────────────────────

  Future<void> _showChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Ubah Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentCtrl,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Password saat ini',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setDlgState(() => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newCtrl,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Password baru',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setDlgState(() => obscureNew = !obscureNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    if (v.length < 8) return 'Minimal 8 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi password baru',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setDlgState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    if (v != newCtrl.text) return 'Password tidak cocok';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.pop(ctx, true);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _savingPassword = true);
    try {
      await ApiClient.patch<Map<String, dynamic>>(
        '/api/auth/change-password',
        data: {
          'current_password': currentCtrl.text,
          'new_password': newCtrl.text,
        },
      );
      _showSnack('Password berhasil diubah.');
    } catch (e) {
      _showSnack('Gagal mengubah password: $e', error: true);
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  // ── Notification toggle ────────────────────────────────────────────────────

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      // Minta izin lagi atau buka setelan
      final status = await NotificationService.instance.requestPermission();
      if (status == NotificationPermissionStatus.granted) {
        setState(() => _notifEnabled = true);
        _showSnack('Notifikasi diaktifkan.');
      } else {
        // Arahkan ke setelan sistem
        _showSnack('Buka Setelan untuk mengaktifkan notifikasi.');
        await NotificationService.instance.openSystemNotificationSettings();
        final has = await NotificationService.instance.hasPermission();
        if (mounted) setState(() => _notifEnabled = has);
      }
    } else {
      // Arahkan ke setelan untuk menonaktifkan
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Nonaktifkan Notifikasi'),
          content: const Text(
            'Untuk menonaktifkan notifikasi, buka Setelan perangkat '
            '→ Ada Titik! → Notifikasi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              child: const Text('Buka Setelan'),
            ),
          ],
        ),
      );
      if (ok == true) {
        await NotificationService.instance.openSystemNotificationSettings();
        final has = await NotificationService.instance.hasPermission();
        if (mounted) setState(() => _notifEnabled = has);
      }
    }
  }

  // ── Deactivate / Delete ────────────────────────────────────────────────────

  Future<void> _confirmDeactivate() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nonaktifkan Akun'),
        content: const Text(
          'Akun Anda akan dinonaktifkan sementara. '
          'Anda bisa mengaktifkannya kembali dengan login. '
          'Lanjutkan?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await ApiClient.patch<Map<String, dynamic>>(
        '/api/users/deactivate',
        data: {},
      );
      await AuthStorage.clear();
      ref.invalidate(authProvider);
      if (mounted) context.go('/login');
    } catch (e) {
      _showSnack('Gagal menonaktifkan akun: $e', error: true);
    }
  }

  Future<void> _confirmDelete() async {
    // Double confirmation untuk hapus akun
    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Hapus Akun'),
          ],
        ),
        content: const Text(
          'Tindakan ini TIDAK DAPAT DIBATALKAN.\n\n'
          'Semua data Anda termasuk riwayat donasi, postingan, '
          'dan poin akan dihapus permanen.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );

    if (step1 != true) return;

    // Konfirmasi kedua: ketik "HAPUS"
    final confirmCtrl = TextEditingController();
    final step2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Akhir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ketik HAPUS untuk mengkonfirmasi penghapusan akun:'),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              decoration: const InputDecoration(
                hintText: 'HAPUS',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (confirmCtrl.text.trim().toUpperCase() == 'HAPUS') {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content: Text('Ketik HAPUS dengan huruf besar')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );

    if (step2 != true) return;
    try {
      await ApiClient.delete<Map<String, dynamic>>('/api/users/account');
      await AuthStorage.clear();
      ref.invalidate(authProvider);
      if (mounted) context.go('/login');
    } catch (e) {
      _showSnack('Gagal menghapus akun: $e', error: true);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Pengaturan Akun', style: AppTextStyles.headlineSmall),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profil cepat ────────────────────────────────────────────────
            _SectionHeader(label: 'Profil'),
            _SettingsTile(
              icon: Icons.person_outline_rounded,
              title: 'Edit Profil',
              subtitle: 'Ubah nama, bio, dan foto profil',
              onTap: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (_) => EditProfileScreen(user: widget.user),
                );
                if (result == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profil berhasil diperbarui')),
                  );
                }
              },
            ),

            // ── Keamanan ────────────────────────────────────────────────────
            _SectionHeader(label: 'Keamanan'),
            _SettingsTile(
              icon: Icons.email_outlined,
              title: 'Alamat Email',
              subtitle: widget.user.email,
              trailing: _savingEmail
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
              onTap: _savingEmail ? null : _showChangeEmailDialog,
            ),
            _SettingsTile(
              icon: Icons.lock_outline_rounded,
              title: 'Ubah Password',
              subtitle: 'Ganti password akun Anda',
              trailing: _savingPassword
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
              onTap: _savingPassword ? null : _showChangePasswordDialog,
            ),

            // ── Notifikasi ──────────────────────────────────────────────────
            _SectionHeader(label: 'Notifikasi'),
            _SettingsTileSwitch(
              icon: Icons.notifications_outlined,
              title: 'Notifikasi Push',
              subtitle: 'Terima update donasi, pesan, dan aktivitas',
              value: _notifEnabled,
              loading: _loadingNotifState,
              onChanged: _toggleNotifications,
            ),
            _SettingsTile(
              icon: Icons.settings_outlined,
              title: 'Setelan Notifikasi Sistem',
              subtitle: 'Buka pengaturan notifikasi di perangkat',
              onTap: () =>
                  NotificationService.instance.openSystemNotificationSettings(),
            ),

            // ── Privasi ──────────────────────────────────────────────────────
            _SectionHeader(label: 'Privasi'),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Kebijakan Privasi',
              subtitle: 'Bagaimana kami menggunakan data Anda',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Akan diarahkan ke halaman kebijakan privasi')),
                );
              },
            ),

            // ── Akun ────────────────────────────────────────────────────────
            _SectionHeader(label: 'Akun'),
            _SettingsTile(
              icon: Icons.pause_circle_outline_rounded,
              title: 'Nonaktifkan Akun',
              subtitle: 'Akun bisa diaktifkan kembali kapan saja',
              iconColor: Colors.orange,
              onTap: _confirmDeactivate,
            ),
            _SettingsTile(
              icon: Icons.delete_outline_rounded,
              title: 'Hapus Akun',
              subtitle: 'Hapus permanen semua data Anda',
              iconColor: Colors.red,
              titleColor: Colors.red,
              isDestructive: true,
              onTap: _confirmDelete,
            ),
            const SizedBox(height: 32),

            // Versi aplikasi
            Center(
              child: Text(
                'Ada Titik! v1.0.0',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.captionUppercase.copyWith(
          color: AppColors.textSecondary,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final Color? titleColor;
  final bool isDestructive;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.titleColor,
    this.isDestructive = false,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor =
        iconColor ?? (isDestructive ? Colors.red : AppColors.textSecondary);
    final effectiveTitleColor =
        titleColor ?? (isDestructive ? Colors.red : AppColors.textPrimary);

    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: effectiveIconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: effectiveIconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: effectiveTitleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTileSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool loading;
  final void Function(bool) onChanged;

  const _SettingsTileSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (loading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
