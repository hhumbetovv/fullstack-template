import 'package:core_data/src/model/remote/action_model.dart';
import 'package:core_domain/public.dart';

extension ActionModelExt on ActionModel {
  Action toEntity() {
    return Action.values.firstWhere(
      (element) => element.name == name,
      orElse: () {
        throw Exception('Entity not found for this model: $this');
      },
    );
  }
}

extension ActionExt on Action {
  ActionModel toModel() {
    return ActionModel.values.firstWhere(
      (element) => element.name == name,
      orElse: () {
        throw Exception('Model not found for this entity: $this');
      },
    );
  }
}
