import 'package:flutter_app/modules/auth/domain/entities/register.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/service_locator.dart';
import '../../domain/usecase/create_user.dart';
import '../../domain/entities/user.dart';

class RegisterViewModel extends StateNotifier<RegisterState> {
  final CreateUser createUser;

  RegisterViewModel(this.createUser) : super(RegisterState());

  Future<void> register(String name, String role) async {
    final user = User(id: DateTime.now().toString(), name: name, role: role);
    await createUser(user);
    state = RegisterState(isRegistered: true);
  }
}

final registerViewModelProvider = StateNotifierProvider<RegisterViewModel, RegisterState>((ref) {
  return RegisterViewModel(ref.read(createUserProvider));
});