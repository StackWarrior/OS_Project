import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../state/app_state.dart';
import '../state/shell_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final user = app.currentUser;

    final isEn = app.locale.languageCode == 'en';

    if (user == null) {
      return Center(
        child: FilledButton(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.login,
              (r) => false,
            );
          },
          child: Text(isEn ? 'Sign in' : 'تسجيل الدخول'),
        ),
      );
    }

    final enrolledCount = app.purchasedCourseIds.length;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: user.profileImageUrl.isNotEmpty
                    ? NetworkImage(user.profileImageUrl)
                    : null,
                child: user.profileImageUrl.isEmpty
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w800),
                      )
                    : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: theme.textTheme.headlineSmall),
                    Text(
                      user.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (user.phone.isNotEmpty)
                      Text(
                        user.phone,
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Analytics Cards
          Text(isEn ? 'Learning Progress' : 'تقدم التعلم', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                context,
                isEn ? 'Enrolled' : 'مسجل',
                '$enrolledCount',
                Icons.book_outlined,
                () => context.read<ShellController>().goToTab(2),
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                context,
                isEn ? 'Completed' : 'مكتمل',
                '${app.completedCoursesCount}',
                Icons.check_circle_outline,
                null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                context,
                isEn ? 'Time Spent' : 'الوقت المستغرق',
                isEn ? '${app.totalLearningTime.inHours}h ${app.totalLearningTime.inMinutes % 60}m' : '${app.totalLearningTime.inHours}س ${app.totalLearningTime.inMinutes % 60}د',
                Icons.timer_outlined,
                null,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                context,
                isEn ? 'Avg. Progress' : 'متوسط التقدم',
                '${(app.overallProgress * 100).toInt()}%',
                Icons.analytics_outlined,
                null,
              ),
            ],
          ),

          const SizedBox(height: 24),
          Text(isEn ? 'Account' : 'الحساب', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),

          _buildActionCard(
            context,
            isEn ? 'Edit Profile' : 'تعديل الملف الشخصي',
            isEn ? 'Update your personal info' : 'تحديث معلوماتك الشخصية',
            Icons.person_outline,
            () => Navigator.pushNamed(context, AppRoutes.editProfile),
          ),
          _buildActionCard(
            context,
            isEn ? 'Language' : 'اللغة',
            isEn ? 'English' : 'العربية',
            Icons.translate,
            () => app.toggleLanguage(),
          ),
          _buildActionCard(
            context,
            isEn ? 'Payment Methods' : 'طرق الدفع',
            isEn ? 'Manage cards and payments' : 'إدارة البطاقات والمدفوعات',
            Icons.credit_card_outlined,
            () => Navigator.pushNamed(context, AppRoutes.paymentMethods),
          ),
          _buildActionCard(
            context,
            isEn ? 'Favorites' : 'المفضلة',
            isEn ? '${app.favoriteCourseIds.length} courses saved' : 'تم حفظ ${app.favoriteCourseIds.length} دورة',
            Icons.favorite_border,
            () => context.read<ShellController>().goToTab(3),
          ),

          if (user.dateOfBirth != null) ...[
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.cake_outlined),
              title: Text(isEn ? 'Birthday' : 'تاريخ الميلاد'),
              subtitle: Text(DateFormat(isEn ? 'MMMM dd, yyyy' : 'dd MMMM yyyy', isEn ? 'en' : 'ar').format(user.dateOfBirth!)),
            ),
          ],

          const SizedBox(height: 32),
          if (user.isAdmin) ...[
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.admin);
              },
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: Text(isEn ? 'Admin Dashboard' : 'لوحة تحكم المسؤول'),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: () async {
              await app.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (r) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: Text(isEn ? 'Sign Out' : 'تسجيل الخروج'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value,
      IconData icon, VoidCallback? onTap) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(height: 8),
                Text(value, style: theme.textTheme.titleLarge),
                Text(label, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle,
      IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}
