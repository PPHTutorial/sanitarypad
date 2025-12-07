enum PosterSize {
  w92('w92'),
  w154('w154'),
  w185('w185'),
  w342('w342'),
  w500('w500'),
  w780('w780'),
  original('original');
  final String value;
  const PosterSize(this.value);
}

enum BackdropSize {
  w300('w300'),
  w780('w780'),
  w1280('w1280'),
  original('original');
  final String value;
  const BackdropSize(this.value);
}

class TMDBEndpoints {
  static const String imageBase = 'https://image.tmdb.org/t/p';

  static String _ensureSizedUrl(String raw, String size) {
    if (raw.isEmpty) return '';
    // If full URL, try to normalize by replacing the size segment
    if (raw.startsWith('http')) {
      final idx = raw.indexOf('/t/p/');
      if (idx != -1) {
        final after = raw.substring(idx + '/t/p/'.length);
        final slash = after.indexOf('/');
        if (slash != -1) {
          final tail = after.substring(slash + 1);
          return '$imageBase/$size/$tail';
        }
      }
      // If it's a direct URL without /t/p/, return as is
      return raw;
    }
    // If raw starts with /t/p/size/file
    if (raw.startsWith('/t/p/')) {
      final after = raw.substring('/t/p/'.length);
      final slash = after.indexOf('/');
      if (slash != -1) {
        final tail = after.substring(slash + 1);
        return '$imageBase/$size/$tail';
      }
      return '$imageBase/$size/$after';
    }
    // If raw starts with a slash but not /t/p/
    if (raw.startsWith('/')) {
      return '$imageBase/$size$raw';
    }
    // Otherwise treat as filename
    return '$imageBase/$size/$raw';
  }

  static String posterUrl(String path, {PosterSize size = PosterSize.w500}) => _ensureSizedUrl(path, size.value);
  static String backdropUrl(String path, {BackdropSize size = BackdropSize.w780}) => _ensureSizedUrl(path, size.value);
}
