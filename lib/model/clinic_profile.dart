class ClinicProfile {
  const ClinicProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.specialty,
    required this.staffId,
    required this.licenseNumber,
    this.firstName = '',
  });

  final String uid, name, email, phone, specialty, staffId, licenseNumber;
  final String firstName;

  factory ClinicProfile.fromMap(String uid, Map<String, dynamic> data) {
    String read(List<String> keys) {
      for (final key in keys) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
      return '';
    }

    final name = read(['fullName', 'name', 'displayName']);
    return ClinicProfile(
      uid: uid,
      firstName: read(['firstName']),
      name: name.isNotEmpty
          ? name
          : [
              read(['firstName']),
              read(['lastName']),
            ].where((part) => part.isNotEmpty).join(' '),
      email: read(['email']),
      phone: read(['contact', 'phone', 'phoneNumber']),
      specialty: read(['specialty', 'specialization']),
      staffId: read(['userId', 'staffId']),
      licenseNumber: read(['licenseNumber', 'prcNumber']),
    );
  }

  String get initials {
    final words = name
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty && word.toLowerCase() != 'dr.')
        .toList();
    if (words.isEmpty) return '?';
    return [
      words.first,
      if (words.length > 1) words.last,
    ].map((word) => String.fromCharCode(word.runes.first)).join().toUpperCase();
  }
}
