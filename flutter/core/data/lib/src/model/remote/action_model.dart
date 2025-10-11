import 'package:json_annotation/json_annotation.dart';

enum ActionModel {
  @JsonValue('CREATE_PROFILE')
  createProfile,
  @JsonValue('SIGN_PRIVACY_AND_TERMS')
  signPrivacyAndTerms,
  @JsonValue('LOGOUT')
  logout,
}
