class InvoiceModel {
  final String invoiceId;
  final String invoiceNumber;
  final String bookingId;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final String vehicleName;
  final String vehicleReg;
  final double rentalCharge;
  final double securityDeposit;
  final double discount;
  final double totalAmount;
  final double amountPaid;
  final double balanceDue;
  final String status;
  final String? pdfUrl;

  const InvoiceModel({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.bookingId,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    required this.vehicleName,
    required this.vehicleReg,
    required this.rentalCharge,
    required this.securityDeposit,
    required this.discount,
    required this.totalAmount,
    required this.amountPaid,
    required this.balanceDue,
    required this.status,
    this.pdfUrl,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final customer = json['''customer'''] is Map ? json['''customer'''] : {};
    final vehicle = json['''vehicle'''] is Map ? json['''vehicle'''] : {};
    final charges = json['''charges'''] is Map ? json['''charges'''] : {};

    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      return double.tryParse(val?.toString() ?? '''''') ?? 0.0;
    }

    final bookingId = (json['''bookingId'''] ?? '''''').toString();

    return InvoiceModel(
      invoiceId: (json['''id'''] ?? json['''invoiceId'''] ?? '''''').toString(),
      invoiceNumber: (json['''invoiceNumber'''] ?? '''''').toString(),
      bookingId: bookingId,
      customerName: (customer['''name'''] ?? json['''customerName'''] ?? '''Customer''').toString(),
      customerEmail: (customer['''email'''] ?? json['''customerEmail'''] ?? '''''').toString(),
      customerPhone: customer['''phone''']?.toString(),
      vehicleName: (vehicle['''name'''] ?? json['''vehicleName'''] ?? '''Vehicle''').toString(),
      vehicleReg: (vehicle['''registration'''] ?? json['''vehicleReg'''] ?? '''''').toString(),
      rentalCharge: parseDouble(charges['''rental'''] ?? json['''baseAmount''']),
      securityDeposit: parseDouble(charges['''securityDeposit'''] ?? json['''securityDeposit''']),
      discount: parseDouble(charges['''discount'''] ?? json['''couponDiscount''']),
      totalAmount: parseDouble(json['''total'''] ?? json['''totalAmount''']),
      amountPaid: parseDouble(json['''amountPaid''']),
      balanceDue: parseDouble(json['''balanceDue''']),
      status: (json['''status'''] ?? '''issued''').toString(),
      pdfUrl: '''/invoices/pdf.php?bookingId=$bookingId''',
    );
  }
}
