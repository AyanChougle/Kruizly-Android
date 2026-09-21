class KycModel {
  final String? id;
  final String licenseStatus;
  final String aadharStatus;
  final String panStatus;
  final String overallStatus;
  final String? rejectionReason;
  final bool hasSubmission;
  final String? licenseNumber;
  final String? aadharNumber;
  final String? panNumber;
  final String? licenseFrontUrl;
  final String? licenseBackUrl;
  final String? aadharFrontUrl;
  final String? aadharBackUrl;
  final String? panFrontUrl;
  final String? panBackUrl;

  const KycModel({
    this.id,
    required this.licenseStatus,
    required this.aadharStatus,
    required this.panStatus,
    required this.overallStatus,
    this.rejectionReason,
    required this.hasSubmission,
    this.licenseNumber,
    this.aadharNumber,
    this.panNumber,
    this.licenseFrontUrl,
    this.licenseBackUrl,
    this.aadharFrontUrl,
    this.aadharBackUrl,
    this.panFrontUrl,
    this.panBackUrl,
  });

  bool get isVerified => overallStatus == 'verified' || overallStatus == 'approved' || (licenseStatus == 'verified' && aadharStatus == 'verified');
  bool get isPending => overallStatus == 'pending' || overallStatus == 'under_review' || licenseStatus == 'pending' || aadharStatus == 'pending';
  bool get isRejected => overallStatus == 'rejected' || licenseStatus == 'rejected' || aadharStatus == 'rejected';

  factory KycModel.fromJson(Map<String, dynamic> json) {
    final ver = json['verification'] is Map ? json['verification'] as Map<String, dynamic> : json;
    return KycModel(
      id: ver['id']?.toString() ?? ver['verificationId']?.toString(),
      licenseStatus: (ver['licenseStatus'] ?? ver['license_status'] ?? 'not_submitted').toString(),
      aadharStatus: (ver['aadharStatus'] ?? ver['aadhar_status'] ?? 'not_submitted').toString(),
      panStatus: (ver['panStatus'] ?? ver['pan_status'] ?? 'not_submitted').toString(),
      overallStatus: (ver['overallStatus'] ?? ver['overall_status'] ?? ver['status'] ?? 'not_submitted').toString(),
      rejectionReason: ver['rejectionReason']?.toString() ?? ver['rejection_reason']?.toString(),
      hasSubmission: json['hasSubmission'] == true || (ver['licenseStatus'] != null && ver['licenseStatus'] != 'not_submitted'),
      licenseNumber: ver['licenseNumber']?.toString() ?? ver['license_number']?.toString(),
      aadharNumber: ver['aadharNumber']?.toString() ?? ver['aadhar_number']?.toString(),
      panNumber: ver['panNumber']?.toString() ?? ver['pan_number']?.toString(),
      licenseFrontUrl: ver['licenseFrontUrl']?.toString() ?? ver['license_front']?.toString(),
      licenseBackUrl: ver['licenseBackUrl']?.toString() ?? ver['license_back']?.toString(),
      aadharFrontUrl: ver['aadharFrontUrl']?.toString() ?? ver['aadhar_front']?.toString(),
      aadharBackUrl: ver['aadharBackUrl']?.toString() ?? ver['aadhar_back']?.toString(),
      panFrontUrl: ver['panFrontUrl']?.toString() ?? ver['pan_front']?.toString(),
      panBackUrl: ver['panBackUrl']?.toString() ?? ver['pan_back']?.toString(),
    );
  }
}
