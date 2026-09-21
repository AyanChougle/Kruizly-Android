class UserModel {
  final int id;
  final String firebaseUid;
  final String email;
  final String name;
  final String? phone;
  final int? age;
  final String role;
  final String status;
  final String licenseStatus;
  final String aadharStatus;
  final String panStatus;
  final String? licenseFrontUrl;
  final String? licenseBackUrl;
  final String? aadharFrontUrl;
  final String? aadharBackUrl;
  final String? panFrontUrl;
  final String? panBackUrl;

  const UserModel({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.name,
    this.phone,
    this.age,
    this.role = '''customer''',
    this.status = '''active''',
    this.licenseStatus = '''not_submitted''',
    this.aadharStatus = '''not_submitted''',
    this.panStatus = '''not_submitted''',
    this.licenseFrontUrl,
    this.licenseBackUrl,
    this.aadharFrontUrl,
    this.aadharBackUrl,
    this.panFrontUrl,
    this.panBackUrl,
  });

  bool get isVerified =>
      licenseStatus == '''verified''' && aadharStatus == '''verified''';

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isManager => role.toLowerCase() == 'manager' || isAdmin;
  bool get isExecutive => role.toLowerCase() == 'executive' || isManager || isAdmin;
  bool get isAccounts => role.toLowerCase() == 'accounts' || role.toLowerCase() == 'accountant' || isAdmin;

  bool get isStaff =>
      ['''admin''', '''manager''', '''executive''', '''accountant''', '''accounts'''].contains(role.toLowerCase());

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['''id'''] is int ? json['''id'''] : int.tryParse(json['''id'''].toString()) ?? 0,
      firebaseUid: (json['''firebaseUid'''] ?? json['''uid'''] ?? json['''firebase_uid'''] ?? '''''').toString(),
      email: (json['''email'''] ?? '''''').toString(),
      name: (json['''name'''] ?? json['''userName'''] ?? '''KRUIZLY Member''').toString(),
      phone: json['''phone''']?.toString(),
      age: json['''age'''] is int ? json['''age'''] : int.tryParse(json['''age'''].toString()),
      role: (json['''role'''] ?? '''customer''').toString(),
      status: (json['''status'''] ?? '''active''').toString(),
      licenseStatus: (json['''licenseStatus'''] ?? json['''license_status'''] ?? '''not_submitted''').toString(),
      aadharStatus: (json['''aadharStatus'''] ?? json['''aadhar_status'''] ?? '''not_submitted''').toString(),
      panStatus: (json['''panStatus'''] ?? json['''pan_status'''] ?? '''not_submitted''').toString(),
      licenseFrontUrl: json['''licenseFrontURL''']?.toString() ?? json['''licenseFrontUrl''']?.toString(),
      licenseBackUrl: json['''licenseBackURL''']?.toString() ?? json['''licenseBackUrl''']?.toString(),
      aadharFrontUrl: json['''aadharFrontURL''']?.toString() ?? json['''aadharFrontUrl''']?.toString(),
      aadharBackUrl: json['''aadharBackURL''']?.toString() ?? json['''aadharBackUrl''']?.toString(),
      panFrontUrl: json['''panFrontURL''']?.toString() ?? json['''panFrontUrl''']?.toString(),
      panBackUrl: json['''panBackURL''']?.toString() ?? json['''panBackUrl''']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '''id''': id,
      '''firebaseUid''': firebaseUid,
      '''email''': email,
      '''name''': name,
      '''phone''': phone,
      '''age''': age,
      '''role''': role,
      '''status''': status,
      '''licenseStatus''': licenseStatus,
      '''aadharStatus''': aadharStatus,
      '''panStatus''': panStatus,
    };
  }
}
