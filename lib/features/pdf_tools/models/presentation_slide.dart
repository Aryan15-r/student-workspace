class PresentationSlide {
  final String title;
  final String? subtitle;
  final List<String> bulletPoints;
  final String? note;

  const PresentationSlide({
    required this.title,
    this.subtitle,
    required this.bulletPoints,
    this.note,
  });

  factory PresentationSlide.fromJson(Map<String, dynamic> json) {
    return PresentationSlide(
      title: json['title'] as String? ?? 'Slide',
      subtitle: json['subtitle'] as String?,
      bulletPoints:
          (json['bulletPoints'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      note: json['note'] as String?,
    );
  }
}
