import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/main.dart';
import 'package:mobile/providers/vpn_provider.dart';

void main() {
  testWidgets('Argus VPN App loads Dashboard and Shield screens', (WidgetTester tester) async {
    // Set a mobile screen dimension so all list items fit
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => VpnProvider()),
        ],
        child: const ArgusVpnApp(),
      ),
    );

    // Verify Title & Initial State
    expect(find.text('ARGUS VPN'), findsOneWidget);
    expect(find.text('PROTECTION OFF'), findsOneWidget);
    expect(find.text('Tap to Connect'), findsOneWidget);

    // Switch to Argus Shield Tab
    await tester.tap(find.text('Shield'));
    await tester.pumpAndSettle();

    // Verify Content Filtering Options
    expect(find.text('ARGUS SHIELD'), findsOneWidget);
    expect(find.text('Block Adult & Porn Sites'), findsOneWidget);
    expect(find.text('Block Betting & Gambling'), findsOneWidget);
    expect(find.text('Block Social Networks'), findsOneWidget);
    expect(find.text('Block Ads & Data Trackers'), findsOneWidget);
    expect(find.text('Malware & Phishing Protection'), findsOneWidget);

    // Toggle Adult content block switch
    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(5));
    await tester.tap(switches.first);
    await tester.pumpAndSettle();
  });
}
