/// Who holds the phone. Anything other than [myself] switches to Care Mode.
enum AppFor {
  myself('Myself'),
  child('A child'),
  dependent('Someone I care for');

  final String label;
  const AppFor(this.label);

  bool get isCareMode => this != AppFor.myself;
}

/// How responders should approach a Care Mode user. Selected labels are stored
/// joined with '; ' in [CitizenProfile.supportNotes].
const List<String> careSupportOptions = [
  'Does not speak',
  'Deaf or hard of hearing',
  'Afraid of sirens or loud sounds',
  'May run away',
  'Ask before touching',
  'Has seizures',
  'Call caregiver first',
];

class CitizenProfile {
  final String fullName;
  final String phoneNumber;
  final String email;
  final String barangay;
  final String city;
  final String province;
  final String address;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String medicalNotes;
  final bool isRegistered;
  final bool isLoggedIn;
  final bool isVerified;
  final AppFor appFor;
  final String supportNotes;
  final String? authUserId;

  const CitizenProfile({
    this.fullName = '',
    this.phoneNumber = '',
    this.email = '',
    this.barangay = '',
    this.city = '',
    this.province = '',
    this.address = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.medicalNotes = '',
    this.isRegistered = false,
    this.isLoggedIn = false,
    this.isVerified = false,
    this.appFor = AppFor.myself,
    this.supportNotes = '',
    this.authUserId,
  });

  /// Street, barangay, city, province with empty parts left out. A profile
  /// made by phone sign-in has none of them, so this never renders as ", , ".
  String get addressLine {
    final parts = [address, barangay, city, province]
        .where((s) => s.trim().isNotEmpty)
        .join(', ');
    return parts.isEmpty ? 'Address not set' : parts;
  }

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'phone_number': phoneNumber,
        'email': email,
        'barangay': barangay,
        'city': city,
        'province': province,
        'address': address,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'medical_notes': medicalNotes,
        'is_registered': isRegistered,
        'is_logged_in': isLoggedIn,
        'is_verified': isVerified,
        'app_for': appFor.name,
        'support_notes': supportNotes,
        'auth_user_id': authUserId,
      };

  factory CitizenProfile.fromJson(Map<String, dynamic> json) => CitizenProfile(
        fullName: json['full_name'] as String? ?? 'Resident Citizen',
        phoneNumber: json['phone_number'] as String? ?? '',
        email: json['email'] as String? ?? '',
        barangay: json['barangay'] as String? ?? 'Barangay 171',
        city: json['city'] as String? ?? 'Metro Manila',
        province: json['province'] as String? ?? 'Metro Manila',
        address: json['address'] as String? ?? 'Block 3, Sitio Buntog',
        emergencyContactName:
            json['emergency_contact_name'] as String? ?? 'Emergency Contact',
        emergencyContactPhone:
            json['emergency_contact_phone'] as String? ?? '',
        medicalNotes: json['medical_notes'] as String? ?? 'None',
        isRegistered: json['is_registered'] as bool? ?? false,
        isLoggedIn: json['is_logged_in'] as bool? ?? false,
        isVerified: json['is_verified'] as bool? ?? false,
        appFor: AppFor.values.firstWhere(
          (a) => a.name == json['app_for'],
          orElse: () => AppFor.myself,
        ),
        supportNotes: json['support_notes'] as String? ?? '',
        authUserId: json['auth_user_id'] as String?,
      );

  CitizenProfile copyWith({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? barangay,
    String? city,
    String? province,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? medicalNotes,
    bool? isRegistered,
    bool? isLoggedIn,
    bool? isVerified,
    AppFor? appFor,
    String? supportNotes,
    String? authUserId,
  }) =>
      CitizenProfile(
        fullName: fullName ?? this.fullName,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        email: email ?? this.email,
        barangay: barangay ?? this.barangay,
        city: city ?? this.city,
        province: province ?? this.province,
        address: address ?? this.address,
        emergencyContactName:
            emergencyContactName ?? this.emergencyContactName,
        emergencyContactPhone:
            emergencyContactPhone ?? this.emergencyContactPhone,
        medicalNotes: medicalNotes ?? this.medicalNotes,
        isRegistered: isRegistered ?? this.isRegistered,
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        isVerified: isVerified ?? this.isVerified,
        appFor: appFor ?? this.appFor,
        supportNotes: supportNotes ?? this.supportNotes,
        authUserId: authUserId ?? this.authUserId,
      );
}
