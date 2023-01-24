
  @override
  void onInit() {
    final _app = Get.find<ChatAppService>();
    // storeNotificationClick.listen((payload) {
    //   print('iniyg diKlik ya $payload');
    // });

    // final NotificationAppLaunchDetails? notificationAppLaunchDetails =
    //     await localNotificationsPlugin.getNotificationAppLaunchDetails();
    // final didNotificationLaunchApp =
    //     notificationAppLaunchDetails?.didNotificationLaunchApp ?? false;
    // if (didNotificationLaunchApp) {
    //   final resNotification = notificationAppLaunchDetails?.notificationResponse;
    //   if (resNotification != null) onSelectNotification(resNotification);
    // }

    // Stream<RemoteMessage> _stream = FirebaseMessaging.onMessageOpenedApp;

    storeNotificationClick.stream.listen((event) async {
      print('iniyg diKlik ya $event');
      CommonWidget.shortToast('show notif $event');
      if (event == '') return;
      final res = jsonDecode(event);
      final title =res['sender']['username'];
      print('iniyg diKlik routee ${Get.currentRoute}');

      ChatRoom roomChat = await _app.chatRoomByUsername(title);
      _app.openRoom(room: roomChat);
      if (Get.currentRoute == MainPage.namePath) {
        Get.toNamed(RoomChatUi.namePath, arguments: roomChat);
        storeNotificationClick.add('');
        return;
      } else {
        await Get.offAllNamed(MainPage.namePath);
        await Get.offAndToNamed(RoomChatUi.namePath, arguments: roomChat);
        storeNotificationClick.add('');
        return;
      }
    });
    super.onInit();

  }
