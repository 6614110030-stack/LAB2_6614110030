import 'dart:io';

import 'package:task_manager/task_manager.dart';
import 'package:task_manager/task.dart';
import 'package:task_manager/exceptions.dart';

// เมนู CLI สำหรับจัดการ Task
// วิธีใช้: จากโฟลเดอร์โปรเจ็กต์ ให้รัน
// dart run bin/menu.dart

void main(List<String> args) async {
  final manager = TaskManager();
  final defaultPath = 'tasks.json';

  print('📋  Task Manager (terminal menu)');

  while (true) {
    print('\n✨ เลือกคำสั่ง: (มี ${manager.allTasks.length} งาน)');
    print('1) ➕  เพิ่ม Task');
    print('2) ✏️  แก้ไข Task');
    print('3) 🔎  ค้นหา Task ตาม title');
    print('4) 🗑️  ลบ Task');
    print('5) 💾  Save (to JSON)');
    print('6) 📂  Load (from JSON)');
    print('0) ❌  ออกจากโปรแกรม');
    stdout.write('> ');
    final input = stdin.readLineSync();
    if (input == null) break;

    switch (input.trim()) {
      case '1':
        await _addTaskInteractive(manager); 
        break;
      case '2':
        await _editTaskInteractive(manager);
        break;
      case '3':
        _searchInteractive(manager);
        break;
      case '4':
        _deleteInteractive(manager);
        break;
      case '5':
        await _saveInteractive(manager, defaultPath);
        break;
      case '6':
        await _loadInteractive(manager, defaultPath);
        break;
      case '0':
        print('Bye');
        return;
      default:
        print('คำสั่งไม่ถูกต้อง');
    }
  }
}

String _prompt(String label, {String? defaultValue}) {
  stdout.write('$label${defaultValue != null ? ' [$defaultValue]' : ''}: ');
  final line = stdin.readLineSync();
  if (line == null) return defaultValue ?? '';
  if (line.trim().isEmpty) return defaultValue ?? '';
  return line.trim();
}

DateTime? _promptDate(String label) {
  final input = _prompt(label + ' (YYYY-MM-DD) หรือเว้นว่าง');
  if (input.isEmpty) return null;
  try {
    return DateTime.parse(input);
  } catch (_) {
    print('รูปแบบวันที่ไม่ถูกต้อง, ข้ามการตั้ง due date');
    return null;
  }
}

Future<void> _addTaskInteractive(TaskManager manager) async {
  print('\n--- ➕ เพิ่ม Task ---');
  final id = _prompt('id');
  final title = _prompt('title');
  final description = _prompt('description (optional)');
  final dueDate = _promptDate('dueDate');

  if (id.isEmpty || title.isEmpty) {
    print('⚠️  id และ title ต้องไม่ว่าง');
    return;
  }

  try {
    manager.addTaskOrThrow(Task(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate,
    ));
    print('✅  เพิ่มงานสำเร็จ: $title');
  } on TaskException catch (e) {
    print('ไม่สามารถเพิ่มงานได้: $e');
  } catch (e) {
    print('ข้อผิดพลาด: $e');
  }
}

Future<void> _editTaskInteractive(TaskManager manager) async {
  print('\n--- ✏️ แก้ไข Task ---');
  final id = _prompt('id ของงานที่จะแก้ไข');
  if (id.isEmpty) {
    print('id ต้องไม่ว่าง');
    return;
  }

  final existing = manager.findTaskById(id);
  if (existing == null) {
    print('ไม่พบบงาน id=$id');
    return;
  }

  print('(เว้นว่างเพื่อไม่แก้ไขค่านั้น)');
  final title = _prompt('title', defaultValue: existing.title);
  final description = _prompt('description', defaultValue: existing.description);
  final dueDate = _promptDate('dueDate');
  final isCompletedInput = _prompt('isCompleted (y/n)', defaultValue: existing.isCompleted ? 'y' : 'n');
  final isCompleted = isCompletedInput.toLowerCase().startsWith('y');

  try {
    manager.updateTaskOrThrow(id,
        title: title, description: description, dueDate: dueDate, isCompleted: isCompleted);
    print('✅  อัปเดตงานสำเร็จ');
  } on TaskException catch (e) {
    print('ไม่สามารถอัปเดตงาน: $e');
  } catch (e) {
    print('ข้อผิดพลาด: $e');
  }
}

void _searchInteractive(TaskManager manager) {
  print('\n--- 🔎 ค้นหา Task ตาม title ---');
  final q = _prompt('keyword');
  if (q.isEmpty) {
    print('คำค้นว่าง');
    return;
  }
  final results = manager.searchByTitle(q);
  if (results.isEmpty) {
    print('🔍  ไม่พบงานที่ตรงกับ "$q"');
    return;
  }
  print('✅ พบ ${results.length} งาน:');
  for (var t in results) {
    print('- ${t.id}: ${t.title} (${t.isCompleted ? 'Completed' : 'Pending'})');
  }
}

void _deleteInteractive(TaskManager manager) {
  print('\n--- 🗑️ ลบ Task ---');
  final id = _prompt('id ของงานที่จะลบ');
  if (id.isEmpty) {
    print('id ต้องไม่ว่าง');
    return;
  }
  try {
    manager.removeTaskOrThrow(id);
    print('✅  ลบงานสำเร็จ');
  } on TaskException catch (e) {
    print('ไม่สามารถลบงาน: $e');
  } catch (e) {
    print('ข้อผิดพลาด: $e');
  }
}

Future<void> _saveInteractive(TaskManager manager, String path) async {
  print('\n--- 💾 Save Tasks ---');
  final p = _prompt('path', defaultValue: path);
  try {
    await manager.saveToFile(p);
    print('✅  บันทึกไฟล์สำเร็จ: $p');
  } on TaskException catch (e) {
    print('ไม่สามารถบันทึกได้: $e');
  } on Exception catch (e) {
    print('ข้อผิดพลาดขณะบันทึก: $e');
  }
}

Future<void> _loadInteractive(TaskManager manager, String path) async {
  print('\n--- 📂 Load Tasks ---');
  final p = _prompt('path', defaultValue: path);
  try {
    await manager.loadFromFile(p);
    print('✅  โหลดไฟล์สำเร็จ: ${manager.allTasks.length} งาน');
  } on TaskException catch (e) {
    print('ไม่สามารถโหลดได้: $e');
  } on Exception catch (e) {
    print('ข้อผิดพลาดขณะโหลด: $e');
  }
}
