import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:callink_flutter/features/callink_chat/infrastructure/chat/models/request/save_notification_request.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';

import '../constants/common.dart';

const String groupKey = 'chat.callink.id';
// Map<String, List<NotificationData>> storeMapMessages = {};
final StoreGlobalNotification storeNotification = StoreGlobalNotification();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await setupFlutterNotifications();
  await saveToMessage(message);
  showRemoteNotificationOnly(message);
  // print('Handling a background message ${message.toMap()}');
  return;
}

Future<bool> saveToMessage(RemoteMessage messages) async {
  final data = NotificationData.fromJson(messages.data);

  List<ActiveNotification> activeNotifications =
      await flutterLocalNotificationsPlugin.getActiveNotifications();
  print('activeNotifications banyak ${activeNotifications.length} '
      '${activeNotifications.asMap().toString()}');
  if (activeNotifications.isEmpty) {
    storeNotification.deleteAll();
  } else {
    for (ActiveNotification active in activeNotifications) {
      print('active title ${active.title} '
          'body ${active.body} '
          'groupKey ${active.groupKey} '
          'tag ${active.tag} '
          'id ${active.id} '
          'payload ${active.payload} ');
      if (active.id != 0) {
        storeNotification.updateValue(data.title, [data]);
      }
    }
  }

  storeNotification.updateValue(data.title, [data]);
  return true;
}

final BehaviorSubject<String> storeNotificationClick = BehaviorSubject();
final localNotificationsPlugin = FlutterLocalNotificationsPlugin();
const bool isLocalNotificationInit = false;

bool isFlutterLocalNotificationsInitialized = false;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description:
      'This channel is used for important notifications.', // description
  importance: Importance.max,
);
const channelGroup = AndroidNotificationChannelGroup(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description: 'This channel is used for important notifications.',
);

AndroidFlutterLocalNotificationsPlugin?
    _androidFlutterLocalNotificationsPlugin =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

Future<void> setupFlutterNotifications() async {
  await Firebase.initializeApp();
  if (isFlutterLocalNotificationsInitialized) return;

  const initializationSettingsAndroid = AndroidInitializationSettings('splash');

  final initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification:
          (int? id, String? title, String? body, String? payload) async {});

  var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

  await _androidFlutterLocalNotificationsPlugin
      ?.createNotificationChannelGroup(channelGroup);
  await _androidFlutterLocalNotificationsPlugin
      ?.createNotificationChannel(channel);

  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  final didNotificationLaunchApp =
      notificationAppLaunchDetails?.didNotificationLaunchApp ?? false;

  if (didNotificationLaunchApp) {
    final resNotification = notificationAppLaunchDetails?.notificationResponse;
    if (resNotification != null) onSelectNotification(resNotification);
  } else {
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onSelectNotification,
      onDidReceiveBackgroundNotificationResponse: onSelectNotification,
    );
  }

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  isFlutterLocalNotificationsInitialized = true;
}

@pragma('vm:entry-point')
void onSelectNotification(NotificationResponse notificationResponse) {
  print("payload acttion ${notificationResponse.actionId} "
      "${notificationResponse.input} "
      "${notificationResponse.notificationResponseType}"
      "${notificationResponse.id}"
      "${notificationResponse.payload}");

  if (notificationResponse.payload!.isEmpty) return;
  String payload = notificationResponse.payload!;
  print("payload $payload");

  switch (notificationResponse.notificationResponseType) {
    case NotificationResponseType.selectedNotification:
      if (notificationResponse.payload != null) {
        if (notificationResponse.payload!.isEmpty) return;
        String payload = notificationResponse.payload!;
        print("payload $payload");
        storeNotificationClick.add(payload);
      }
      return;
    case NotificationResponseType.selectedNotificationAction:
      if (notificationResponse.actionId == TypePayload.reply.name) {
        print('selsai replay $payload');
        return;
      }

      if (notificationResponse.actionId == TypePayload.read.name) {
        print('selsai read $payload');
        return;
      }
  }
}

