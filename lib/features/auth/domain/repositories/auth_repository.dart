import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Stream<UserEntity?> get user;
}
