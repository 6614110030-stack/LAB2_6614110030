// ไฟล์นี้ประกอบด้วยคลาส `Task` ซึ่งเป็นตัวแทนของงาน (todo)
// ใช้เก็บข้อมูลพื้นฐานของงาน เช่น id, title, description, dueDate และสถานะการทำงาน
// คลาสนี้มีเมธอดช่วยเหลือเช่นการทำเครื่องหมายว่างานเสร็จและตรวจสอบว่า overdue หรือไม่
/// คลาส `Task` เป็นโมเดลข้อมูลหลักของงานหนึ่งชิ้น
/// - เก็บข้อมูลพื้นฐาน: `id`, `title`, `description`, `dueDate`, และ `isCompleted`
/// - สามารถเรียก `complete()` เพื่อทำเครื่องหมายว่างานเสร็จ
/// - เมธอด `isOverdue()` ใช้ตรวจสอบว่าเวลาปัจจุบันเลยกำหนดหรือไม่
class Task {
  // รหัสประจำงาน (ต้องกำหนดค่า) - ใช้สำหรับอ้างอิงและค้นหา
  final String id;
  // ชื่อหัวข้องาน
  String title;
  // รายละเอียดเพิ่มเติมของงาน (ว่างเป็นค่าว่างได้)
  String description;

  // วันที่ครบกำหนด (nullable ถ้าไม่มี due date)
  DateTime? dueDate;

  // สถานะว่าเสร็จหรือยัง (default false)
  bool isCompleted;

  /// สร้าง `Task` ใหม่
  ///
  /// พารามิเตอร์:
  /// - `id` : รหัสที่ไม่ซ้ำของงาน (required)
  /// - `title` : ชื่อหัวข้องาน (required)
  /// - `description` : รายละเอียด (default เป็นค่าว่าง)
  /// - `dueDate` : วันที่กำหนด (nullable)
  /// - `isCompleted` : สถานะว่าเสร็จหรือยัง (default false)
  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.isCompleted = false,
  });

  /// ทำเครื่องหมายว่างานเป็นสถานะเสร็จ
  void complete() {
    isCompleted = true;
  }

  /// ตรวจสอบว่างาน overdue หรือไม่
  /// คืนค่า `true` ถ้า `dueDate` ถูกกำหนดและเวลาปัจจุบันเลยวันนั้นแล้ว
  bool isOverdue() {
    final due = dueDate;
    if (due == null) {
      return false; // ถ้าไม่มี due date ถือว่าไม่ overdue
    }
    return DateTime.now().isAfter(due);
  }

  // คืนสตริงสรุปสถานะงาน สำหรับการดีบักหรือแสดงผล
  @override
  String toString() {
    final status = isCompleted ? 'Completed' : 'Pending';
    final due = dueDate != null
        ? 'Due: ${dueDate!.toLocal().toString().split(' ')[0]}'
        : 'No due date';
    return 'Task: $title ($status) - $due';
  }
}

// Priority task with priority level
/// `PriorityTask` คือ `Task` ที่เพิ่มระดับความสำคัญ (priority)
/// - `priority` เป็นค่าจาก 1 (สูงสุด) ถึง 3 (ต่ำสุด)
class PriorityTask extends Task {
  /// ระดับความสำคัญของงาน (1..3)
  final int priority;

  PriorityTask({
    required super.id,
    required super.title,
    super.description,
    super.dueDate,
    super.isCompleted,
    this.priority = 2, // Default medium priority
  }) : assert(
         priority >= 1 && priority <= 3,
         'Priority must be between 1 and 3',
       );

  /// คืนคำอธิบายระดับความสำคัญ เช่น 'High', 'Medium', 'Low'
  String get priorityLabel {
    switch (priority) {
      case 1:
        return 'High';
      case 2:
        return 'Medium';
      case 3:
        return 'Low';
      default:
        return 'Unknown';
    }
  }

  @override
  String toString() {
    return '${super.toString()} [Priority: $priorityLabel]';
  }
}

// Recurring task that repeats periodically
/// `RecurringTask` เป็นงานที่เกิดขึ้นซ้ำตามช่วงเวลา (interval)
/// - `intervalDays` กำหนดจำนวนวันระหว่างการเกิดซ้ำแต่ละครั้ง
class RecurringTask extends Task {
  /// จำนวนวันระหว่างการเกิดซ้ำ (ต้องเป็นจำนวนเต็มบวก)
  final int intervalDays;

  /// วันที่ที่งานถูกทำเสร็จล่าสุด (ใช้ในการคำนวณ occurrence ถัดไป)
  DateTime? lastCompleted;

  RecurringTask({
    required super.id,
    required super.title,
    super.description,
    super.dueDate,
    super.isCompleted,
    required this.intervalDays,
    this.lastCompleted,
  }) : assert(intervalDays > 0, 'Interval must be positive');

  /// คำนวณวันที่ครบกำหนดครั้งถัดไป
  /// - ถ้ามี `lastCompleted` จะใช้ค่านั้นเป็นฐาน
  /// - ถ้าไม่มีแต่มี `dueDate` จะใช้ `dueDate` เป็นฐาน
  DateTime? getNextDueDate() {
    final last = lastCompleted ?? dueDate;
    if (last == null) return null;
    return last.add(Duration(days: intervalDays));
  }

  @override
  /// ทำเครื่องหมายว่างานเสร็จ และเตรียม occurrence ถัดไป
  /// - อัปเดต `lastCompleted` เป็นเวลาปัจจุบัน
  /// - คำนวณ `dueDate` ถัดไปจาก `intervalDays`
  /// - รีเซ็ต `isCompleted` เป็น false เพื่อให้ occurrence ใหม่สามารถถูกทำซ้ำได้
  void complete() {
    super.complete();
    lastCompleted = DateTime.now();
    // Reset for next occurrence
    isCompleted = false;
    dueDate = getNextDueDate();
  }

  @override
  String toString() {
    return '${super.toString()} [Repeats every $intervalDays days]';
  }
}
