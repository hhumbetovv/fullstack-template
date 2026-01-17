import 'package:core_navigation/src/result/view_model.dart';
import 'package:core_presentation/exports.dart';

extension ResultContextExtension on BuildContext {
  void setResult<T extends Object>(T value) {
    ResultIntent.setResult(T, value).dispatch(this);
  }

  void clearResult<T extends Object>() {
    ResultIntent.clearResult(T).dispatch(this);
  }

  void clearAllResults() {
    const ResultIntent.clearAllResults().dispatch(this);
  }
}
