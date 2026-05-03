import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/course.dart';
import '../models/user_profile.dart';
import '../models/payment_method.dart';

class AppState extends ChangeNotifier {
  AppState();

  FirebaseAuth? _auth;
  FirebaseFirestore? _db;
  FirebaseStorage? _storage;

  bool _firebaseAvailable = false;
  bool get isFirebaseAvailable => _firebaseAvailable;

  bool _ready = false;
  bool get isReady => _ready;

  bool onboardingComplete = false;
  UserProfile? currentUser;
  List<PaymentMethod> paymentMethods = [];

  List<Course> _courses = [];
  List<Course> get courses => List.unmodifiable(_courses);

  final Set<String> purchasedCourseIds = {};
  final Set<String> favoriteCourseIds = {};
  final Map<String, int> videoProgressSeconds = {};

  static const _kOnboarding = 'onboarding_complete';
  static const _kPurchased = 'purchased_ids';
  static const _kFavorites = 'favorite_ids';
  static const _kProgress = 'video_progress';
  static const _kCourses = 'courses_json';
  static const _kUser = 'user_profile';
  static const _kPayments = 'payment_methods_json';

  Future<void> init({bool isFirebaseAvailable = true}) async {
    _firebaseAvailable = isFirebaseAvailable;
    
    if (_firebaseAvailable) {
      _auth = FirebaseAuth.instance;
      _db = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;
    }

    final p = await SharedPreferences.getInstance();
    onboardingComplete = p.getBool(_kOnboarding) ?? false;

    // Listen to Auth changes
    if (_firebaseAvailable) {
      _auth!.authStateChanges().listen(
        (user) async {
          try {
            if (user != null) {
              await _loadUserData(user.uid);
            } else {
              currentUser = null;
              paymentMethods = [];
              notifyListeners();
            }
          } catch (e) {
            debugPrint('Error loading user data: $e');
          }
        },
        onError: (e) {
          debugPrint('Auth stream error (likely invalid config): $e');
          // If the auth stream fails, we don't crash, we just remain in Demo Mode
        },
      );
    }

    purchasedCourseIds
      ..clear()
      ..addAll(_readStringList(p, _kPurchased));

    favoriteCourseIds
      ..clear()
      ..addAll(_readStringList(p, _kFavorites));

    final progRaw = p.getString(_kProgress);
    if (progRaw != null) {
      final map = jsonDecode(progRaw) as Map<String, dynamic>;
      videoProgressSeconds
        ..clear()
        ..addAll(map.map((k, v) => MapEntry(k, (v as num).toInt())));
    }

    final coursesRaw = p.getString(_kCourses);
    if (coursesRaw != null) {
      final list = jsonDecode(coursesRaw) as List<dynamic>;
      _courses = list
          .map((e) => Course.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _courses = buildSeedCourses();
    }

    if (!_firebaseAvailable) {
      final userRaw = p.getString(_kUser);
      if (userRaw != null) {
        currentUser = UserProfile.fromJson(jsonDecode(userRaw));
      }
      final paymentsRaw = p.getString(_kPayments);
      if (paymentsRaw != null) {
        final list = jsonDecode(paymentsRaw) as List<dynamic>;
        paymentMethods = list
            .map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    _ready = true;
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    if (!_firebaseAvailable) return;
    
    final doc = await _db!.collection('users').doc(uid).get();
    if (doc.exists) {
      currentUser = UserProfile.fromJson(doc.data()!);
    }
    
    final payments = await _db!
        .collection('payment_methods')
        .where('userId', isEqualTo: uid)
        .get();
    paymentMethods = payments.docs
        .map((d) => PaymentMethod.fromJson(d.data()))
        .toList();
    
    notifyListeners();
  }

  Set<String> _readStringList(SharedPreferences p, String key) {
    return p.getStringList(key)?.toSet() ?? {};
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOnboarding, onboardingComplete);
    await p.setStringList(_kPurchased, purchasedCourseIds.toList());
    await p.setStringList(_kFavorites, favoriteCourseIds.toList());
    await p.setString(
      _kProgress,
      jsonEncode(
        videoProgressSeconds.map((k, v) => MapEntry(k, v)),
      ),
    );
    await p.setString(
      _kCourses,
      jsonEncode(_courses.map((c) => c.toJson()).toList()),
    );

    if (!_firebaseAvailable) {
      if (currentUser != null) {
        await p.setString(_kUser, jsonEncode(currentUser!.toJson()));
      } else {
        await p.remove(_kUser);
      }
      await p.setString(
        _kPayments,
        jsonEncode(paymentMethods.map((m) => m.toJson()).toList()),
      );
    }
  }

  Future<void> completeOnboarding() async {
    onboardingComplete = true;
    notifyListeners();
    await _persist();
  }

  Future<void> resetOnboardingForDemo() async {
    onboardingComplete = false;
    notifyListeners();
    await _persist();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    DateTime? dateOfBirth,
    Uint8List? imageBytes,
  }) async {
    if (!_firebaseAvailable) {
      _performDemoRegister(name, email, phone, dateOfBirth);
      return;
    }

    try {
      final cred = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      String imageUrl = '';
      if (imageBytes != null) {
        final ref = _storage!.ref().child('profiles/$uid.jpg');
        await ref.putData(imageBytes);
        imageUrl = await ref.getDownloadURL();
      }

      final newUser = UserProfile(
        id: uid,
        name: name,
        email: email,
        phone: phone,
        profileImageUrl: imageUrl,
        dateOfBirth: dateOfBirth,
        createdAt: DateTime.now(),
        isAdmin: email.toLowerCase().contains('admin'),
      );

      await _db!.collection('users').doc(uid).set(newUser.toJson());
      currentUser = newUser;
      notifyListeners();
      await _persist();
    } catch (e) {
      final err = e.toString();
      if (err.contains('configuration-not-found') || 
          err.contains('invalid-credential') ||
          err.contains('api-key-not-found')) {
        debugPrint('Firebase Auth config error during register: $e. Falling back to Demo.');
        _performDemoRegister(name, email, phone, dateOfBirth);
      } else {
        rethrow;
      }
    }
  }

  void _performDemoRegister(String name, String email, String phone, DateTime? dob) {
    currentUser = UserProfile(
      id: 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      dateOfBirth: dob,
      createdAt: DateTime.now(),
    );
    notifyListeners();
    _persist();
  }

  Future<void> loginEmail({
    required String email,
    required String password,
  }) async {
    if (!_firebaseAvailable) {
      _performDemoLogin(email);
      return;
    }
    
    try {
      await _auth!.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      final err = e.toString();
      if (err.contains('configuration-not-found') || 
          err.contains('invalid-credential') ||
          err.contains('api-key-not-found')) {
        debugPrint('Firebase Auth config error during login: $e. Falling back to Demo.');
        _performDemoLogin(email);
      } else {
        rethrow;
      }
    }
  }

  void _performDemoLogin(String email) {
    currentUser = UserProfile(
      id: 'demo-user',
      name: 'Demo Learner',
      email: email,
      phone: '1234567890',
      createdAt: DateTime.now(),
    );
    notifyListeners();
    _persist();
  }

  Future<void> loginGoogleMock() async {
    const email = 'learner@gmail.com';
    if (!_firebaseAvailable) {
      _performDemoLogin(email);
      return;
    }
    
    try {
      // This is a "mock" that actually tries Firebase if available
      await _auth!.signInWithEmailAndPassword(email: email, password: 'password123');
    } catch (e) {
      debugPrint('Google Mock Login failed, falling back to Demo Mode: $e');
      _performDemoLogin(email);
    }
  }

  Future<void> logout() async {
    if (_firebaseAvailable) {
      await _auth!.signOut();
    }
    currentUser = null;
    paymentMethods = [];
    notifyListeners();
    await _persist();
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    DateTime? dateOfBirth,
    Uint8List? imageBytes,
  }) async {
    final u = currentUser;
    if (u == null) return;

    String imageUrl = u.profileImageUrl;
    if (_firebaseAvailable && imageBytes != null) {
      final ref = _storage!.ref().child('profiles/${u.id}.jpg');
      await ref.putData(imageBytes);
      imageUrl = await ref.getDownloadURL();
    }

    final updated = UserProfile(
      id: u.id,
      name: name,
      email: u.email,
      phone: phone,
      profileImageUrl: imageUrl,
      dateOfBirth: dateOfBirth,
      role: u.role,
      createdAt: u.createdAt,
      isAdmin: u.isAdmin,
    );

    if (_firebaseAvailable) {
      await _db!.collection('users').doc(u.id).update(updated.toJson());
    }
    
    currentUser = updated;
    notifyListeners();
    await _persist();
  }

