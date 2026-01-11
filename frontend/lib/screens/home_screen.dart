import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/gradient_background.dart';
import '../services/journal_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/sync_service.dart';
import '../main.dart';
import '../widgets/responsive_container.dart';
import 'journal_entry_screen.dart';
import 'progress_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _sidebarOpen = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const JournalListView(),
    const JournalEntryNavigator(),
    const ProgressContent(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = isDesktopLayout(context);

    if (isDesktop) {
      return _buildDesktopLayout(context);
    }

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: Drawer(
        elevation: 0,
        backgroundColor: const Color(0xFF0A0E12),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.headlineSmall?.color ?? Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.bug_report, color: Colors.orange),
                      tooltip: 'Debug Info',
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed('/debug');
                      },
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              ListTile(
                leading: Icon(Icons.person_outline, color: Colors.grey.shade300),
                title: Text('Profile & Goals', style: TextStyle(color: Colors.grey.shade300, fontSize: 18)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              ListTile(
                leading: Icon(Icons.notifications_outlined, color: Colors.grey.shade300),
                title: Text('Notifications', style: TextStyle(color: Colors.grey.shade300, fontSize: 18)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/notification-settings');
                },
              ),
              const Spacer(),
              const Divider(color: Colors.white12, height: 1),
              Consumer<AuthService>(
                builder: (context, authService, _) {
                  return FutureBuilder<String?>(
                    future: authService.tokenStorage.getAccessToken(),
                    builder: (context, snapshot) {
                      final hasToken = snapshot.data != null;
                      
                      if (!hasToken) {
                        return ListTile(
                          leading: const Icon(Icons.login, color: Colors.green),
                          title: const Text('Login with Auth0', style: TextStyle(color: Colors.green, fontSize: 18)),
                          subtitle: const Text('Required for cloud sync', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          onTap: () async {
                            Navigator.pop(context);
                            try {
                              await authService.login(scheme: 'selfupgrade');
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Login failed: $e')),
                                );
                              }
                            }
                          },
                        );
                      }
                      
                      return ListTile(
                        leading: Icon(Icons.logout, color: Colors.grey.shade300),
                        title: Text('Logout', style: TextStyle(color: Colors.grey.shade300, fontSize: 18)),
                        onTap: () async {
                          await authService.logout();
                          
                          await UserService.deleteCurrent();
                          
                          if (context.mounted && Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                          
                          if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                              (route) => false,
                            );
                          }
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      appBar: _selectedIndex == 2 ? null : AppBar(
        title: const Text('SelfUpgrade'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _scaffoldKey.currentState!.openEndDrawer();
            },
          ),
        ],
      ),
      body: GradientBackground(
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        indicatorColor: const Color(0xFF4CEEBB),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/journal-entry').then((_) {
              setState(() {
                _selectedIndex = 0;
              });
            });
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.home, color: Color(0xFF0A0E10)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.edit, color: Color(0xFF0A0E10)),
            label: 'New Entry',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.show_chart, color: Color(0xFF0A0E10)),
            label: 'Progress',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 ? Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(78,244,192,0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Offstage(
          offstage: _selectedIndex != 0,
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(context, '/journal-entry');
            },
            icon: const Icon(Icons.add),
            label: const Text('New Entry'),
          ),
        ),
      ) : null,
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      floatingActionButton: _selectedIndex == 0 ? Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(78,244,192,0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, '/journal-entry');
          },
          icon: const Icon(Icons.add),
          label: const Text('New Entry'),
        ),
      ) : null,
      body: Stack(
        children: [
          Row(
            children: [
          // Settings sidebar (pushes content when open)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _sidebarOpen ? 280 : 0,
            child: _sidebarOpen
                ? Container(
                    color: const Color(0xFF0A0E10),
                    child: SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                            child: Row(
                              children: [
                                Text(
                                  'Settings',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.headlineSmall?.color ?? Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.bug_report, color: Colors.orange),
                                  tooltip: 'Debug Info',
                                  onPressed: () {
                                    setState(() => _sidebarOpen = false);
                                    Navigator.of(context).pushNamed('/debug');
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Divider(color: Colors.white12, height: 1),
                          ListTile(
                            leading: Icon(Icons.person_outline, color: Colors.grey.shade300),
                            title: Text('Profile & Goals', style: TextStyle(color: Colors.grey.shade300, fontSize: 18)),
                            onTap: () {
                              setState(() => _sidebarOpen = false);
                              Navigator.pushNamed(context, '/profile');
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.notifications_outlined, color: Colors.grey.shade300),
                            title: Text('Notifications', style: TextStyle(color: Colors.grey.shade300, fontSize: 18)),
                            onTap: () {
                              setState(() => _sidebarOpen = false);
                              Navigator.pushNamed(context, '/notification-settings');
                            },
                          ),
                          const Spacer(),
                          const Divider(color: Colors.white12, height: 1),
                          Consumer<AuthService>(
                            builder: (context, authService, _) {
                              return FutureBuilder<String?>(
                                future: authService.tokenStorage.getAccessToken(),
                                builder: (context, snapshot) {
                                  final hasToken = snapshot.data != null;

                                  if (!hasToken) {
                                    return ListTile(
                                      leading: const Icon(Icons.login, color: Colors.green),
                                      title: const Text('Login with Auth0', style: TextStyle(color: Colors.green, fontSize: 18)),
                                      subtitle: const Text('Required for cloud sync', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                      onTap: () async {
                                        setState(() => _sidebarOpen = false);
                                        try {
                                          await authService.login(scheme: 'selfupgrade');
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Login failed: $e')),
                                            );
                                          }
                                        }
                                      },
                                    );
                                  }

                                  return ListTile(
                                    leading: Icon(Icons.logout, color: Colors.grey.shade300),
                                    title: Text('Logout', style: TextStyle(color: Colors.grey.shade300, fontSize: 18)),
                                    onTap: () async {
                                      await authService.logout();

                                      await UserService.deleteCurrent();

                                      setState(() => _sidebarOpen = false);

                                      if (context.mounted) {
                                        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                                          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                                          (route) => false,
                                        );
                                      }
                                    },
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (_sidebarOpen) const VerticalDivider(thickness: 1, width: 1, color: Colors.white12),
          // Side navigation
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              if (index == 1) {
                Navigator.pushNamed(context, '/journal-entry').then((_) {
                  setState(() {
                    _selectedIndex = 0;
                  });
                });
              } else {
                setState(() {
                  _selectedIndex = index;
                });
              }
            },
            backgroundColor: const Color(0xFF0A0E10),
            labelType: NavigationRailLabelType.all,
            indicatorColor: const Color(0xFF4CEEBB),
            selectedIconTheme: const IconThemeData(
              color: Color(0xFF0A0E10),
            ),
            unselectedIconTheme: const IconThemeData(
              color: Colors.grey,
            ),
            selectedLabelTextStyle: const TextStyle(
              color: Color(0xFF4CEEBB),
            ),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: IconButton(
                icon: Icon(_sidebarOpen ? Icons.close : Icons.settings),
                onPressed: () {
                  setState(() => _sidebarOpen = !_sidebarOpen);
                },
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.edit_outlined),
                selectedIcon: Icon(Icons.edit),
                label: Text('New Entry'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.show_chart_outlined),
                selectedIcon: Icon(Icons.show_chart),
                label: Text('Progress'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main content
          Expanded(
            child: Stack(
              children: [
                GradientBackground(
                  child: ResponsiveContainer(
                    maxWidth: 1200,
                    child: _screens[_selectedIndex],
                  ),
                ),
                // Refresh button for desktop
                if (_selectedIndex == 0)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: FloatingActionButton.small(
                      onPressed: () async {
                        final authService = Provider.of<AuthService>(context, listen: false);
                        if (authService.apiService != null) {
                          SyncService.initialize(authService.apiService!);
                          await SyncService.pullFromServer();
                          if (mounted) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Data refreshed'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        }
                      },
                      tooltip: 'Refresh data',
                      child: const Icon(Icons.refresh),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}


class JournalListView extends StatefulWidget {
  const JournalListView({super.key});

  @override
  State<JournalListView> createState() => _JournalListViewState();
}

class _JournalListViewState extends State<JournalListView> {
  Future<void> _refreshData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.apiService != null) {
      SyncService.initialize(authService.apiService!);
      await SyncService.pullFromServer();
      // Trigger a rebuild by calling setState if mounted
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _getFormattedDate(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                ValueListenableBuilder(
                  valueListenable: JournalService.listenable(),
                  builder: (context, box, _) {
              final entries = box.values.toList().cast().toList();

              DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

              final totalEntries = entries.length;

              final today = dateOnly(DateTime.now());
              final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
              final entriesThisWeek = entries.where((e) => dateOnly(e.createdAt).isAtSameMomentAs(startOfWeek) || dateOnly(e.createdAt).isAfter(startOfWeek)).length;

              final dateSet = <DateTime>{};
              for (final e in entries) {
                dateSet.add(dateOnly(e.createdAt));
              }
              int streak = 0;
              if (dateSet.isNotEmpty) {
                final latest = dateSet.reduce((a, b) => a.isAfter(b) ? a : b);
                var cursor = latest;
                while (dateSet.contains(cursor)) {
                  streak += 1;
                  cursor = cursor.subtract(const Duration(days: 1));
                }
              }

              final streakLabel = '$streak ${streak == 1 ? 'day' : 'days'}';

              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.book_outlined,
                      label: 'Entries',
                      value: totalEntries.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.calendar_today_outlined,
                      label: 'This Week',
                      value: entriesThisWeek.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.local_fire_department_outlined,
                      label: 'Streak',
                      value: streakLabel,
                    ),
                  ),
                ],
              );
            },
          ),

                const SizedBox(height: 24),

                ValueListenableBuilder(
                  valueListenable: JournalService.listenable(),
                  builder: (context, box, _) {
              final entries = box.values.toList().reversed.toList();
              if (entries.isEmpty) {
                return SizedBox(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary.withAlpha((0.5 * 255).round()),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No entries yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start your journaling journey today!',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final e = entries[idx];
                    final content = e.content;
                    final lines = content.split('\n');
                    final title = (lines.isNotEmpty && lines.first.trim().isNotEmpty)
                        ? lines.first.trim()
                        : '(No title)';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => JournalEntryScreen(entryId: e.id)),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0E10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color.fromRGBO(255,255,255,0.04)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      e.createdAt.toLocal().toString(),
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: const Color(0xFF0A0E12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Text('Delete Entry', style: TextStyle(color: Colors.white)),
                                      content: const Text(
                                        'Are you sure you want to delete this entry?',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  
                                  if (confirm == true) {
                                    await JournalService.delete(e.id);
                                    await SyncService.deleteJournalEntry(e.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromRGBO(255,255,255,0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ) ?? const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

class JournalEntryNavigator extends StatelessWidget {
  const JournalEntryNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}