handleActionNotification(NotificationResponse notificationResponse) {
  switch (notificationResponse.actionId) {
  }
}

void showRemoteNotification(RemoteMessage message) async {
  final data = NotificationData.fromJson(message.data);
  var groupThis = data.ejson.rid;
  var nameHadTrim = data.title.toLowerCase().trim();
  var uniqueId = generateNumberFromString(nameHadTrim);
  print('uniqid from $nameHadTrim = $uniqueId');
  print('ridnya ini $groupThis');

  var notificationsInGroup = storeNotification.readValue(data.title) ?? [];

  List<String> body =
      notificationsInGroup.map((e) => e.message.toString()).toList();
  final summary =
      body.length == 1 ? data.message : '${body.length} new messages';

  List<AndroidNotificationAction> action = [
    AndroidNotificationAction(TypePayload.read.name, 'Mark as Read'),
    AndroidNotificationAction(TypePayload.reply.name, 'Reply',
        allowGeneratedReplies: true,
        inputs: [
          const AndroidNotificationActionInput(
              label: 'Reply', allowFreeFormInput: true)
        ])
  ];
  final AndroidNotificationDetails firstNotificationAndroidSpecifics =
      AndroidNotificationDetails(
    channel.id,
    channel.name,
    channelDescription: channel.description,
    importance: Importance.max,
    priority: Priority.high,
    groupKey: groupKey,
    ticker: 'test ticker',
    actions: action,
    styleInformation: InboxStyleInformation(body, contentTitle: data.title),
    tag: groupThis,
  );

  final NotificationDetails firstNotificationPlatformSpecifics =
      NotificationDetails(android: firstNotificationAndroidSpecifics);
  var success = await flutterLocalNotificationsPlugin.show(
      uniqueId, data.title, summary, firstNotificationPlatformSpecifics,
      payload: jsonEncode(notificationsInGroup.first.ejson));

  List<String> bodyGroup = storeNotification.myMap.entries.map((e) {
    final text = '${e.key}: ${e.value.length} new messages';
    print('fasdsd $text');
    return text;
  }).toList();
  List<NotificationData> combinedList =
      storeNotification.myMap.values.expand((i) => i).toList();
  var summaryGroup =
      '${combinedList.length} new message from ${storeNotification.myMap.length} chats';
  final AndroidNotificationDetails secondNotificationAndroidSpecifics =
      AndroidNotificationDetails(channel.id, channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.high,
          groupKey: groupKey,
          setAsGroupSummary: true,
          styleInformation:
              InboxStyleInformation(bodyGroup, summaryText: summaryGroup));
  final NotificationDetails secondNotificationPlatformSpecifics =
      NotificationDetails(android: secondNotificationAndroidSpecifics);
  success = await flutterLocalNotificationsPlugin.show(
      0, '', '', secondNotificationPlatformSpecifics);
}

void showDefaultLocalNotification({required String title, required messages}) {
  int hashCode = Random().nextInt(1000);

  final notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(channel.id, channel.name,
        channelDescription: channel.description,
        priority: Priority.max,
        importance: Importance.high,
        groupKey: groupKey),
  );

  flutterLocalNotificationsPlugin.show(
    hashCode,
    title,
    messages,
    notificationDetails,
  );
}

NotificationData? notificationDataFromJson(String str) =>
    NotificationData.fromJson(json.decode(str));

String notificationDataToJson(NotificationData? data) =>
    json.encode(data!.toJson());

class NotificationData {
  NotificationData({
    required this.image,
    required this.summaryText,
    required this.soundname,
    required this.style,
    required this.notId,
    required this.ejson,
    required this.title,
    required this.message,
    required this.msgcnt,
  });

  String image;
  String summaryText;
  String soundname;
  String style;
  String notId;
  NotificationEJson ejson;
  String title;
  String message;
  String msgcnt;

