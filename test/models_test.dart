import 'package:flutter_test/flutter_test.dart';
import 'package:lingayat_matrimony/models.dart';

void main() {
  test('profile serialises core fields', () {
    final profile = Profile(id: '1', name: 'A', gender: 'bride', age: 25, city: 'Pune');
    expect(profile.toMap()['gender'], 'bride');
    expect(Profile.fromMap({...profile.toMap(), 'status': 'approved'}).city, 'Pune');
  });
}
