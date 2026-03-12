import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note.dart';
import '../services/auth_service.dart';
import '../services/storage.dart';
import '../widgets/note_card.dart';
import 'edit_screen.dart';

class HomeScreen extends StatefulWidget {
  final String studentName;
  final String studentId;
  const HomeScreen({super.key, required this.studentName, required this.studentId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> _notes = [];
  String _query = '';

  Future<void> _signOut() async {
    await AuthService.signOut();
  }

  @override
  void initState() {
    super.initState();
    Storage.notesNotifier.addListener(_onNotes);
    _notes = Storage.notesNotifier.value;
  }

  void _onNotes() {
    setState(() {
      _notes = Storage.notesNotifier.value;
    });
  }

  @override
  void dispose() {
    Storage.notesNotifier.removeListener(_onNotes);
    super.dispose();
  }

  List<Note> get _filtered {
    if (_query.isEmpty) return _notes;
    final q = _query.toLowerCase();
    return _notes.where((n) => n.title.toLowerCase().contains(q)).toList();
  }

  Future<void> _confirmDelete(BuildContext ctx, Note note) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa ghi chú này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok == true) await Storage.delete(note);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart Note - ${widget.studentName} - ${widget.studentId}'),
            if (user?.email != null)
              Text(
                user!.email!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Tìm kiếm theo tiêu đề',
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.note, size: 120, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text('Bạn chưa có ghi chú nào, hãy tạo mới nhé!', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    )
                  : MasonryGridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final note = _filtered[index];
                        return Dismissible(
                          key: ValueKey(note.id),
                          direction: DismissDirection.endToStart,
                          background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: Colors.red, child: const Icon(Icons.delete, color: Colors.white)),
                          confirmDismiss: (_) async {
                            await _confirmDelete(context, note);
                            return false;
                          },
                          child: NoteCard(
                            note: note,
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => EditScreen(note: note)));
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newNote = Note.createNew();
          await Navigator.push(context, MaterialPageRoute(builder: (_) => EditScreen(note: newNote, isNew: true)));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
