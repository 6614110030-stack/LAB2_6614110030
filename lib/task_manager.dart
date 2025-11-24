import 'task.dart';
import 'result.dart';
import 'exceptions.dart';
import 'storage.dart';

// ไฟล์นี้เป็นตัวจัดการคอลเลกชันของ `Task` ทั้งหมด
// มีหน้าที่เก็บรายการงาน, ค้นหา, เพิ่ม, ลบ และคำนวณสถิติเกี่ยวกับงาน
/// `TaskManager` ดูแลคอลเลกชันของ `Task` ทั้งหมด
/// - เก็บรายการแบบ internal และมีเมธอดสำหรับเพิ่ม/ลบ/ค้นหา
/// - ให้ getter สำหรับดึงรายการทั้งหมด งานที่ค้าง งานที่เสร็จ และเมธอดสถิติ
class TaskManager {
  // รายการภายในที่เก็บ `Task` ทั้งหมด (เข้าถึงเฉพาะภายในคลาส)
  final List<Task> _tasks = [];

  // แผนที่ช่วยให้ค้นหา task ตาม id ได้เร็วขึ้น
  final Map<String, Task> _taskMap = {};

  // เก็บ id ที่มีอยู่แล้วเพื่อเช็คความซ้ำซ้อน
  final Set<String> _taskIds = {};

  /// คืนรายการ `Task` ทั้งหมด
  /// - คืน `List` ที่ไม่สามารถแก้ไขได้จากภายนอก (เพื่อป้องกันการเปลี่ยนแปลงจากภายนอก)
  List<Task> get allTasks => List.unmodifiable(_tasks);

  /// คืนเฉพาะงานที่ยังไม่เสร็จ (pending)
  List<Task> get pendingTasks =>
      _tasks.where((task) => !task.isCompleted).toList();

  /// คืนเฉพาะงานที่ทำเสร็จแล้ว (completed)
  List<Task> get completedTasks =>
      _tasks.where((task) => task.isCompleted).toList();

  /// เพิ่มงานใหม่ลงใน Manager
  /// - ถ้า `id` ซ้ำ จะไม่เพิ่มและคืน `false`
  /// - ถ้าเพิ่มสำเร็จจะคืน `true`
  bool addTask(Task task) {
    if (_taskIds.contains(task.id)) {
      return false; // id ต้องไม่ซ้ำ
    }

    _tasks.add(task);
    _taskMap[task.id] = task;
    _taskIds.add(task.id);
    return true;
  }

  /// เพิ่มงานแบบที่โยน exception เมื่อเกิดข้อผิดพลาด
  /// - ถ้า `id` ซ้ำ จะโยน `DuplicateTaskException`
  /// - ถ้า `title` ว่าง จะโยน `InvalidTaskDataException`
  void addTaskOrThrow(Task task) {
    if (_taskIds.contains(task.id)) {
      throw DuplicateTaskException(task.id);
    }

    // ตรวจสอบความถูกต้องของข้อมูลงาน
    if (task.title.trim().isEmpty) {
      throw InvalidTaskDataException('title', 'Title cannot be empty');
    }

    _tasks.add(task);
    _taskMap[task.id] = task;
    _taskIds.add(task.id);
  }

  /// เพิ่มงานแบบปลอดภัยที่คืนค่า `Result` แทนการโยน exception
  /// - คืน `Success<Task>` เมื่อเพิ่มสำเร็จ
  /// - คืน `Failure` เมื่อเกิดปัญหา (id ซ้ำ หรือข้อมูลไม่ถูกต้อง)
  Result<Task> addTaskSafe(Task task) {
    try {
      if (_taskIds.contains(task.id)) {
        return Failure('Task with ID "${task.id}" already exists');
      }

      if (task.title.trim().isEmpty) {
        return Failure('Task title cannot be empty');
      }

      _tasks.add(task);
      _taskMap[task.id] = task;
      _taskIds.add(task.id);
      return Success(task);
    } catch (e) {
      return Failure('Failed to add task: $e');
    }
  }

