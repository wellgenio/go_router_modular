import 'dart:html' as html;

void replaceBrowserUrl(String url) {
  html.window.history.replaceState(null, '', url);
}
