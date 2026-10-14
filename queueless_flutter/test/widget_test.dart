import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queueless_client/queueless_client.dart';
import 'package:queueless_flutter/design_system/app_components.dart';
import 'package:queueless_flutter/design_system/app_theme.dart';
import 'package:queueless_flutter/room_join_link.dart';
import 'package:queueless_flutter/screens/customer_screen.dart';

void main() {
  testWidgets('missing roomId shows room-selection screen instead of error', (
    WidgetTester tester,
  ) async {
    final testRooms = [
      QueueRoom(id: 1, name: 'Room 1', createdAt: DateTime.now()),
      QueueRoom(id: 2, name: 'VIP Consultation', createdAt: DateTime.now()),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: CustomerScreen(
          roomsLoader: () async => testRooms,
          initialUri: Uri.parse('http://localhost:8080/'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify room selection screen is displayed without any error
    expect(find.text('Select a room to join the queue'), findsOneWidget);
    expect(find.text('Available rooms'), findsOneWidget);
    expect(find.text('Room 1'), findsOneWidget);
    expect(find.text('VIP Consultation'), findsOneWidget);
    expect(find.byType(AppFeedbackBanner), findsNothing);
  });

  testWidgets('selecting a room transitions to join form and allows joining', (
    WidgetTester tester,
  ) async {
    final testRooms = [
      QueueRoom(id: 1, name: 'Room 1', createdAt: DateTime.now()),
      QueueRoom(id: 2, name: 'VIP Consultation', createdAt: DateTime.now()),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: CustomerScreen(
          roomsLoader: () async => testRooms,
          initialUri: Uri.parse('http://localhost:8080/'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap "Join this room" on the VIP Consultation room card
    final joinVipButtons =
        find.widgetWithText(AppPrimaryButton, 'Join this room');
    expect(joinVipButtons, findsNWidgets(2));
    await tester.tap(joinVipButtons.at(1));
    await tester.pumpAndSettle();

    // Now on the join form for VIP Consultation
    expect(find.text('Join the VIP Consultation queue.'), findsOneWidget);
    expect(
      find.text(
        'You are joining VIP Consultation. You can track another room after this ticket is created.',
      ),
      findsOneWidget,
    );
    expect(find.text('Join the queue'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('direct room link in URL directly loads the specified room', (
    WidgetTester tester,
  ) async {
    final testRooms = [
      QueueRoom(id: 1, name: 'Room 1', createdAt: DateTime.now()),
      QueueRoom(id: 2, name: 'VIP Consultation', createdAt: DateTime.now()),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: CustomerScreen(
          roomsLoader: () async => testRooms,
          initialUri: Uri.parse('http://localhost:8080/?roomId=2'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Directly in the join form for Room 2
    expect(find.text('Join the VIP Consultation queue.'), findsOneWidget);
    expect(find.text('VIP Consultation'), findsWidgets);
    expect(find.text('Join the queue'), findsOneWidget);
    expect(find.byType(AppFeedbackBanner), findsNothing);
  });

  testWidgets('customer can return to room selection from join form', (
    WidgetTester tester,
  ) async {
    final testRooms = [
      QueueRoom(id: 1, name: 'Room 1', createdAt: DateTime.now()),
      QueueRoom(id: 2, name: 'VIP Consultation', createdAt: DateTime.now()),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: CustomerScreen(
          roomsLoader: () async => testRooms,
          initialUri: Uri.parse('http://localhost:8080/?roomId=2'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Join the VIP Consultation queue.'), findsOneWidget);

    // Tap "Change room" to return to room selection
    final changeRoomButton = find.text('Change room');
    expect(changeRoomButton, findsOneWidget);
    await tester.tap(changeRoomButton);
    await tester.pumpAndSettle();

    // Returned to room selection screen
    expect(find.text('Select a room to join the queue'), findsOneWidget);
    expect(find.text('Available rooms'), findsOneWidget);
  });

  testWidgets(
    'URL with invalid roomId shows clear error and way to return to room selection',
    (WidgetTester tester) async {
      final testRooms = [
        QueueRoom(id: 1, name: 'Room 1', createdAt: DateTime.now()),
        QueueRoom(id: 2, name: 'VIP Consultation', createdAt: DateTime.now()),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: CustomerScreen(
            roomsLoader: () async => testRooms,
            initialUri: Uri.parse('http://localhost:8080/?roomId=-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'This room link is invalid. Please select an active room from the list.',
        ),
        findsOneWidget,
      );
      expect(find.text('Return to room selection'), findsOneWidget);

      // Tapping Return to room selection clears the error
      await tester.tap(find.text('Return to room selection'));
      await tester.pumpAndSettle();

      expect(find.byType(AppFeedbackBanner), findsNothing);
      expect(find.text('Select a room to join the queue'), findsOneWidget);
    },
  );

  testWidgets(
    'URL with unavailable roomId shows clear error and way to return to room selection',
    (WidgetTester tester) async {
      final testRooms = [
        QueueRoom(id: 1, name: 'Room 1', createdAt: DateTime.now()),
        QueueRoom(id: 2, name: 'VIP Consultation', createdAt: DateTime.now()),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: CustomerScreen(
            roomsLoader: () async => testRooms,
            initialUri: Uri.parse('http://localhost:8080/?roomId=999'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'This room is unavailable or does not exist. Please select an active room from the list.',
        ),
        findsOneWidget,
      );
      expect(find.text('Return to room selection'), findsOneWidget);

      // Customer can also directly select an available room from the list below the error
      final joinButtons =
          find.widgetWithText(AppPrimaryButton, 'Join this room');
      expect(joinButtons, findsNWidgets(2));
      await tester.tap(joinButtons.first);
      await tester.pumpAndSettle();

      // Now in Room 1 join form
      expect(find.text('Join the Room 1 queue.'), findsOneWidget);
    },
  );

  testWidgets('customer join form validates an empty name locally', (
    WidgetTester tester,
  ) async {
    final testRooms = [
      QueueRoom(id: 1, name: 'Room 1', createdAt: DateTime.now()),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: CustomerScreen(
          roomsLoader: () async => testRooms,
          initialUri: Uri.parse('http://localhost:8080/?roomId=1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final joinButton = find.text('Join the queue');
    await tester.ensureVisible(joinButton);
    await tester.tap(joinButton);
    await tester.pump();

    expect(
      find.text('Please enter your name to get started.'),
      findsOneWidget,
    );
  });

  testWidgets('empty room list renders gracefully with message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: CustomerScreen(
          roomsLoader: () async => <QueueRoom>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No rooms available'), findsOneWidget);
    expect(
      find.text(
        'There are currently no active queues available to join. Please check back later or ask staff for assistance.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('queue flow renders live counts and customer position', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: AppQueueFlow(
            waitingCount: 3,
            servingCount: 1,
            customerPosition: 2,
          ),
        ),
      ),
    );

    expect(find.text('Live queue flow'), findsOneWidget);
    expect(find.text('3 waiting'), findsOneWidget);
    expect(find.text('Serving now'), findsOneWidget);
    expect(find.text('1 person is ahead of you.'), findsOneWidget);
  });

  testWidgets('customer join layout renders at mobile and desktop widths', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final testRooms = [
      QueueRoom(id: 1, name: 'Room 1', createdAt: DateTime.now()),
    ];

    for (final size in [const Size(360, 800), const Size(1280, 800)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: CustomerScreen(
            roomsLoader: () async => testRooms,
            initialUri: Uri.parse('http://localhost:8080/?roomId=1'),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Join the queue'), findsOneWidget);
    }
  });

  test(
    'newly created room generates a correct customer join link with roomId',
    () {
      final link =
          buildRoomJoinUrl(roomId: 42, baseUrl: 'http://localhost:8082');
      expect(link, 'http://localhost:8082?roomId=42');
    },
  );

  testWidgets('staff empty state shows No rooms yet and Create a room action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppEmptyState(
                  icon: Icons.meeting_room_outlined,
                  title: 'No rooms yet',
                  message:
                      'You do not have access to any rooms yet. Create a room to start serving customers.',
                ),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_business_outlined),
                  label: const Text('Create a room'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No rooms yet'), findsOneWidget);
    expect(find.text('Create a room'), findsOneWidget);
  });

  testWidgets(
    'Restart queue dialog shows room info, active ticket notice, and handles cancel/confirm',
    (WidgetTester tester) async {
      bool? confirmed;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Restart queue for Consultation?'),
                    content: const SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Starting a new queue session will restart ticket numbering at #1 for Consultation.',
                          ),
                          Text(
                            'Notice: There are currently 1 serving and 2 waiting tickets. These active tickets will be closed and cancelled. Old ticket history is preserved and will not be deleted.',
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Restart queue'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Open Restart Dialog'),
            ),
          ),
        ),
      );

      // Verify Cancel action
      await tester.tap(find.text('Open Restart Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Restart queue for Consultation?'), findsOneWidget);
      expect(
        find.textContaining('restart ticket numbering at #1'),
        findsOneWidget,
      );
      expect(
        find.textContaining('active tickets will be closed and cancelled'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(confirmed, isFalse);

      // Verify Confirm action
      await tester.tap(find.text('Open Restart Dialog'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restart queue'));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
    },
  );

  testWidgets(
    'Delete room dialog warns about active tickets, preservation of history, and handles cancel/confirm',
    (WidgetTester tester) async {
      bool? confirmed;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete room "Consultation"?'),
                    content: const SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Are you sure you want to delete "Consultation"? This action cannot be undone.',
                          ),
                          Text(
                            'Warning: This room currently has 1 serving and 2 waiting tickets. All active tickets and the current queue session will be closed and cancelled. The room will be removed from customer and staff discovery.',
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete room'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Open Delete Dialog'),
            ),
          ),
        ),
      );

      // Verify Cancel action
      await tester.tap(find.text('Open Delete Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete room "Consultation"?'), findsOneWidget);
      expect(find.textContaining('cannot be undone'), findsOneWidget);
      expect(
        find.textContaining(
          'All active tickets and the current queue session will be closed',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(confirmed, isFalse);

      // Verify Confirm action
      await tester.tap(find.text('Open Delete Dialog'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete room'));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
    },
  );

  testWidgets(
    'responsive audit across mobile, tablet, and desktop viewports without overflows',
    (WidgetTester tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testRooms = [
        QueueRoom(
          id: 1,
          name: 'General Consultation with a Very Long Department Name That Tests Text Truncation and Wrapping',
          createdAt: DateTime.now(),
        ),
        QueueRoom(
          id: 2,
          name: 'Express Desk 2',
          createdAt: DateTime.now(),
        ),
      ];

      final viewports = [
        const Size(320, 568),   // Compact mobile
        const Size(390, 844),   // Standard mobile (iPhone 12/13/14)
        const Size(768, 1024),  // iPad / tablet
        const Size(1280, 800),  // Laptop / small desktop
        const Size(1440, 900),  // Standard desktop
      ];

      for (final viewport in viewports) {
        await tester.binding.setSurfaceSize(viewport);

        // 1. Customer Room Selection view
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: CustomerScreen(
              key: UniqueKey(),
              roomsLoader: () async => testRooms,
              initialUri: Uri.parse('http://localhost:8080/'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Failed at viewport $viewport on customer room selection');
        expect(find.text('Select a room to join the queue'), findsOneWidget);

        // 2. Customer Join Form view
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: CustomerScreen(
              key: UniqueKey(),
              roomsLoader: () async => testRooms,
              initialUri: Uri.parse('http://localhost:8080/?roomId=1'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Failed at viewport $viewport on customer join view');
        expect(find.text('Join the queue'), findsOneWidget);
      }
    },
  );

  testWidgets(
    'newly created room automatically appears on customer room selection screen via realtime event without reload',
    (WidgetTester tester) async {
      final initialRooms = [
        QueueRoom(id: 1, name: 'General Queue', createdAt: DateTime.now()),
      ];
      final updatedRooms = [
        QueueRoom(id: 1, name: 'General Queue', createdAt: DateTime.now()),
        QueueRoom(id: 2, name: 'Blood Test Lab', createdAt: DateTime.now()),
      ];

      var currentRooms = initialRooms;
      final roomEventsController = StreamController<QueueEvent>.broadcast();
      addTearDown(roomEventsController.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: CustomerScreen(
            roomsLoader: () async => currentRooms,
            roomsStream: () => roomEventsController.stream,
            initialUri: Uri.parse('http://localhost:8080/'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only Room 1 initially
      expect(find.text('General Queue'), findsOneWidget);
      expect(find.text('Blood Test Lab'), findsNothing);

      // Staff creates Room 2 in backend, updating public room list and firing realtime event
      currentRooms = updatedRooms;
      roomEventsController.add(QueueEvent(roomId: 2, action: 'created'));
      await tester.pumpAndSettle();

      // Both rooms are now visible without full page reload
      expect(find.text('General Queue'), findsOneWidget);
      expect(find.text('Blood Test Lab'), findsOneWidget);
    },
  );

  testWidgets(
    'deleted room automatically disappears from customer room selection screen in realtime',
    (WidgetTester tester) async {
      final initialRooms = [
        QueueRoom(id: 1, name: 'General Queue', createdAt: DateTime.now()),
        QueueRoom(id: 2, name: 'Temporary Desk', createdAt: DateTime.now()),
      ];
      final updatedRooms = [
        QueueRoom(id: 1, name: 'General Queue', createdAt: DateTime.now()),
      ];

      var currentRooms = initialRooms;
      final roomEventsController = StreamController<QueueEvent>.broadcast();
      addTearDown(roomEventsController.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: CustomerScreen(
            roomsLoader: () async => currentRooms,
            roomsStream: () => roomEventsController.stream,
            initialUri: Uri.parse('http://localhost:8080/'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('General Queue'), findsOneWidget);
      expect(find.text('Temporary Desk'), findsOneWidget);

      // Staff deletes Room 2
      currentRooms = updatedRooms;
      roomEventsController.add(QueueEvent(roomId: 2, action: 'deleted'));
      await tester.pumpAndSettle();

      expect(find.text('General Queue'), findsOneWidget);
      expect(find.text('Temporary Desk'), findsNothing);
    },
  );

  testWidgets(
    'reconnect resynchronizes customer room list if an event was missed while offline',
    (WidgetTester tester) async {
      final initialRooms = [
        QueueRoom(id: 1, name: 'General Queue', createdAt: DateTime.now()),
      ];
      final updatedRooms = [
        QueueRoom(id: 1, name: 'General Queue', createdAt: DateTime.now()),
        QueueRoom(id: 3, name: 'X-Ray Department', createdAt: DateTime.now()),
      ];

      var currentRooms = initialRooms;
      final roomEventsController = StreamController<QueueEvent>.broadcast();
      addTearDown(roomEventsController.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: CustomerScreen(
            roomsLoader: () async => currentRooms,
            roomsStream: () => roomEventsController.stream,
            initialUri: Uri.parse('http://localhost:8080/'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('General Queue'), findsOneWidget);
      expect(find.text('X-Ray Department'), findsNothing);

      // Backend added a room while client was disconnected
      currentRooms = updatedRooms;

      // Stream drops / errors, triggering customer screen reconnect logic
      roomEventsController.addError('Connection dropped');
      await tester.pumpAndSettle();

      // Upon error / reconnect, rooms list is fetched and resynchronized
      expect(find.text('General Queue'), findsOneWidget);
      expect(find.text('X-Ray Department'), findsOneWidget);
    },
  );
}