  /// แก้ไขข้อมูลของงานโดยใช้ id
  /// - ถ้าไม่พบงานจะคืนค่า false
  /// - ถ้าแก้ไขสำเร็จจะคืนค่า true
  /// ตัวอย่างการใช้งาน: `updateTask('1', title: 'New title')`
  bool updateTask(
    String id, {
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    final task = _taskMap[id];
    if (task == null) return false;

    if (title != null) task.title = title;
    if (description != null) task.description = description;
    if (dueDate != null) task.dueDate = dueDate;
    if (isCompleted != null) task.isCompleted = isCompleted;
    return true;
  }

  /// แก้ไขข้อมูลของงานแล้วโยน exception หากไม่พบหรือข้อมูลไม่ถูกต้อง
  /// - ถ้าไม่พบจะโยน `TaskNotFoundException`
  /// - ถ้าข้อมูลไม่ถูกต้อง (เช่น title ว่าง) จะโยน `InvalidTaskDataException`
  void updateTaskOrThrow(
    String id, {
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    final task = _taskMap[id];
    if (task == null) throw TaskNotFoundException(id);

    if (title != null && title.trim().isEmpty) {
      throw InvalidTaskDataException('title', 'Title cannot be empty');
    }

    if (title != null) task.title = title;
    if (description != null) task.description = description;
    if (dueDate != null) task.dueDate = dueDate;
    if (isCompleted != null) task.isCompleted = isCompleted;
  }

  /// แก้ไขงานแบบปลอดภัยที่คืนค่า `Result` แทนการโยน exception
  Result<Task> updateTaskSafe(
    String id, {
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    try {
      final task = _taskMap[id];
      if (task == null) return Failure('Task with ID "$id" not found');

      if (title != null && title.trim().isEmpty)
        return Failure('Task title cannot be empty');

      if (title != null) task.title = title;
      if (description != null) task.description = description;
      if (dueDate != null) task.dueDate = dueDate;
      if (isCompleted != null) task.isCompleted = isCompleted;
      return Success(task);
    } catch (e) {
      return Failure('Failed to update task: $e');
    }
  }

  /// ลบงานแบบที่โยน exception ถ้าไม่พบงาน
  /// - ถ้า `id` ไม่พบ จะโยน `TaskNotFoundException`
  void removeTaskOrThrow(String id) {
    if (!_taskIds.contains(id)) {
      throw TaskNotFoundException(id);
    }

    final task = _taskMap[id]!;
    _tasks.remove(task);
    _taskMap.remove(id);
    _taskIds.remove(id);
  }

  /// ลบงานแบบปลอดภัยที่คืนค่า `Result` แทนการโยน exception
  /// - คืน `Success<String>` เมื่อการลบสำเร็จ
  /// - คืน `Failure` เมื่อไม่พบหรือเกิดข้อผิดพลาด
  Result<String> removeTaskSafe(String id) {
    try {
      if (!_taskIds.contains(id)) {
        return Failure('Task with ID "$id" not found');
      }

      final task = _taskMap[id]!;
      _tasks.remove(task);
      _taskMap.remove(id);
      _taskIds.remove(id);
      return Success('Task removed successfully');
    } catch (e) {
      return Failure('Failed to remove task: $e');
    }
  }

  /// ค้นหางานโดย title (partial, case-insensitive)
  /// คืนรายการ `Task` ที่ title ตรงกับ query (แยกด้วย substring)
  List<Task> searchByTitle(String query) {
    final q = query.toLowerCase();
    return _tasks.where((t) => t.title.toLowerCase().contains(q)).toList();
  }

  /// โหลดงานจากไฟล์ JSON แล้วแทนที่งานปัจจุบันทั้งหมด
  /// - ใช้ `TaskStorage.loadTasksOrThrow` ซึ่งจะโยน `StorageException` เมื่อเกิดปัญหา
  Future<void> loadFromFile(String path) async {
    final storage = TaskStorage(path);
    final loaded = await storage.loadTasksOrThrow();
    // แทนที่ state ภายใน
    _tasks.clear();
    _taskMap.clear();
    _taskIds.clear();
    for (var t in loaded) {
      _tasks.add(t);
      _taskMap[t.id] = t;
      _taskIds.add(t.id);
    }
  }

  /// บันทึกงานปัจจุบันเป็นไฟล์ JSON
  /// - เรียกใช้ `TaskStorage.saveTasksOrThrow` ซึ่งจะโยน `StorageException` เมื่อเกิดปัญหา
  Future<void> saveToFile(String path) async {
    final storage = TaskStorage(path);
    await storage.saveTasksOrThrow(_tasks);
  }

  /// คืน `Task` ตาม id หรือโยน `TaskNotFoundException` ถ้าไม่พบ
  Task getTaskOrThrow(String id) {
    final task = _taskMap[id];
    if (task == null) {
      throw TaskNotFoundException(id);
    }
    return task;
  }

  /// ค้นหา `Task` แบบปลอดภัยที่คืนค่า `Result` แทนการโยน exception
  /// - คืน `Success<Task>` ถ้าพบ
  /// - คืน `Failure` ถ้าไม่พบ
  Result<Task> findTaskSafe(String id) {
    final task = _taskMap[id];
    if (task == null) {
      return Failure('Task with ID "$id" not found');
    }
    return Success(task);
  }

  /// ค้นหา `Task` ตาม `id`
  /// - คืน `Task` ถ้าพบ หรือ `null` ถ้าไม่พบ
  Task? findTaskById(String id) {
    return _taskMap[id];
  }

  /// ลบงานโดย `id` คืน `true` ถ้าลบสำเร็จ
  bool removeTask(String id) {
    final task = _taskMap[id];
    if (task == null) {
      return false;
    }

    _tasks.remove(task);
    _taskMap.remove(id);
    _taskIds.remove(id);
    return true;
  }

  /// คืนรายการงานที่มีกำหนดครบภายใน `days` วันข้างหน้า
  /// - จะคืนเฉพาะงานที่ยังไม่เสร็จและมี `dueDate` อยู่
  List<Task> getTasksDueWithin(int days) {
    final deadline = DateTime.now().add(Duration(days: days));
    return _tasks.where((task) {
      final due = task.dueDate;
      return due != null && due.isBefore(deadline) && !task.isCompleted;
    }).toList();
  }

  /// คืนสถิติของงานในรูปแบบ `Map<String,int>`:
  /// - `total` : จำนวนงานทั้งหมด
  /// - `pending` : จำนวนงานที่ยังไม่เสร็จ
  /// - `completed` : จำนวนงานที่เสร็จแล้ว
  /// - `overdue` : จำนวนงานที่เลยกำหนด
  Map<String, int> getTaskStats() {
    return {
      'total': _tasks.length,
      'pending': pendingTasks.length,
      'completed': completedTasks.length,
      'overdue': _tasks.where((t) => t.isOverdue()).length,
    };
  }
}