  factory NotificationData.fromJson(Map<String, dynamic> json) =>
      NotificationData(
        image: json["image"],
        summaryText: json["summaryText"],
        soundname: json["soundname"],
        style: json["style"],
        notId: json["notId"],
        ejson: NotificationEJson.fromJson(jsonDecode(json['ejson'])),
        title: json["title"],
        message: json["message"],
        msgcnt: json["msgcnt"],
      );

  Map<String, dynamic> toJson() => {
        "image": image,
        "summaryText": summaryText,
        "soundname": soundname,
        "style": style,
        "notId": notId,
        "ejson": ejson.toJson(),
        "title": title,
        "message": message,
        "msgcnt": msgcnt,
      };
}

NotificationEJson eJsonFromJson(String str) =>
    NotificationEJson.fromJson(json.decode(str));

class NotificationEJson {
  NotificationEJson({
    required this.host,
    required this.rid,
    required this.sender,
    required this.type,
    required this.messageId,
  });

  String host;
  String rid;
  Sender sender;
  String type;
  String messageId;

  factory NotificationEJson.fromJson(Map<String, dynamic> json) =>
      NotificationEJson(
        host: json["host"],
        rid: json["rid"],
        sender: Sender.fromJson(json["sender"]),
        type: json["type"],
        messageId: json["messageId"],
      );

  Map<String, dynamic> toJson() => {
        "host": host,
        "rid": rid,
        "sender": sender.toJson(),
        "type": type,
        "messageId": messageId,
      };
}

class Sender {
  Sender({
    required this.id,
    required this.username,
  });

  String id;
  String username;

  factory Sender.fromJson(Map<String, dynamic> json) => Sender(
        id: json["_id"],
        username: json["username"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "username": username,
      };
}

enum TypePayload { reply, read, click }

class StoreGlobalNotification {
  final Map<String, List<NotificationData>> _myMap = {};

  Map<String, List<NotificationData>> get myMap => _myMap;

  void createKeyValue(String key, List<NotificationData> value) {
    _myMap[key] = value;
  }

  List<NotificationData>? readValue(String key) {
    return _myMap[key];
  }

  void updateValue(String key, List<NotificationData> newValue) {
    if (_myMap.containsKey(key)) {
      var check = _myMap[key]!
          .where((element) =>
              element.ejson.messageId == newValue.first.ejson.messageId)
          .toList();
      if (check.isEmpty) _myMap[key]!.addAll(newValue);
    } else {
      createKeyValue(key, newValue);
    }
  }

  void deleteKey(String key) {
    _myMap.remove(key);
  }

