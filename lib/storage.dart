import 'dart:io';
import 'dart:convert';
import 'task.dart';
import 'exceptions.dart';

// Handles task persistence to file system
class TaskStorage {
  final String filePath;

  TaskStorage(this.filePath);

  // Save tasks to file asynchronously
  Future<bool> saveTasks(List<Task> tasks) async {
    try {
      final file = File(filePath);

      // Convert tasks to JSON
      final jsonList = tasks
          .map(
            (task) => {
              'id': task.id,
              'title': task.title,
              'description': task.description,
              'dueDate': task.dueDate?.toIso8601String(),
              'isCompleted': task.isCompleted,
            },
          )
          .toList();

      // Write to file with proper formatting
      final jsonString = JsonEncoder.withIndent('  ').convert(jsonList);
      await file.writeAsString(jsonString);

      print('Saved ${tasks.length} tasks to $filePath');
      return true;
    } catch (e) {
      print('Error saving tasks: $e');
      return false;
    }
  }

  // Load tasks from file asynchronously
  Future<List<Task>> loadTasks() async {
    try {
      final file = File(filePath);

      // Check if file exists
      if (!await file.exists()) {
        print('No saved tasks found');
        return [];
      }

      // Read and parse JSON
      final jsonString = await file.readAsString();
      final jsonList = jsonDecode(jsonString) as List;

      // Convert JSON to Task objects
      final tasks = jsonList.map((json) {
        return Task(
          id: json['id'] as String,
          title: json['title'] as String,
          description: json['description'] as String? ?? '',
          dueDate: json['dueDate'] != null
              ? DateTime.parse(json['dueDate'] as String)
              : null,
          isCompleted: json['isCompleted'] as bool? ?? false,
        );
      }).toList();

      print('Loaded ${tasks.length} tasks from $filePath');
      return tasks;
    } catch (e) {
      print('Error loading tasks: $e');
      return [];
    }
  }

  // Delete all saved tasks
  Future<bool> clearTasks() async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('Cleared all saved tasks');
        return true;
      }
      return false;
    } catch (e) {
      print('Error clearing tasks: $e');
      return false;
    }
  }

  // Simulate network delay for learning async
  Future<void> simulateNetworkDelay() async {
    print('Simulating network request...');
    await Future.delayed(Duration(seconds: 2));
    print('Network request completed!');
  }

  /// Save tasks but throw detailed exceptions on failure
  Future<void> saveTasksOrThrow(List<Task> tasks) async {
    try {
      final file = File(filePath);

      // If file exists, read existing tasks and merge to preserve old data
      Map<String, Map<String, Object?>> existingMap = {};
      if (await file.exists()) {
        try {
          final existingString = await file.readAsString();
          final existingJson = jsonDecode(existingString) as List;
          for (var e in existingJson) {
            final id = e['id'] as String?;
            if (id != null) {
              existingMap[id] = Map<String, Object?>.from(e as Map);
            }
          }
        } catch (_) {
          // If existing file is corrupt, we will overwrite but notify
          print('Warning: existing file is not valid JSON, it will be replaced');
          existingMap = {};
        }
      }

      // Merge tasks: keep existing tasks that are not in incoming list
      final duplicates = <String>[];
      for (var task in tasks) {
        final jsonObj = {
          'id': task.id,
          'title': task.title,
          'description': task.description,
          'dueDate': task.dueDate?.toIso8601String(),
          'isCompleted': task.isCompleted,
        };
        if (existingMap.containsKey(task.id)) {
          duplicates.add(task.id);
        }
        existingMap[task.id] = jsonObj;
      }

      final mergedList = existingMap.values.toList();
      final jsonString = JsonEncoder.withIndent('  ').convert(mergedList);
      await file.writeAsString(jsonString);

      if (duplicates.isNotEmpty) {
        print('Saved ${tasks.length} tasks (merged). Duplicate ids updated: ${duplicates.join(', ')}');
      } else {
        print('Saved ${tasks.length} tasks successfully');
      }
    } on FileSystemException catch (e) {
      throw StorageException('save', e.message);
    } on JsonUnsupportedObjectError catch (e) {
      throw StorageException('save', 'Invalid JSON: ${e.unsupportedObject}');
    } catch (e) {
      throw StorageException('save', e.toString());
    }
  }

  /// Load tasks but throw detailed exceptions on failure
  Future<List<Task>> loadTasksOrThrow() async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        return []; // Empty list is valid, not an error
      }

      final jsonString = await file.readAsString();
      final jsonList = jsonDecode(jsonString) as List;

      return jsonList.map((json) {
        try {
          return Task(
            id: json['id'] as String,
            title: json['title'] as String,
            description: json['description'] as String? ?? '',
            dueDate: json['dueDate'] != null
                ? DateTime.parse(json['dueDate'] as String)
                : null,
            isCompleted: json['isCompleted'] as bool? ?? false,
          );
        } catch (e) {
          throw StorageException(
            'load',
            'Invalid task data: ${json['id'] ?? 'unknown'}',
          );
        }
      }).toList();
    } on FileSystemException catch (e) {
      throw StorageException('load', e.message);
    } on FormatException catch (e) {
      throw StorageException('load', 'Invalid JSON format: ${e.message}');
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException('load', e.toString());
    }
  }
}
