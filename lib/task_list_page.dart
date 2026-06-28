import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_task_page.dart';
import 'edit_task_page.dart';

const _primary = Color(0xFF5B52E0);
const _bgPage = Color(0xFFF8F7FF);

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteTask(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('tasks').doc(docId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task deleted'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _toggleDone(String docId, bool currentDone) async {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(docId)
        .update({'done': !currentDone});
  }

  String _initials(String? email) {
    if (email == null || email.isEmpty) return '?';
    return email[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _bgPage,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('uid', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          final allDocs = snapshot.data?.docs ?? [];

          // Filter by search
          final filtered = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] ?? '').toString().toLowerCase();
            final desc = (data['description'] ?? '').toString().toLowerCase();
            return title.contains(_searchQuery) ||
                desc.contains(_searchQuery);
          }).toList();

          final activeDocs =
              filtered.where((d) => !((d.data() as Map)['done'] == true)).toList();
          final doneDocs =
              filtered.where((d) => (d.data() as Map)['done'] == true).toList();

          return CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                backgroundColor: _primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: _primary,
                    padding: const EdgeInsets.fromLTRB(20, 52, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Welcome back 👋',
                                    style: TextStyle(
                                        color: Colors.white60, fontSize: 12)),
                                const SizedBox(height: 2),
                                const Text('My Tasks',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            // Avatar + logout
                            GestureDetector(
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    title: const Text('Log out'),
                                    content: const Text(
                                        'Are you sure you want to log out?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Log out',
                                            style: TextStyle(
                                                color: Colors.redAccent)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await FirebaseAuth.instance.signOut();
                                }
                              },
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    Colors.white.withOpacity(0.2),
                                child: Text(
                                  _initials(user?.email),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Search bar
                        Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                            onChanged: (v) =>
                                setState(() => _searchQuery = v.toLowerCase()),
                            decoration: InputDecoration(
                              hintText: 'Search tasks...',
                              hintStyle:
                                  TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                              prefixIcon: Icon(Icons.search,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 18),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Stat Cards ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      _StatCard(
                          number: allDocs.length,
                          label: 'Total',
                          color: _primary),
                      const SizedBox(width: 10),
                      _StatCard(
                          number: activeDocs.length,
                          label: 'Active',
                          color: const Color(0xFFE24B4A)),
                      const SizedBox(width: 10),
                      _StatCard(
                          number: doneDocs.length,
                          label: 'Done',
                          color: const Color(0xFF3B6D11)),
                    ],
                  ),
                ),
              ),

              // ── Loading / Error / Empty ───────────────────────────
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()))
              else if (snapshot.hasError)
                SliverFillRemaining(
                    child: Center(child: Text('Error: ${snapshot.error}')))
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded,
                            size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 14),
                        Text('No tasks yet',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500)),
                        const SizedBox(height: 6),
                        Text('Tap + to add your first task',
                            style: TextStyle(color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                )
              else ...[
                // ── Active Tasks ──────────────────────────────────
                if (activeDocs.isNotEmpty) ...[
                  _SectionHeader(title: 'Active tasks (${activeDocs.length})'),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final doc = activeDocs[i];
                          final data = doc.data() as Map<String, dynamic>;
                          return _TaskCard(
                            doc: doc,
                            data: data,
                            isDone: false,
                            onToggle: () =>
                                _toggleDone(doc.id, false),
                            onEdit: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditTaskPage(
                                  docId: doc.id,
                                  currentTitle: data['title'] ?? '',
                                  currentDescription:
                                      data['description'] ?? '',
                                ),
                              ),
                            ),
                            onDelete: () => _deleteTask(context, doc.id),
                          );
                        },
                        childCount: activeDocs.length,
                      ),
                    ),
                  ),
                ],

                // ── Done Tasks ────────────────────────────────────
                if (doneDocs.isNotEmpty) ...[
                  _SectionHeader(title: 'Completed (${doneDocs.length})'),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final doc = doneDocs[i];
                          final data = doc.data() as Map<String, dynamic>;
                          return _TaskCard(
                            doc: doc,
                            data: data,
                            isDone: true,
                            onToggle: () =>
                                _toggleDone(doc.id, true),
                            onEdit: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditTaskPage(
                                  docId: doc.id,
                                  currentTitle: data['title'] ?? '',
                                  currentDescription:
                                      data['description'] ?? '',
                                ),
                              ),
                            ),
                            onDelete: () => _deleteTask(context, doc.id),
                          );
                        },
                        childCount: doneDocs.length,
                      ),
                    ),
                  ),
                ],

                // Bottom padding for FAB
                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTaskPage()),
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Task',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Stat Card Widget ──────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final int number;
  final String label;
  final Color color;

  const _StatCard(
      {required this.number, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEDEAFF), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$number',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF888780))),
          ],
        ),
      ),
    );
  }
}

// ── Section Header Widget ─────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5B52E0))),
      ),
    );
  }
}

// ── Task Card Widget ──────────────────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final Map<String, dynamic> data;
  final bool isDone;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.doc,
    required this.data,
    required this.isDone,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'No title';
    final description = data['description'] ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    return Opacity(
      opacity: isDone ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDEAFF), width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: isDone ? _primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: isDone ? _primary : const Color(0xFFC8C3F8),
                        width: 1.5),
                  ),
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDone
                            ? Colors.grey.shade400
                            : const Color(0xFF1a1a1a),
                        decoration: isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                    if (createdAt != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 10, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Text(
                            '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Action buttons
              Column(
                children: [
                  if (!isDone)
                    _ActionBtn(
                      icon: Icons.edit_outlined,
                      bg: const Color(0xFFEDEAFF),
                      iconColor: _primary,
                      onTap: onEdit,
                      tooltip: 'Edit',
                    ),
                  const SizedBox(height: 6),
                  _ActionBtn(
                    icon: Icons.delete_outline,
                    bg: const Color(0xFFFFECEC),
                    iconColor: Colors.redAccent,
                    onTap: onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small Action Button ───────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color iconColor;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionBtn({
    required this.icon,
    required this.bg,
    required this.iconColor,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15, color: iconColor),
        ),
      ),
    );
  }
}