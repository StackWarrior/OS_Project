import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/course.dart';
import '../models/user_profile.dart';
import '../models/payment_method.dart';
import '../data/seed_data.dart';

enum AppStatus { initial, loading, authenticated, unauthenticated, error }

class AppState extends ChangeNotifier {
  AppState();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const _kAdminEmail = 'mmomoadel@gmail.com';

  AppStatus _status = AppStatus.initial;
  AppStatus get status => _status;

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

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
  static const _kLocale = 'selected_locale';

  Future<void> init() async {
    _status = AppStatus.loading;
    notifyListeners();

    try {
      final p = await SharedPreferences.getInstance();
      onboardingComplete = p.getBool(_kOnboarding) ?? false;
      
      final savedLocale = p.getString(_kLocale);
      if (savedLocale != null) {
        _locale = Locale(savedLocale);
      }

      // Load local preferences
      purchasedCourseIds.addAll(p.getStringList(_kPurchased) ?? []);
      favoriteCourseIds.addAll(p.getStringList(_kFavorites) ?? []);
      
      final progRaw = p.getString(_kProgress);
      if (progRaw != null) {
        final map = jsonDecode(progRaw) as Map<String, dynamic>;
        videoProgressSeconds.addAll(map.map((k, v) => MapEntry(k, (v as num).toInt())));
      }

      // Sync seed data: Ensure all default courses exist in Firestore
      final seedCourses = buildSeedCourses();
      for (final c in seedCourses) {
        // We use a simple existence check to avoid overwriting admin changes 
        // but ensuring new seed courses are added.
        final docRef = _db.collection('courses').doc(c.id);
        final doc = await docRef.get();
        if (!doc.exists) {
          await docRef.set(c.toJson());
        }
      }

      // Real-time listener for courses
      _db.collection('courses').snapshots().listen((snapshot) {
        _courses = snapshot.docs.map((d) {
          final data = d.data();
          if (data['id'] == null) data['id'] = d.id;
          return Course.fromJson(data);
        }).toList();
        notifyListeners();
      });

      // Listen for total users count (Admin only logic usually, but here in AppState)
      _db.collection('users').snapshots().listen((snapshot) {
        _totalUsersCount = snapshot.docs.length;
        notifyListeners();
      });

      // Listen for purchases to calculate revenue
      _db.collection('purchases').snapshots().listen((snapshot) {
        double revenue = 0.0;
        for (var doc in snapshot.docs) {
          revenue += (doc.data()['price'] as num?)?.toDouble() ?? 0.0;
        }
        _totalRevenue = revenue;
        notifyListeners();
      });

      // Listen to Auth changes
      _auth.authStateChanges().listen(
        (user) async {
          if (user != null) {
            try {
              await _loadUserData(user.uid);
              _status = AppStatus.authenticated;
            } catch (e) {
              _status = AppStatus.error;
              _errorMessage = 'Failed to load user data: $e';
            }
          } else {
            currentUser = null;
            paymentMethods = [];
            _status = AppStatus.unauthenticated;
          }
          notifyListeners();
        },
        onError: (e) {
          _status = AppStatus.error;
          _errorMessage = 'Authentication stream error: $e';
          notifyListeners();
        },
      );
    } catch (e) {
      _status = AppStatus.error;
      _errorMessage = 'Initialization failed: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _loadUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      // Create a default profile if it doesn't exist (e.g. for users created via Console or first-time login)
      final user = _auth.currentUser;
      if (user != null) {
        final email = user.email ?? '';
        final bool isActuallyAdmin = email.trim().toLowerCase() == _kAdminEmail;

        final newUser = UserProfile(
          id: uid,
          name: user.displayName ?? 'New User',
          email: email,
          createdAt: DateTime.now(),
          role: isActuallyAdmin ? 'admin' : 'user',
          isAdmin: isActuallyAdmin,
        );
        await _db.collection('users').doc(uid).set(newUser.toJson());
        currentUser = newUser;
      } else {
        throw Exception('No authenticated user found');
      }
    } else {
      final data = doc.data()!;
      currentUser = UserProfile.fromJson(data);
      
      // Force admin status if the email matches, even if the doc was previously non-admin
      final bool isActuallyAdmin = currentUser!.email.trim().toLowerCase() == _kAdminEmail;
      if (isActuallyAdmin && !currentUser!.isAdmin) {
        currentUser!.isAdmin = true;
        currentUser!.role = 'admin';
        await _db.collection('users').doc(uid).update({
          'isAdmin': true,
          'role': 'admin',
        });
      }
    }

    final payments = await _db
        .collection('payment_methods')
        .where('userId', isEqualTo: uid)
        .get();
    
    paymentMethods = payments.docs
        .map((d) => PaymentMethod.fromJson(d.data()))
        .toList();
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOnboarding, onboardingComplete);
    await p.setStringList(_kPurchased, purchasedCourseIds.toList());
    await p.setStringList(_kFavorites, favoriteCourseIds.toList());
    await p.setString(_kProgress, jsonEncode(videoProgressSeconds));
    await p.setString(_kLocale, _locale.languageCode);
  }

  Future<void> toggleLanguage() async {
    if (_locale.languageCode == 'en') {
      _locale = const Locale('ar');
    } else {
      _locale = const Locale('en');
    }
    notifyListeners();
    await _persist();
  }

  Future<void> completeOnboarding() async {
    onboardingComplete = true;
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
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    String imageUrl = '';
    if (imageBytes != null) {
      final ref = _storage.ref().child('profiles/$uid.jpg');
      await ref.putData(imageBytes);
      imageUrl = await ref.getDownloadURL();
    }

    final bool isActuallyAdmin = email.trim().toLowerCase() == _kAdminEmail;

    final newUser = UserProfile(
      id: uid,
      name: name,
      email: email,
      phone: phone,
      profileImageUrl: imageUrl,
      dateOfBirth: dateOfBirth,
      createdAt: DateTime.now(),
      role: isActuallyAdmin ? 'admin' : 'user',
      isAdmin: isActuallyAdmin,
    );

    await _db.collection('users').doc(uid).set(newUser.toJson());
    currentUser = newUser;
    _status = AppStatus.authenticated;
    notifyListeners();
    await _persist();
  }

  Future<void> loginEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async {
    await _auth.signOut();
    currentUser = null;
    paymentMethods = [];
    _status = AppStatus.unauthenticated;
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
    if (imageBytes != null) {
      final ref = _storage.ref().child('profiles/${u.id}.jpg');
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

    await _db.collection('users').doc(u.id).update(updated.toJson());
    currentUser = updated;
    notifyListeners();
  }

  Future<void> addPaymentMethod({
    required String cardHolderName,
    required String cardNumber,
    required String last4Digits,
    required String expiryDate,
    required String cvv,
  }) async {
    final uid = currentUser?.id;
    if (uid == null) return;

    final docRef = _db.collection('payment_methods').doc();
    final method = PaymentMethod(
      id: docRef.id,
      userId: uid,
      cardHolderName: cardHolderName,
      cardNumber: cardNumber,
      last4Digits: last4Digits,
      expiryDate: expiryDate,
      cvv: cvv,
      createdAt: DateTime.now(),
    );

    await docRef.set(method.toJson());
    paymentMethods.add(method);
    notifyListeners();
  }

  Future<void> deletePaymentMethod(String id) async {
    await _db.collection('payment_methods').doc(id).delete();
    paymentMethods.removeWhere((m) => m.id == id);
    notifyListeners();
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
    final course = courseById(courseId);
    if (course == null) return;

    final uid = currentUser?.id;
    if (uid != null) {
      // Record purchase in Firestore
      await _db.collection('purchases').add({
        'userId': uid,
        'courseId': courseId,
        'price': course.price,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

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
    
    // Persist to Firestore
    await _db.collection('courses').doc(course.id).set(course.toJson());

    if (i >= 0) {
      _courses[i] = course;
    } else {
      _courses.add(course);
    }
    notifyListeners();
  }

  Future<void> deleteCourse(String id) async {
    // Delete from Firestore
    await _db.collection('courses').doc(id).delete();

    _courses.removeWhere((c) => c.id == id);
    purchasedCourseIds.remove(id);
    favoriteCourseIds.remove(id);
    videoProgressSeconds.remove(id);
    notifyListeners();
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

  int _totalUsersCount = 0;
  int get totalUsersCount => _totalUsersCount;

  double get totalRevenue {
    double revenue = 0.0;
    // This is a simplification. Ideally, we'd have a 'purchases' collection in Firestore.
    // For now, we calculate based on the current user's purchases if we want personal revenue,
    // but the task asks for AppState revenue/user count logic, likely for an admin view.
    // If it's for admin, we need to fetch this from Firestore.
    return _totalRevenue;
  }
  double _totalRevenue = 0.0;

  int get featuredCoursesCount => _courses.where((c) => c.featured).length;
}
