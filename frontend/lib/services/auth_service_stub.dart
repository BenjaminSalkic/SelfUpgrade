void saveHashOnStartup() {
  // No-op on mobile
}

String getSavedHash() {
  return '';
}

void redirectToUrl(String url) {
  throw UnsupportedError('Web-only feature');
}

String getLocationHash() {
  return '';
}

String getLocationPathname() {
  return '/';
}

void replaceHistoryState() {
}
