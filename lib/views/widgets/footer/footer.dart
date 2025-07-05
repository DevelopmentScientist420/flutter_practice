import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Mobile layout
              if (constraints.maxWidth < 768) {
                return _buildMobileFooter(context);
              }

              // Desktop/Tablet layout
              return _buildDesktopFooter(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMobileFooter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo section
        _buildLogoSection(),
        const SizedBox(height: 32),
        
        // Social media
        _buildSocialMediaSection(),
        const SizedBox(height: 32),
        
        // Copyright
        _buildCopyrightSection(),
      ],
    );
  }

  Widget _buildDesktopFooter(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo section (takes more space)
            Expanded(
              flex: 2,
              child: _buildLogoSection(),
            ),
            const SizedBox(width: 40),
            const SizedBox(width: 40),
          ],
        ),
        const SizedBox(height: 40),
        
        // Divider
        Container(
          height: 1,
          color: Colors.grey[700],
        ),
        const SizedBox(height: 32),
        
        // Bottom section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCopyrightSection(),
            _buildSocialMediaSection(),
          ],
        ),
      ],
    );
  }

  Widget _buildLogoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MONEY SAVER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your trusted assistant to prevent your wallet from burning.',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialMediaSection() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSocialIcon(Icons.facebook, 'Facebook'),
        const SizedBox(width: 16),
        _buildSocialIcon(Icons.alternate_email, 'Twitter'),
        const SizedBox(width: 16),
        _buildSocialIcon(Icons.business, 'LinkedIn'),
        const SizedBox(width: 16),
        _buildSocialIcon(Icons.camera_alt, 'Instagram'),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          // Add social media link logic here
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: Colors.grey[400],
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildCopyrightSection() {
    final DateTime year = DateTime.now(); // Get current year

    return Text(
      '© 2020 - ${year.year} Money Saver. All rights reserved.',
      style: TextStyle(
        color: Colors.grey[500],
        fontSize: 12,
      ),
    );
  }
}