  Future<void> addPaymentMethod({
    required String cardHolderName,
    required String last4Digits,
    required String expiryDate,
  }) async {
    final uid = currentUser?.id;
    if (uid == null) return;

    final method = PaymentMethod(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: uid,
      cardHolderName: cardHolderName,
      last4Digits: last4Digits,
      expiryDate: expiryDate,
      createdAt: DateTime.now(),
    );

    if (_firebaseAvailable) {
      final docRef = _db!.collection('payment_methods').doc();
      final finalMethod = method.copyWith(id: docRef.id);
      await docRef.set(finalMethod.toJson());
      paymentMethods.add(finalMethod);
    } else {
      paymentMethods.add(method);
      await _persist();
    }
    
    notifyListeners();
  }

  Future<void> deletePaymentMethod(String id) async {
    if (_firebaseAvailable) {
      await _db!.collection('payment_methods').doc(id).delete();
    }
    paymentMethods.removeWhere((m) => m.id == id);
    notifyListeners();
    if (!_firebaseAvailable) {
      await _persist();
    }
  }

  // Analytics Helpers
  int get completedCoursesCount {
    int count = 0;
    for (final courseId in purchasedCourseIds) {
      final course = courseById(courseId);
      if (course != null) {
        final progress = videoProgressSeconds[courseId] ?? 0;
        final total = course.durationMinutes * 60;
        if (total > 0 && progress >= total * 0.9) {
          count++;
        }
      }
    }
    return count;
  }

