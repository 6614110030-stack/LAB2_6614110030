// Base exception for task-related errors
class TaskException implements Exception {
  final String message;
  final String? details;

  TaskException(this.message, [this.details]);

  @override
  String toString() {
    if (details != null) {
      return 'TaskException: $message\nDetails: $details';
    }
    return 'TaskException: $message';
  }
}

// Thrown when task ID already exists
class DuplicateTaskException extends TaskException {
  DuplicateTaskException(String taskId)
    : super('Task with ID "$taskId" already exists');
}

// Thrown when task is not found
class TaskNotFoundException extends TaskException {
  TaskNotFoundException(String taskId)
    : super('Task with ID "$taskId" not found');
}

// Thrown when task data is invalid
class InvalidTaskDataException extends TaskException {
  InvalidTaskDataException(String field, String reason)
    : super('Invalid task data', 'Field "$field": $reason');
}

// Thrown when storage operation fails
class StorageException extends TaskException {
  StorageException(String operation, String reason)
    : super('Storage operation failed', '$operation: $reason');
}
