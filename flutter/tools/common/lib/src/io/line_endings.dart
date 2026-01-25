const String _lf = '\n';
const String _crlf = '\r\n';

/// Determines the preferred line ending derived from [existingContent].
/// Defaults to LF to stay aligned with repository defaults while still
/// preserving CRLF copies locally when present.
String preferredLineEndingForContent(String? existingContent) {
  if (existingContent == null || existingContent.isEmpty) {
    return _lf;
  }
  if (existingContent.contains(_crlf)) {
    return _crlf;
  }
  if (existingContent.contains(_lf)) {
    return _lf;
  }
  return _lf;
}

/// Normalizes [content] to LF, then reapplies [preferredLineEnding] if provided.
/// This keeps committed files in LF while letting local worktrees retain their
/// platform-specific endings.
String normalizeLineEndings(
  String content, {
  String? preferredLineEnding,
}) {
  final normalized = content.replaceAll(_crlf, _lf);
  final lineEnding = preferredLineEnding ?? _lf;
  if (lineEnding == _lf) {
    return normalized;
  }
  return normalized.replaceAll(_lf, lineEnding);
}
