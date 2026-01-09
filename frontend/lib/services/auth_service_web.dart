import 'dart:html' as html;

String? _savedHash;

void saveHashOnStartup() {
  if (_savedHash == null && html.window.location.hash.isNotEmpty) {
    _savedHash = html.window.location.hash;
  }
}

String getSavedHash() {
  return _savedHash ?? '';
}

void redirectToUrl(String url) {
  html.window.location.href = url;
}

String getLocationHash() {
  return html.window.location.hash;
}

String getLocationPathname() {
  return html.window.location.pathname ?? '/';
}

void replaceHistoryState() {
  html.window.history.replaceState(null, '', html.window.location.pathname);
}
