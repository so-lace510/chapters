import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/experience.dart';
import '../models/experience_type.dart';
import '../services/experience_service.dart';
import '../theme.dart';
import '../widgets/timeline_entry.dart';
import 'experience_detail_screen.dart';
import 'new_experience_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = ExperienceService.instance;
  late Future<List<Experience>> _future = _service.fetchAll();
  String _filter = 'All';

  Future<void> _reload() async {
    final f = _service.fetchAll();
    setState(() {
      _future = f;
    });
    try {
      await f;
    } catch (_) {}
  }

  Future<void> _openNew() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NewExperienceScreen()),
    );
    if (saved == true) {
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Experience saved')),
        );
      }
    }
  }

  Future<void> _openDetail(Experience e) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => ExperienceDetailScreen(experience: e)),
    );
    if (result == 'deleted') {
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Experience deleted')),
        );
      }
    }
  }

  String get _name {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    final n = email.split('@').first;
    return n.isEmpty ? 'there' : n;
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  bool _matches(Experience e) {
    if (_filter == 'All') return true;
    if (_filter == otherLabel) return !isPresetTitle(e.title);
    return e.title == _filter;
  }

  List<Object> _withMonthHeaders(List<Experience> list) {
    final items = <Object>[];
    String? month;
    for (final e in list) {
      final m = DateFormat('MMMM y').format(e.happenedOn);
      if (m != month) {
        items.add(m);
        month = m;
      }
      items.add(e);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNew,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New experience',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Experience>>(
          future: _future,
          builder: (context, snap) {
            final loading = snap.connectionState != ConnectionState.done;
            final all = snap.data ?? const <Experience>[];
            final filtered = all.where(_matches).toList();

            return RefreshIndicator(
              onRefresh: _reload,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _header(context)),
                  if (snap.hasError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _message(
                        icon: Icons.cloud_off_rounded,
                        title: 'Couldn\'t load your experiences',
                        body: 'Check your connection, then try again.',
                        action: 'Try again',
                        onAction: _reload,
                      ),
                    )
                  else if (loading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    if (all.isNotEmpty) SliverToBoxAdapter(child: _stats(all)),
                    if (all.isNotEmpty) SliverToBoxAdapter(child: _filters()),
                    if (all.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _message(
                          icon: Icons.auto_stories_rounded,
                          title: 'Your story starts here',
                          body:
                              'Add your first experience: a win, a rough day, '
                              'or just an ordinary one.',
                          action: 'New experience',
                          onAction: _openNew,
                        ),
                      )
                    else if (filtered.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _message(
                          icon: Icons.search_off_rounded,
                          title: 'Nothing under "$_filter" yet',
                          body: 'Pick another filter or add a new experience.',
                        ),
                      )
                    else
                      _timeline(filtered),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_greeting, $_name.', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  'Everything here is private to you.',
                  style: AppTheme.serif(
                    size: 16.5,
                    color: AppColors.muted,
                    style: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined, size: 28),
            onSelected: (v) {
              if (v == 'signout') Supabase.instance.client.auth.signOut();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'signout', child: Text('Sign out')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stats(List<Experience> all) {
    final now = DateTime.now();
    final wins =
        all.where((e) => e.title == 'Big win' || e.title == 'Small win').length;
    final thisMonth = all
        .where((e) =>
            e.happenedOn.year == now.year && e.happenedOn.month == now.month)
        .length;

    Widget stat(int n, String label) => Expanded(
          child: Column(
            children: [
              Text('$n', style: AppTheme.serif(size: 34, weight: FontWeight.w500, height: 1.1)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ],
          ),
        );
    const divider = SizedBox(
      height: 38,
      child: VerticalDivider(width: 1, color: AppColors.line),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
      child: Row(
        children: [
          stat(all.length, 'experiences'),
          divider,
          stat(wins, 'wins'),
          divider,
          stat(thisMonth, 'this month'),
        ],
      ),
    );
  }

  Widget _filters() {
    final chips = ['All', ...experienceTypes.map((t) => t.label)];
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final label = chips[i];
          final selected = _filter == label;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => setState(() => _filter = label),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.line),
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
    );
  }

  Widget _timeline(List<Experience> list) {
    final items = _withMonthHeaders(list);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 110),
      sliver: SliverList.builder(
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          if (item is String) {
            return Padding(
              padding: EdgeInsets.fromLTRB(6, i == 0 ? 8 : 20, 0, 14),
              child: Text(
                item,
                style: AppTheme.serif(
                  size: 22,
                  style: FontStyle.italic,
                  color: AppColors.primary,
                ),
              ),
            );
          }
          final e = item as Experience;
          return TimelineEntry(experience: e, onTap: () => _openDetail(e));
        },
      ),
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String body,
    String? action,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 46, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTheme.serif(size: 17, color: AppColors.muted),
          ),
          if (action != null) ...[
            const SizedBox(height: 22),
            SizedBox(
              width: 220,
              child: FilledButton(onPressed: onAction, child: Text(action)),
            ),
          ],
        ],
      ),
    );
  }
}
