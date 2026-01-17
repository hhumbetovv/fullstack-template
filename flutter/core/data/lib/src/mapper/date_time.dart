extension DateTimeModelMapper on DateTime {
  int toModel() => millisecondsSinceEpoch;
}

extension DateTimeEntityMapper on int? {
  DateTime toEntity() => DateTime.fromMillisecondsSinceEpoch(this ?? 0);
}
