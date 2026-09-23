import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/booking_model.dart';

class BookingNotificationHelper {
  /// Formats exact duration with both days and hours
  static String formatDurationDetailed(DateTime pickup, DateTime drop, {int? days, int? hours}) {
    final diff = drop.difference(pickup);
    final totalHours = diff.inHours > 0 ? diff.inHours : (hours != null && hours > 0 ? hours : 24);
    final calculatedDays = totalHours ~/ 24;
    final remainingHours = totalHours % 24;

    if (calculatedDays > 0 && remainingHours > 0) {
      return '$calculatedDays ${calculatedDays == 1 ? 'Day' : 'Days'}, $remainingHours ${remainingHours == 1 ? 'Hour' : 'Hours'} ($totalHours Total Hours)';
    } else if (calculatedDays > 0) {
      return '$calculatedDays ${calculatedDays == 1 ? 'Day' : 'Days'} ($totalHours Total Hours)';
    } else {
      return '$totalHours ${totalHours == 1 ? 'Hour' : 'Hours'}';
    }
  }

  /// Compact duration string: e.g. "3d 8h (80h)"
  static String formatDurationShort(DateTime pickup, DateTime drop, {int? days, int? hours}) {
    final diff = drop.difference(pickup);
    final totalHours = diff.inHours > 0 ? diff.inHours : (hours != null && hours > 0 ? hours : 24);
    final calculatedDays = totalHours ~/ 24;
    final remainingHours = totalHours % 24;

    if (calculatedDays > 0 && remainingHours > 0) {
      return '${calculatedDays}d ${remainingHours}h (${totalHours}h)';
    } else if (calculatedDays > 0) {
      return '${calculatedDays}d (${totalHours}h)';
    } else {
      return '${totalHours}h';
    }
  }

  /// Generates the complete, professional WhatsApp & Email confirmation message
  static String generateApprovalConfirmationMessage(BookingModel booking) {
    final dateFmt = DateFormat('EEE, dd MMM yyyy • hh:mm a');
    final pickupStr = dateFmt.format(booking.pickupDate);
    final dropStr = dateFmt.format(booking.dropDate);
    final durationStr = formatDurationDetailed(
      booking.pickupDate,
      booking.dropDate,
      days: booking.days,
      hours: booking.hours,
    );
    final bId = booking.bookingNumber.isNotEmpty ? booking.bookingNumber : booking.bookingId;
    final customerName = booking.userName.isNotEmpty ? booking.userName : 'Valued Client';
    final vehicle = '${booking.vehicleName} (${booking.vehicleReg.isNotEmpty ? booking.vehicleReg : booking.vehicleCategory.toUpperCase()})';

    return '''🚗 *KRUIZLY SELF-DRIVE CAR RENTALS*
*BOOKING CONFIRMATION & APPROVAL NOTICE*

Dear $customerName,

Your car rental booking has been *APPROVED & CONFIRMED*! Here are your complete reservation details:

📋 *Booking ID:* #$bId
🚘 *Vehicle:* $vehicle
📍 *Pickup Location:* ${booking.location}

⏰ *BOOKED RENTAL SCHEDULE:*
• *Pickup Date & Time:* $pickupStr
• *Drop-off Date & Time:* $dropStr
• *Booked Duration:* $durationStr

💰 *PAYMENT & CHARGES:*
• Total Trip Amount: ₹${booking.totalAmount.toInt()}
• Advance Paid: ₹${booking.advanceAmount.toInt()}
• Balance Due at Delivery: ₹${booking.remainingBalance.toInt()}
${booking.securityDeposit > 0 ? '• Security Deposit (Refundable): ₹${booking.securityDeposit.toInt()}\n' : ''}
📋 *DOCUMENTS REQUIRED AT HANDOVER:*
• Original Driving License
• Original Aadhaar Card / Govt ID Proof

Thank you for choosing Kruizly! Have a safe and comfortable drive.

📞 *Customer Support:* +91 98920 19999 / +91 91671 64547
🌐 *Website:* https://kruizly.com''';
  }

  /// Sends the confirmation message directly to the client via WhatsApp
  static Future<bool> sendWhatsAppConfirmation(BookingModel booking) async {
    final message = generateApprovalConfirmationMessage(booking);
    String phone = (booking.userPhone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.length == 10) {
      phone = '91$phone';
    }
    final encodedText = Uri.encodeComponent(message);
    final urlStr = phone.isNotEmpty
        ? 'https://wa.me/$phone?text=$encodedText'
        : 'https://wa.me/?text=$encodedText';
    final uri = Uri.parse(urlStr);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }

  /// Sends the confirmation message directly to the client via Email
  static Future<bool> sendEmailConfirmation(BookingModel booking) async {
    final bId = booking.bookingNumber.isNotEmpty ? booking.bookingNumber : booking.bookingId;
    final subject = Uri.encodeComponent('Booking Confirmation #$bId Approved - Kruizly Self-Drive');
    final message = generateApprovalConfirmationMessage(booking);
    final body = Uri.encodeComponent(message);
    final email = booking.userEmail.trim();

    final urlStr = email.isNotEmpty
        ? 'mailto:$email?subject=$subject&body=$body'
        : 'mailto:?subject=$subject&body=$body';
    final uri = Uri.parse(urlStr);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }
}
