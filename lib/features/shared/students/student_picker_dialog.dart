import 'package:flutter/material.dart';

import '../../../data/models/models.dart';

/// Searchable list of students; returns the chosen one.
Future<User?> showStudentPicker(
  BuildContext context, {
  required List<User> students,
  String title = 'اختر الطالب',
  Map<String, String> subtitles = const {},
}) => showDialog<User>(
  context: context,
  builder: (_) => _StudentPicker(students: students, title: title, subtitles: subtitles),
);

class _StudentPicker extends StatefulWidget {
  const _StudentPicker({required this.students, required this.title, required this.subtitles});

  final List<User> students;
  final String title;
  final Map<String, String> subtitles;

  @override
  State<_StudentPicker> createState() => _StudentPickerState();
}

class _StudentPickerState extends State<_StudentPicker> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final matches = widget.students
        .where((s) => _query.isEmpty || s.name.contains(_query) || s.phone.contains(_query))
        .toList();
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        height: 440,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: const InputDecoration(
                hintText: 'بحث بالاسم أو الموبايل',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, i) {
                  final s = matches[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text(s.name.characters.first)),
                    title: Text(s.name),
                    subtitle: Text(widget.subtitles[s.id] ?? s.phone),
                    onTap: () => Navigator.of(context).pop(s),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
      ],
    );
  }
}