  void deleteAll() {
    _myMap.clear();
  }
}

void showRemoteNotificationSchedule(RemoteMessage message) async {
  final data = NotificationData.fromJson(message.data);
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

  var scheduledNotificationDateTime =
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 1));
  var vibrationPattern = Int64List(4);
  vibrationPattern[0] = 0;
  vibrationPattern[1] = 1000;
  vibrationPattern[2] = 5000;
  vibrationPattern[3] = 2000;

  var groupThis = data.ejson.rid;
  var nameHadTrim = data.title.toLowerCase().trim();
  var uniqueId = generateNumberFromString(nameHadTrim);
  print('uniqid from $nameHadTrim = $uniqueId');
  print('ridnya ini $groupThis');

  var notificationsInGroup = storeNotification.readValue(data.title) ?? [];

  List<String> body =
      notificationsInGroup.map((e) => e.message.toString()).toList();
  final summary =
      body.length == 1 ? data.message : '${body.length} new messages';

  List<AndroidNotificationAction> action = [
    AndroidNotificationAction(TypePayload.read.name, 'Mark as Read'),
    AndroidNotificationAction(TypePayload.reply.name, 'Reply',
        allowGeneratedReplies: true,
        inputs: [
          const AndroidNotificationActionInput(
              label: 'Reply', allowFreeFormInput: true)
        ])
  ];

  final AndroidNotificationDetails firstNotificationAndroidSpecifics =
      AndroidNotificationDetails(
    channel.id,
    channel.name,
    channelDescription: channel.description,
    importance: Importance.max,
    priority: Priority.high,
    groupKey: groupKey,
    ticker: 'test ticker',
    actions: action,
    styleInformation: InboxStyleInformation(body, contentTitle: data.title),
    tag: groupThis,
  );
  final NotificationDetails firstNotificationPlatformSpecifics =
      NotificationDetails(android: firstNotificationAndroidSpecifics);
  var success = await flutterLocalNotificationsPlugin.zonedSchedule(
      message.hashCode,
      data.title,
      data.message,
      scheduledNotificationDateTime,
      firstNotificationPlatformSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode(data.ejson));

  List<String> bodyGroup = storeNotification.myMap.entries.map((e) {
    final text = '${e.key}: ${e.value.length} new messages';
    print('fasdsd $text');
    return text;
  }).toList();
  List<NotificationData> combinedList =
      storeNotification.myMap.values.expand((i) => i).toList();
  var summaryGroup =
      '${combinedList.length} new message from ${storeNotification.myMap.length} chats';
  final AndroidNotificationDetails secondNotificationAndroidSpecifics =
      AndroidNotificationDetails(channel.id, channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.high,
          groupKey: groupKey,
          setAsGroupSummary: true,
          styleInformation:
              InboxStyleInformation(bodyGroup, summaryText: summaryGroup));
  final NotificationDetails secondNotificationPlatformSpecifics =
      NotificationDetails(android: secondNotificationAndroidSpecifics);
  success = await flutterLocalNotificationsPlugin.show(
      0, '', '', secondNotificationPlatformSpecifics);
}

void showRemoteNotificationOnly(RemoteMessage message) async {
  final data = NotificationData.fromJson(message.data);
  var groupThis = data.ejson.rid;
  var nameHadTrim = data.title.toLowerCase().trim();
  var uniqueId = generateNumberFromString(nameHadTrim);
  print('uniqid from $nameHadTrim = $uniqueId');
  print('ridnya ini $groupThis');

  List<ActiveNotification> activeNotifications =
      await flutterLocalNotificationsPlugin.getActiveNotifications();
  List<String> body = [];
  if (activeNotifications.isEmpty){
    body.add(data.message);
  } else {
    for (ActiveNotification active in activeNotifications) {
      if (active.id == uniqueId){
        List<String> list = [active.body!, data.message];
        body.addAll(list);
      }
    }
  }


  // var notificationsInGroup = storeNotification.readValue(data.title) ?? [];
  //
  // List<String> body =
  //     notificationsInGroup.map((e) => e.message.toString()).toList();
  final summary =
      body.length == 1 ? data.message : '${body.length} new messages';

  List<AndroidNotificationAction> action = [
    AndroidNotificationAction(TypePayload.read.name, 'Mark as Read'),
    AndroidNotificationAction(TypePayload.reply.name, 'Reply',
        allowGeneratedReplies: true,
        inputs: [
          const AndroidNotificationActionInput(
              label: 'Reply', allowFreeFormInput: true)
        ])
  ];
  final AndroidNotificationDetails firstNotificationAndroidSpecifics =
      AndroidNotificationDetails(
    channel.id,
    channel.name,
    channelDescription: channel.description,
    importance: Importance.max,
    priority: Priority.high,
    groupKey: groupKey,
    ticker: 'test ticker',
    actions: action,
    styleInformation: InboxStyleInformation(body, contentTitle: data.title),
    tag: groupThis,
  );

  final NotificationDetails firstNotificationPlatformSpecifics =
      NotificationDetails(android: firstNotificationAndroidSpecifics);
  var success = await flutterLocalNotificationsPlugin.show(
      uniqueId, data.title, summary, firstNotificationPlatformSpecifics,
      payload: jsonEncode(data.ejson));
}
