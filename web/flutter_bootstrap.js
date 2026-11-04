{{flutter_js}}
{{flutter_build_config}}

// The web app loads nothing from other sites (r-06, ADR-043). CanvasKit is
// bundled (--no-web-resources-cdn) and Roboto is an app font; a character
// missing from it would make the engine fetch a Noto font from this base
// URL, which stays on this site instead of fonts.gstatic.com.
_flutter.loader.load({
  config: {
    fontFallbackBaseUrl: 'assets/fonts/fallback/',
  },
});
