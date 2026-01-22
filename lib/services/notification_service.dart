import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/animal.dart';
import '../models/field.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const List<String> animalScopes = [
    'animal_birthday',
    'animal_last_birth',
    'animal_heat',
  ];

  static const List<String> fieldScopes = [
    'field_planting',
    'field_harvest',
  ];

  static const List<String> _allScopes = [
    ...animalScopes,
    ...fieldScopes,
  ];

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    if (!Platform.isAndroid && !Platform.isIOS) {
      _initialized = true;
      return;
    }

    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _notifications.initialize(initSettings);

    if (Platform.isAndroid) {
      final androidSpecific = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidSpecific?.createNotificationChannel(
        const AndroidNotificationChannel(
          'reminders_channel',
          'Hatırlatıcılar',
          description: 'Tarla ve hayvan hatırlatıcı bildirimleri',
          importance: Importance.high,
        ),
      );
    }

    _initialized = true;
  }

  Future<void> scheduleAnimalNotifications(Animal animal) async {
    await initialize();
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await cancelNotificationsForEntity(animal.id, scopes: animalScopes);
    await _scheduleBirthdayReminder(animal);
    await _scheduleLastBirthReminder(animal);
    await _scheduleHeatReminder(animal);
  }

  Future<void> scheduleFieldNotifications(Field field) async {
    await initialize();
     if (!Platform.isAndroid && !Platform.isIOS) return;
    await cancelNotificationsForEntity(field.id, scopes: fieldScopes);
    await _scheduleFieldPlantingReminder(field);
    await _scheduleFieldHarvestReminder(field);
  }

  Future<void> cancelNotificationsForEntity(
    String entityId, {
    List<String>? scopes,
  }) async {
    await initialize();
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final targetScopes = scopes ?? _allScopes;
    for (final scope in targetScopes) {
      await _notifications.cancel(_notificationId(entityId, scope));
    }
  }

  NotificationDetails get _notificationDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders_channel',
          'Hatırlatıcılar',
          channelDescription: 'Tarla ve hayvan hatırlatıcı bildirimleri',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(),
      );

  Future<void> _scheduleBirthdayReminder(Animal animal) async {
    final nextBirthday = _nextAnnualDate(animal.birthDate);
    if (nextBirthday == null) return;

    final age = nextBirthday.year - animal.birthDate.year;
    await _scheduleReminder(
      id: _notificationId(animal.id, animalScopes[0]),
      scheduledDate: nextBirthday,
      title: 'Doğum Günü',
      body: '${animal.name} hayvanınız $age yaşına girdi 🎉',
    );
  }

  Future<void> _scheduleLastBirthReminder(Animal animal) async {
    if (animal.lastBirthDate == null) return;
    final nextAnniversary = _nextAnnualDate(animal.lastBirthDate!);
    if (nextAnniversary == null) return;

    final formatted =
        DateFormat('d MMMM yyyy', 'tr_TR').format(animal.lastBirthDate!);
    await _scheduleReminder(
      id: _notificationId(animal.id, animalScopes[1]),
      scheduledDate: nextAnniversary,
      title: 'Doğurma Hatırlatması',
      body: '${animal.name} hayvanınız en son $formatted tarihinde doğurmuştu.',
    );
  }

  Future<void> _scheduleHeatReminder(Animal animal) async {
    if (animal.nextHeatDate == null) return;
    final scheduleDate = DateTime(
      animal.nextHeatDate!.year,
      animal.nextHeatDate!.month,
      animal.nextHeatDate!.day,
      8,
    );
    if (scheduleDate.isBefore(DateTime.now())) return;

    await _scheduleReminder(
      id: _notificationId(animal.id, animalScopes[2]),
      scheduledDate: scheduleDate,
      title: 'Kızgınlık Takibi',
      body: '${animal.name} için kızgınlık takibi günü geldi.',
    );
  }

  Future<void> _scheduleFieldPlantingReminder(Field field) async {
    if (field.plantingDate == null) return;
    final scheduleDate = DateTime(
      field.plantingDate!.year,
      field.plantingDate!.month,
      field.plantingDate!.day,
      7,
    );
    if (scheduleDate.isBefore(DateTime.now())) return;

    await _scheduleReminder(
      id: _notificationId(field.id, fieldScopes[0]),
      scheduledDate: scheduleDate,
      title: 'Ekim Takvimi',
      body: '${field.name} için ekim zamanı geldi. Hazırlıkları başlatın.',
    );
  }

  Future<void> _scheduleFieldHarvestReminder(Field field) async {
    if (field.harvestDate == null) return;
    final scheduleDate = DateTime(
      field.harvestDate!.year,
      field.harvestDate!.month,
      field.harvestDate!.day,
      7,
    );
    if (scheduleDate.isBefore(DateTime.now())) return;

    await _scheduleReminder(
      id: _notificationId(field.id, fieldScopes[1]),
      scheduledDate: scheduleDate,
      title: 'Hasat Takvimi',
      body: '${field.name} için hasat günü geldi. Başarılar dileriz.',
    );
  }

  Future<void> _scheduleReminder({
    required int id,
    required DateTime scheduledDate,
    required String title,
    required String body,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      _notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  DateTime? _nextAnnualDate(DateTime source) {
    final now = DateTime.now();
    DateTime candidate = DateTime(now.year, source.month, source.day, 9);
    if (candidate.isBefore(now)) {
      candidate = DateTime(now.year + 1, source.month, source.day, 9);
    }
    return candidate;
  }

  int _notificationId(String entityId, String scope) {
    final hash = entityId.hashCode ^ scope.hashCode;
    return hash.abs();
  }
}
