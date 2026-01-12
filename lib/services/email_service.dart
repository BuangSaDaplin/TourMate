import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/itinerary_model.dart';

class EmailService {
  // EmailJS configuration
  static const String _serviceId = 'service_w74hzom';
  static const String _templateId = 'template_uic10oj';
  static const String _userId =
      'your-emailjs-public-key'; // Replace with your EmailJS public key
  static const String _emailJsUrl =
      'https://api.emailjs.com/api/v1.0/email/send';

  /// Sends an itinerary via email using EmailJS
  Future<bool> sendItineraryEmail({
    required String recipientEmail,
    required ItineraryModel itinerary,
    required String senderName,
  }) async {
    try {
      final emailData = {
        'service_id': _serviceId,
        'template_id': _templateId,
        'user_id': _userId,
        'template_params': {
          'to_email': recipientEmail,
          'subject': 'Tour Itinerary: ${itinerary.title}',
          'from_name': senderName,
          'email': recipientEmail, // Reply-to email
          'itinerary_title': itinerary.title,
          'itinerary_description': itinerary.description,
          'start_date': itinerary.startDate.toString().split(' ')[0],
          'end_date': itinerary.endDate.toString().split(' ')[0],
          'itinerary_html': _generateItineraryHtml(itinerary, senderName),
        },
      };

      final response = await http.post(
        Uri.parse(_emailJsUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(emailData),
      );

      if (response.statusCode == 200) {
        print('Email sent successfully to $recipientEmail');
        return true;
      } else {
        print(
            'Failed to send email: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending itinerary email: $e');
      return false;
    }
  }

  /// Generates HTML email content for the itinerary
  String _generateItineraryHtml(ItineraryModel itinerary, String senderName) {
    final buffer = StringBuffer();

    buffer.writeln('''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${itinerary.title}</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .activity { background: white; margin: 15px 0; padding: 20px; border-radius: 8px; border-left: 4px solid #667eea; }
        .activity-time { color: #667eea; font-weight: bold; }
        .activity-title { font-size: 18px; font-weight: bold; margin: 10px 0; }
        .activity-description { color: #666; margin: 10px 0; }
        .footer { text-align: center; margin-top: 30px; padding: 20px; background: #333; color: white; border-radius: 10px; }
        .date-badge { display: inline-block; background: #667eea; color: white; padding: 5px 15px; border-radius: 20px; font-size: 14px; margin: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>${itinerary.title}</h1>
            <p>Shared by $senderName</p>
        </div>

        <div class="content">
            <p>Hello!</p>
            <p>$senderName has shared a tour itinerary with you. Here are the details:</p>

            <h3>Tour Overview</h3>
            <p><strong>Description:</strong> ${itinerary.description}</p>
            <p><strong>Duration:</strong> ${itinerary.startDate.toString().split(' ')[0]} to ${itinerary.endDate.toString().split(' ')[0]}</p>

            <h3>Itinerary Details</h3>
''');

    // Group activities by date
    final activitiesByDate = <DateTime, List<dynamic>>{};
    for (final item in itinerary.items) {
      final date = DateTime(
          item.startTime.year, item.startTime.month, item.startTime.day);
      activitiesByDate.putIfAbsent(date, () => []).add(item);
    }

    // Sort dates
    final sortedDates = activitiesByDate.keys.toList()..sort();

    for (final date in sortedDates) {
      final activities = activitiesByDate[date]!;
      activities.sort((a, b) => a.startTime.compareTo(b.startTime));

      buffer.writeln('<div class="date-section">');
      buffer.writeln('<h4>${_formatDate(date)}</h4>');

      for (final activity in activities) {
        buffer.writeln('''
<div class="activity">
    <div class="activity-time">${_formatTime(activity.startTime)} - ${_formatTime(activity.endTime)}</div>
    <div class="activity-title">${activity.title}</div>
    <div class="activity-description">${activity.description}</div>
''');

        if (activity.location != null && activity.location!.isNotEmpty) {
          buffer.writeln(
              '<p><strong>Location:</strong> ${activity.location}</p>');
        }

        if (activity.cost != null && activity.cost! > 0) {
          buffer.writeln(
              '<p><strong>Cost:</strong> \$${activity.cost!.toStringAsFixed(2)}</p>');
        }

        if (activity.notes != null && activity.notes!.isNotEmpty) {
          buffer.writeln('<p><strong>Notes:</strong> ${activity.notes}</p>');
        }

        buffer.writeln('</div>');
      }

      buffer.writeln('</div>');
    }

    buffer.writeln('''
        </div>

        <div class="footer">
            <p>This itinerary was shared via TourMate</p>
            <p>Enjoy your tour!</p>
        </div>
    </div>
</body>
</html>
''');

    return buffer.toString();
  }

  /// Generates plain text email content for the itinerary
  String _generateItineraryText(ItineraryModel itinerary, String senderName) {
    final buffer = StringBuffer();

    buffer.writeln('TOUR ITINERARY: ${itinerary.title.toUpperCase()}');
    buffer.writeln('=' * 50);
    buffer.writeln('');
    buffer.writeln('Shared by: $senderName');
    buffer.writeln('');
    buffer.writeln('Tour Overview:');
    buffer.writeln('Description: ${itinerary.description}');
    buffer.writeln(
        'Duration: ${itinerary.startDate.toString().split(' ')[0]} to ${itinerary.endDate.toString().split(' ')[0]}');
    buffer.writeln('');
    buffer.writeln('Itinerary Details:');
    buffer.writeln('-' * 30);

    // Group activities by date
    final activitiesByDate = <DateTime, List<dynamic>>{};
    for (final item in itinerary.items) {
      final date = DateTime(
          item.startTime.year, item.startTime.month, item.startTime.day);
      activitiesByDate.putIfAbsent(date, () => []).add(item);
    }

    // Sort dates
    final sortedDates = activitiesByDate.keys.toList()..sort();

    for (final date in sortedDates) {
      final activities = activitiesByDate[date]!;
      activities.sort((a, b) => a.startTime.compareTo(b.startTime));

      buffer.writeln('');
      buffer.writeln(_formatDate(date));
      buffer.writeln('-' * 20);

      for (final activity in activities) {
        buffer.writeln('');
        buffer.writeln(
            'Time: ${_formatTime(activity.startTime)} - ${_formatTime(activity.endTime)}');
        buffer.writeln('Activity: ${activity.title}');
        buffer.writeln('Description: ${activity.description}');

        if (activity.location != null && activity.location!.isNotEmpty) {
          buffer.writeln('Location: ${activity.location}');
        }

        if (activity.cost != null && activity.cost! > 0) {
          buffer.writeln('Cost: \$${activity.cost!.toStringAsFixed(2)}');
        }

        if (activity.notes != null && activity.notes!.isNotEmpty) {
          buffer.writeln('Notes: ${activity.notes}');
        }
      }
    }

    buffer.writeln('');
    buffer.writeln('=' * 50);
    buffer.writeln('This itinerary was shared via TourMate');
    buffer.writeln('Enjoy your tour!');

    return buffer.toString();
  }

  /// Helper method to format dates
  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Helper method to format times
  String _formatTime(DateTime time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
  }
}
