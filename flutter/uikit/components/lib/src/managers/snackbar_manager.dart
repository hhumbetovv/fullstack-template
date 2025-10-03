import 'package:common_presentation/config.dart';
import 'package:common_presentation/public.dart';
import 'package:common_shared/public.dart';

class SnackBarManager {
  static void show(String message, [MessageType type = MessageType.info]) {
    messengerKey.currentState?.showSnackBar(
      CommonPresentationConfig().snackBarBuilder(message, type),
    );
  }

  static void showError(String message) => show(message, MessageType.error);
  static void showInfo(String message) => show(message);
  static void showSuccess(String message) => show(message, MessageType.success);
}
