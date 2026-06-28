import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const _primary = Color(0xFF5B52E0);

class EditTaskPage extends StatefulWidget {
  final String docId;
  final String currentTitle;
  final String currentDescription;

  const EditTaskPage({
    super.key,
    required this.docId,
    required this.currentTitle,
    required this.currentDescription,
  });

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  late TextEditingController titleController;
  late TextEditingController descController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.currentTitle);
    descController = TextEditingController(text: widget.currentDescription);
  }

  Future<void> updateTask() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Task title cannot be empty'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.docId)
          .update({
        'title': titleController.text.trim(),
        'description': descController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Task updated!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1a1a1a), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit task',
            style: TextStyle(
                color: Color(0xFF1a1a1a),
                fontSize: 16,
                fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEDEAFF), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Task title',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF444441))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    maxLength: 100,
                    decoration: _deco(hint: 'Task title'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Description',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF444441))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    maxLines: 5,
                    maxLength: 300,
                    decoration: _deco(hint: 'Add details (optional)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : updateTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(isLoading ? 'Saving...' : 'Save changes',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF888780))),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _deco({required String hint}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB4B2A9), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF8F7FF),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFEDEAFF))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFEDEAFF))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _primary, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      );
}