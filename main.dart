import 'package:flutter/material.dart';
import 'colors.dart';
import 'text_styles.dart';

void main() {
  runApp(AboutPageApp());
}

class AboutPageApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'About Page',
      theme: ThemeData(
        primarySwatch: AppColors.primary, // Set the primary color for the app
        scaffoldBackgroundColor: AppColors.backgroundLight, // Set background color
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          titleTextStyle: AppTextStyles.heading.copyWith(color: AppColors.textOnPrimary),
          elevation: 4,
          shadowColor: Colors.black26,
        ),
        dividerColor: AppColors.divider, // Define divider color
      ),
      home: AboutPage(),
    );
  }
}

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
          onPressed: () {}, // Add navigation logic if needed
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: AppColors.textOnPrimary),
            onPressed: () {}, // Add action for the info button
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Countdown Timer App', Icons.timer), // App title section
            SizedBox(height: 10),
            _buildTextBlock(
              'This app allows users to set a countdown timer for various activities. Users can start, pause, and reset the timer as needed, making it ideal for tracking time in different situations.',
            ),
            SizedBox(height: 20),
            Divider(thickness: 2), // Divider for section separation
            SizedBox(height: 10),
            _buildSectionTitle('Credits', Icons.people_alt), // Credits section
            SizedBox(height: 10),
            _buildTextBlock(
              'Developed by:',
              textStyle: AppTextStyles.accentText,
            ),
            SizedBox(height: 5),
            _buildCreditsList([
              'Alisher Mukhamedov',
              'Yerkanat Manassov',
              'Maral Kuanysh',
            ]), // List of developers
            SizedBox(height: 10),
            _buildTextBlock(
              'Mentor (Teacher):',
              textStyle: AppTextStyles.accentText,
            ),
            SizedBox(height: 5),
            _buildTextBlock(
              'Assistant Professor Abzal Kyzyrkanov',
              textStyle: AppTextStyles.credits,
            ), // Teacher's credit
            SizedBox(height: 20),
            _buildFooter(), // Footer with appreciation message
          ],
        ),
      ),
    );
  }

  /// Builds a section title with an icon.
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        SizedBox(width: 10),
        Text(title, style: AppTextStyles.subheading),
      ],
    );
  }

  /// Displays a text block with optional styling.
  Widget _buildTextBlock(String text, {TextStyle? textStyle}) {
    return Text(
      text,
      style: textStyle ?? AppTextStyles.body,
      textAlign: TextAlign.justify,
    );
  }

  /// Creates a list of developers' names with bullet points.
  Widget _buildCreditsList(List<String> names) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: names
          .map((name) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: AppColors.secondary),
                    SizedBox(width: 10),
                    Text(name, style: AppTextStyles.body),
                  ],
                ),
              ))
          .toList(),
    );
  }

  /// Displays a footer message with an icon.
  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.access_time, color: AppColors.accent, size: 40),
          SizedBox(height: 5),
          Text(
            'Thank you for your attention.',
            style: AppTextStyles.credits.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
