// สคริปต์ CLI ตัวอย่างสำหรับรัน Task Manager
// คำอธิบายสั้น ๆ:
// - แสดงการใช้งาน `TaskManager` และชนิดของ `Task` (Regular, Priority, Recurring)
// - โหลด/บันทึกงานผ่าน `TaskStorage` (ไฟล์ JSON) โดยใช้ async/await
// - แสดงตัวอย่างการจัดการงานและสถิติ
// หมายเหตุ: ในโครงสร้างแพ็กเกจที่แท้จริง ควร import ไลบรารีจาก `package:` เช่น
// `import 'package:task_manager/task_manager.dart';` แทนการใช้ relative path
import 'dart:io';
import '../lib/task_manager.dart';
import '../lib/task.dart';
import '../lib/storage.dart';
import '../lib/exceptions.dart';
import '../lib/result.dart';

// จุดเริ่มต้นของโปรแกรม (main) ทำเป็น async เพื่อใช้ await
Future<void> main(List<String> arguments) async {
  print('Welcome to Task Manager CLI!');
  await runApp();
}

// runApp: ตัวอย่างการไหลของแอปพลิเคชัน
// - สร้าง TaskManager และ TaskStorage
// - โหลดงานจาก storage หากมี
// - ถ้าไม่มีงาน จะเพิ่มตัวอย่างงานเข้าไป
// - แสดงรายการงานทั้งหมด และบันทึกกลับไปยัง storage
Future<void> runApp() async {
  final manager = TaskManager();

  print('\n--- Testing Result Pattern ---');

  // Test successful operation
  final result1 = manager.addTaskSafe(Task(id: '1', title: 'Learn Generics'));

  result1.onSuccess((task) {
    print('Successfully added: ${task.title}');
  });

  result1.onFailure((error) {
    print('Failed: $error');
  });

  // Test duplicate task
  final result2 = manager.addTaskSafe(Task(id: '1', title: 'Duplicate'));

  result2
    ..onSuccess((task) => print('Added: $task'))
    ..onFailure((error) => print('Error: $error'));

  // Test chaining with map
  final result3 = manager
      .findTaskSafe('1')
      .map((task) => task.title.toUpperCase());

  print('Uppercase title: ${result3.valueOrNull}');

  // Test value extraction
  final taskOrNull = manager.findTaskSafe('1').valueOrNull;
  print('Found task: $taskOrNull');

  final notFoundTask = manager
      .findTaskSafe('999')
      .valueOr(Task(id: 'default', title: 'Default Task'));
  print('Default task: $notFoundTask');
}
