class Paged<T> {
  const Paged({
    required this.content,
    required this.number,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.firstPage,
    required this.lastPage,
  });

  final List<T> content;
  final int number;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool firstPage;
  final bool lastPage;
}

extension PagedMapper<T> on Paged<T> {
  Paged<R> map<R>(R Function(T) mapper) {
    return Paged(
      content: content.map(mapper).toList(),
      number: number,
      size: size,
      totalElements: totalElements,
      totalPages: totalPages,
      firstPage: firstPage,
      lastPage: lastPage,
    );
  }
}
