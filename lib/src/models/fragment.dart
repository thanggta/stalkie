// lib/src/models/fragment.dart
enum FragmentType { thread, image, record, note, audio }

class DamageSpec {
  final String profile;
  final double intensity;
  final int seed;

  const DamageSpec({
    required this.profile,
    required this.intensity,
    required this.seed,
  });

  static const allowedProfiles = {
    'block-loss',
    'scanline-tear',
    'partial-decode',
    'chroma-bleed',
    'overwrite',
  };

  @override
  bool operator ==(Object other) =>
      other is DamageSpec &&
      other.profile == profile &&
      other.intensity == intensity &&
      other.seed == seed;

  @override
  int get hashCode => Object.hash(profile, intensity, seed);
}

class Fragment {
  final String id;
  final FragmentType type;
  final String label;
  final DamageSpec damage;
  final Map<String, dynamic> content;

  const Fragment({
    required this.id,
    required this.type,
    required this.label,
    required this.damage,
    required this.content,
  });
}
