import 'package:flutter/foundation.dart';

import '../../features/home/data/mock_home_data.dart';
import '../models/student.dart';
import 'parent_api_service.dart';

/// Central state notifier for managing the parent's list of registered students.
/// Shared across ParentHomeView, ManageStudentsScreen, and AddStudentScreen.
class StudentListNotifier extends ChangeNotifier {
  final ParentApiService _apiService;

  List<Student> _students = [];
  bool _isLoading = false;
  bool _hasFetchError = false;
  bool _hasLoaded = false;

  StudentListNotifier(
    this._apiService, {
    List<Student>? initialStudents,
    bool hasFetchError = false,
  }) {
    if (initialStudents != null) {
      _students = initialStudents;
      _hasLoaded = true;
      _hasFetchError = hasFetchError;
    }
  }

  List<Student> get students => _students;
  bool get isLoading => _isLoading;
  bool get hasFetchError => _hasFetchError;
  bool get hasLoaded => _hasLoaded;

  /// Fetches the latest students from the backend API.
  /// If [force] is false and data has already been loaded, does nothing.
  Future<void> fetchStudents({bool force = false}) async {
    if (_hasLoaded && !force) return;

    _isLoading = true;
    _hasFetchError = false;
    notifyListeners();

    try {
      final fetched = await _apiService.getStudents();
      _students = fetched;
      _isLoading = false;
      _hasFetchError = false;
      _hasLoaded = true;
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      _hasFetchError = true;
      // Fallback to mock data on offline or genuine fetch error
      _students = MockHomeData.students;
      _hasLoaded = true;
      notifyListeners();
    }
  }

  /// Forces a re-fetch of the student list from the backend.
  Future<void> refresh() async {
    await fetchStudents(force: true);
  }

  /// Adds a newly created student to the local list immediately and syncs with backend.
  Future<void> onStudentAdded(Student student) async {
    // Immediate optimistic update
    if (!_students.any((s) => s.id == student.id)) {
      _students = [student, ..._students];
    }
    _hasFetchError = false;
    _hasLoaded = true;
    notifyListeners();

    // Reconcile with backend in background
    try {
      final fetched = await _apiService.getStudents();
      if (fetched.isNotEmpty) {
        _students = fetched;
      }
      notifyListeners();
    } catch (_) {
      // Keep local list if offline/background check fails
    }
  }
}
