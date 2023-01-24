
  ///TODO belum selesai
  removeNotification() async {
    final room = state.roomChat.value;
    var nameHadTrim = room.username.toLowerCase().trim();
    var uniqueId = generateNumberFromString(nameHadTrim);
    print('uniqid from $nameHadTrim = $uniqueId');

    List<ActiveNotification> activeNotifications =
        await flutterLocalNotificationsPlugin.getActiveNotifications();
    print('activeNotifications banyak ${activeNotifications.length}');

    final myMap = await isolateReadMap();
    print('storeMapMessages banyak ${myMap.length}');
    // if (storeMapMessages.containsKey(room.username)) {
    //   if (storeMapMessages.length == 1) {
    //     await flutterLocalNotificationsPlugin.cancelAll();
    //     storeMapMessages.clear();
    //     return;
    //   }
    //   await flutterLocalNotificationsPlugin.cancel(uniqueId,
    //       tag: room.idChatRoom);
    //   storeMapMessages.remove(room.username);
    // }
  }
