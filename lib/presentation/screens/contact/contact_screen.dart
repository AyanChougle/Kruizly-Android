import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/background_video_widget.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_card.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  String _subject = 'General Inquiry';
  bool _isSending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final msg = _messageController.text.trim();

    if (name.isEmpty || email.isEmpty || msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in Name, Email, and Message.'),
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _isSending = false;
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _messageController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF06D6A0),
          content: Text(
            'Thank you! Your message has been sent to Kruizly Concierge.',
          ),
        ),
      );
    }
  }

  Future<void> _launchUrlStr(String urlStr) async {
    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              AppAssets.logo,
              height: 26,
              errorBuilder: (_, _, _) => const Text('Kruizly'),
            ),
            const SizedBox(width: 8),
            const Text(
              'CONTACT US',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Color(0xFF4FD7FF),
              ),
            ),
          ],
        ),
      ),
      body: BackgroundVideoWidget(
        isEnabled: true,
        overlayOpacity: 0.86,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner matching media_1789973395982.png
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FD7FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '• CONTACT US',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4FD7FF),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Plan your ride with a team that responds fast.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: context.themeTextPrimary,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Need support, a customized booking, or fleet information? Reach out and we\'ll get you behind the wheel quickly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.themeTextSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // CARD 1: GET IN TOUCH - SEND US A MESSAGE
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4FD7FF).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '• GET IN TOUCH',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4FD7FF),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Send us a message',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.themeTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Fill out the form below and our concierge team will get back to you shortly.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.themeTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _nameController,
                      style: TextStyle(
                        color: context.themeTextPrimary,
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'FULL NAME *',
                        hintText: 'Your full name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        color: context.themeTextPrimary,
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'EMAIL ADDRESS *',
                        hintText: 'name@example.com',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                        color: context.themeTextPrimary,
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'PHONE NUMBER',
                        hintText: '+91 98765 43210',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      initialValue: _subject,
                      style: TextStyle(
                        color: context.themeTextPrimary,
                        fontSize: 13,
                      ),
                      dropdownColor: context.themeSurfaceElevated,
                      decoration: const InputDecoration(
                        labelText: 'INQUIRY SUBJECT',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'General Inquiry',
                          child: Text('General Inquiry'),
                        ),
                        DropdownMenuItem(
                          value: 'Booking Assistance',
                          child: Text('Booking Assistance'),
                        ),
                        DropdownMenuItem(
                          value: 'Fleet Partnership',
                          child: Text('Fleet Partnership'),
                        ),
                        DropdownMenuItem(
                          value: 'Corporate Rental',
                          child: Text('Corporate Rental'),
                        ),
                        DropdownMenuItem(
                          value: 'Customer Feedback',
                          child: Text('Customer Feedback'),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _subject = val ?? 'General Inquiry'),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: _messageController,
                      maxLines: 4,
                      style: TextStyle(
                        color: context.themeTextPrimary,
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'YOUR MESSAGE *',
                        hintText:
                            'Tell us how we can help with your journey...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    CustomButton(
                      text: _isSending ? 'Sending...' : 'SEND MESSAGE →',
                      height: 44,
                      onPressed: _isSending ? null : _sendMessage,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // CARD 2: DIRECT CHANNELS - CONTACT DETAILS
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06D6A0).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '• DIRECT CHANNELS',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF06D6A0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contact Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.themeTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Direct lines to our Mumbai operations and road concierge.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.themeTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Office Address
                    _buildChannelTile(
                      icon: Icons.location_on_outlined,
                      label: 'OFFICE ADDRESS',
                      value: 'Gavson Business Park, Navi Mumbai, India',
                      onTap: () => _launchUrlStr(
                        'https://maps.google.com/?q=Gavson+Business+Park+Ghansoli',
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Phone Line
                    _buildChannelTile(
                      icon: Icons.phone_outlined,
                      label: 'PHONE LINE (CLICK TO CALL)',
                      value: '+91 91671 64547',
                      valueColor: const Color(0xFF4FD7FF),
                      onTap: () => _launchUrlStr('tel:+919167164547'),
                    ),
                    const SizedBox(height: 10),

                    // Direct Email
                    _buildChannelTile(
                      icon: Icons.mail_outline_rounded,
                      label: 'DIRECT EMAIL',
                      value: 'support@Kruizly.com',
                      valueColor: const Color(0xFF4FD7FF),
                      onTap: () => _launchUrlStr('mailto:support@Kruizly.com'),
                    ),
                    const SizedBox(height: 16),

                    // Social buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildSocialPill(
                            'Instagram',
                            Icons.camera_alt_outlined,
                            () =>
                                _launchUrlStr('https://instagram.com/Kruizly'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSocialPill(
                            'Facebook',
                            Icons.facebook_rounded,
                            () => _launchUrlStr('https://facebook.com/Kruizly'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSocialPill(
                            'WhatsApp',
                            Icons.chat_rounded,
                            () => _launchUrlStr('https://wa.me/919167164547'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Map View Representation
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.themeBorder),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 36,
                                  color: Color(0xFFFF5C77),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Gavson Business Park',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Ghansoli, Navi Mumbai',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: context.themeTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: InkWell(
                              onTap: () => _launchUrlStr(
                                'https://maps.google.com/?q=Gavson+Business+Park+Ghansoli',
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Open Maps',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF4FD7FF),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.open_in_new,
                                      size: 12,
                                      color: Color(0xFF4FD7FF),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.themeSurfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.themeBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4FD7FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF4FD7FF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: context.themeTextMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: valueColor ?? context.themeTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialPill(String name, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: context.themeSurfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.themeBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: context.themeTextPrimary),
            const SizedBox(width: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.themeTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
