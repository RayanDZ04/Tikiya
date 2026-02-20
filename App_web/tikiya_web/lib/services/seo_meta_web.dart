import 'dart:html' as html;

class SeoMeta {
  static void set({required String title, required String description}) {
    html.document.title = title;
    _setNamedMeta('description', description);
    _setPropertyMeta('og:title', title);
    _setPropertyMeta('og:description', description);
    _setNamedMeta('twitter:title', title);
    _setNamedMeta('twitter:description', description);

    final origin = html.window.location.origin;
    final path = html.window.location.pathname;
    _setCanonical('$origin$path');
  }

  static void _setNamedMeta(String name, String content) {
    final existing = html.document.querySelector('meta[name="$name"]') as html.MetaElement?;
    if (existing != null) {
      existing.content = content;
      return;
    }
    final meta = html.MetaElement()
      ..name = name
      ..content = content;
    html.document.head?.append(meta);
  }

  static void _setPropertyMeta(String property, String content) {
    final existing =
        html.document.querySelector('meta[property="$property"]') as html.MetaElement?;
    if (existing != null) {
      existing.content = content;
      return;
    }
    final meta = html.MetaElement()
      ..setAttribute('property', property)
      ..content = content;
    html.document.head?.append(meta);
  }

  static void _setCanonical(String href) {
    final existing = html.document.querySelector('link[rel="canonical"]') as html.LinkElement?;
    if (existing != null) {
      existing.href = href;
      return;
    }
    final link = html.LinkElement()
      ..rel = 'canonical'
      ..href = href;
    html.document.head?.append(link);
  }
}
