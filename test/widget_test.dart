import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:srms/app.dart';
import 'package:srms/data/mock_users.dart';
import 'package:srms/screens/failure_queue_screen.dart';
import 'package:srms/screens/report_issue_screen.dart';
import 'package:srms/services/api_client.dart';

ApiClient _api(Future<http.Response> Function(http.Request) handler) =>
    ApiClient(client: MockClient(handler), baseUrl: 'http://test');

Future<void> _fillReport(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Projector not working');
  await tester.enterText(fields.at(1), 'Science Building - Room 204');
  await tester.enterText(fields.at(2), 'The projector will not turn on at all');
}

void main() {
  group('ApiClient error mapping', () {
    test('network failure becomes NetworkException', () async {
      final api = _api((_) => throw http.ClientException('offline'));
      expect(api.listIssues(), throwsA(isA<NetworkException>()));
    });

    test('5xx becomes ServerException', () async {
      final api = _api((_) async => http.Response('{"error":"x"}', 503));
      expect(api.listIssues(), throwsA(isA<ServerException>()));
    });

    test('400 becomes ValidationException with details', () async {
      final api = _api((_) async => http.Response(
          jsonEncode({'error': 'Invalid', 'details': ['title is required']}),
          400));
      await expectLater(
        api.createIssue(
            reporterId: 'u1', title: 't', location: 'l', description: 'd'),
        throwsA(isA<ValidationException>()
            .having((e) => e.details, 'details', ['title is required'])),
      );
    });

    test('403 becomes ForbiddenException', () async {
      final api = _api((_) async => http.Response('{"error":"no"}', 403));
      expect(api.listFailures(actorId: 'u1'), throwsA(isA<ForbiddenException>()));
    });

    test('duplicate response is returned, not thrown', () async {
      final api = _api((_) async => http.Response(
          jsonEncode({
            'duplicate': true,
            'message': 'similar',
            'existingIssue': {'id': '9', 'title': 'Old', 'status': 'reported'},
          }),
          200));
      final r = await api.createIssue(
          reporterId: 'u1', title: 't', location: 'l', description: 'd');
      expect(r.duplicate?.existingId, '9');
      expect(r.issue, isNull);
    });
  });

  group('Screens', () {
    testWidgets('login shows validation messages when empty', (tester) async {
      await tester.pumpWidget(const SrmsApp());
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pump();
      expect(find.text('Enter your email.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
    });

    testWidgets('report form blocks short input before calling the API',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var called = false;
      final api = _api((_) async {
        called = true;
        return http.Response('{}', 500);
      });
      await tester.pumpWidget(MaterialApp(
          home: ReportIssueScreen(user: MockUsers.all.first, api: api)));
      await tester.tap(find.text('Submit report'));
      await tester.pump();
      expect(find.textContaining('needs at least'), findsWidgets);
      expect(called, isFalse);
    });

    testWidgets('report form shows the duplicate notice', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final api = _api((_) async => http.Response(
          jsonEncode({
            'duplicate': true,
            'existingIssue': {'id': '9', 'title': 'Old', 'status': 'reported'},
          }),
          200));
      await tester.pumpWidget(MaterialApp(
          home: ReportIssueScreen(user: MockUsers.all.first, api: api)));
      await _fillReport(tester);
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();
      expect(find.text('Similar issue already reported'), findsOneWidget);
    });

    testWidgets('report form shows a network error message', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final api = _api((_) => throw http.ClientException('offline'));
      await tester.pumpWidget(MaterialApp(
          home: ReportIssueScreen(user: MockUsers.all.first, api: api)));
      await _fillReport(tester);
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Cannot reach the server'), findsOneWidget);
    });

    testWidgets('student cannot open the automation queue', (tester) async {
      final api = _api((_) async => http.Response('[]', 200));
      await tester.pumpWidget(MaterialApp(
          home: FailureQueueScreen(user: MockUsers.all.first, api: api)));
      await tester.pump();
      expect(find.textContaining('Only coordinators'), findsOneWidget);
    });
  });
}
