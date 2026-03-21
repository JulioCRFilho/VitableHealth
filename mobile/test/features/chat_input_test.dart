// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/i_am_on_the_chat_screen.dart';
import './step/i_enter_into_the_message_input.dart';
import './step/i_tap_the_send_button.dart';
import './step/i_should_see_messages_in_the_chat_list.dart';
import './step/i_should_see_in_the_chat_list.dart';

void main() {
  group('''Chat Input Sanity''', () {
    testWidgets('''Trim and Validate whitespace-only messages''',
        (tester) async {
      await iAmOnTheChatScreen(tester);
      await iEnterIntoTheMessageInput(tester, "   ");
      await iTapTheSendButton(tester);
      await iShouldSeeMessagesInTheChatList(tester, 1);
    });
    testWidgets('''Handle UTF-8 and Emojis''', (tester) async {
      await iAmOnTheChatScreen(tester);
      await iEnterIntoTheMessageInput(tester, "Test 🧪 ⚡ 漢字");
      await iTapTheSendButton(tester);
      await iShouldSeeMessagesInTheChatList(tester, 3);
      await iShouldSeeInTheChatList(tester, "Test 🧪 ⚡ 漢字");
    });
  });
}
