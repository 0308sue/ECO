import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front/core/widgets/auth_scaffold.dart';

void main() {
  testWidgets('AuthScaffold shows title and child content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AuthScaffold(
          title: '로그인',
          subtitle: '테스트 안내 문구',
          child: Text('폼 영역'),
        ),
      ),
    );

    expect(find.text('로그인'), findsOneWidget);
    expect(find.text('테스트 안내 문구'), findsOneWidget);
    expect(find.text('폼 영역'), findsOneWidget);
  });
}