  double get overallProgress {
    if (purchasedCourseIds.isEmpty) return 0.0;
    double totalProgress = 0.0;
    int count = 0;
    for (final id in purchasedCourseIds) {
      final course = courseById(id);
      if (course != null) {
        final seconds = videoProgressSeconds[id] ?? 0;
        final totalSeconds = course.durationMinutes * 60;
        if (totalSeconds > 0) {
          totalProgress += (seconds / totalSeconds).clamp(0.0, 1.0);
          count++;
        }
      }
    }
    return count > 0 ? totalProgress / count : 0.0;
  }

  Duration get totalLearningTime {
    int totalSeconds = 0;
    videoProgressSeconds.forEach((_, seconds) => totalSeconds += seconds);
    return Duration(seconds: totalSeconds);
  }

  Course? courseById(String id) {
    try {
      return _courses.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  bool isPurchased(String courseId) => purchasedCourseIds.contains(courseId);
  bool isFavorite(String courseId) => favoriteCourseIds.contains(courseId);

  Future<void> toggleFavorite(String courseId) async {
    if (favoriteCourseIds.contains(courseId)) {
      favoriteCourseIds.remove(courseId);
    } else {
      favoriteCourseIds.add(courseId);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> purchaseCourse(String courseId) async {
    purchasedCourseIds.add(courseId);
    notifyListeners();
    await _persist();
  }

  Future<void> setVideoProgress(String courseId, int seconds) async {
    videoProgressSeconds[courseId] = seconds;
    notifyListeners();
    await _persist();
  }

  int progressFor(String courseId) => videoProgressSeconds[courseId] ?? 0;

  Future<void> upsertCourse(Course course) async {
    final i = _courses.indexWhere((c) => c.id == course.id);
    if (i >= 0) {
      _courses[i] = course;
    } else {
      _courses.add(course);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> deleteCourse(String id) async {
    _courses.removeWhere((c) => c.id == id);
    purchasedCourseIds.remove(id);
    favoriteCourseIds.remove(id);
    videoProgressSeconds.remove(id);
    notifyListeners();
    await _persist();
  }

  List<String> get categories {
    final s = _courses.map((c) => c.category).toSet().toList()..sort();
    return s;
  }

  List<Course> coursesPage({
    required int offset,
    required int limit,
    String? categoryQuery,
    String? search,
  }) {
    Iterable<Course> it = _courses;
    final cat = categoryQuery?.trim();
    if (cat != null && cat.isNotEmpty && cat != 'All') {
      it = it.where((c) => c.category == cat);
    }
    final q = search?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      it = it.where(
        (c) =>
            c.title.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q),
      );
    }
    final list = it.toList();
    return list.skip(offset).take(limit).toList();
  }

  int countCourses({
    String? categoryQuery,
    String? search,
  }) {
    Iterable<Course> it = _courses;
    final cat = categoryQuery?.trim();
    if (cat != null && cat.isNotEmpty && cat != 'All') {
      it = it.where((c) => c.category == cat);
    }
    final q = search?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      it = it.where(
        (c) =>
            c.title.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q),
      );
    }
    return it.length;
  }
}
