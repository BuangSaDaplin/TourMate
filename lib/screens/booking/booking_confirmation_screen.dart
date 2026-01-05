import 'package:flutter/material.dart';
import 'package:tourmate_app/screens/reviews/add_review_screen.dart';
import 'package:tourmate_app/models/review_model.dart';
import 'package:tourmate_app/screens/payments/payment_screen.dart';
import 'package:tourmate_app/models/booking_model.dart';
import '../../utils/app_theme.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> tourData;

  const BookingConfirmationScreen({super.key, required this.tourData});

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  int _numberOfPeople = 1;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedPaymentMethod = 'Credit Card';

  final List<String> _paymentMethods = [
    'Credit Card',
    'Debit Card',
    'PayPal',
    'GCash',
    'PayMaya',
  ];

  double get _totalPrice => widget.tourData['price'] * _numberOfPeople;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Booking Confirmation'), elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tour Summary Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tour Summary', style: AppTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.image,
                          size: 40,
                          color: AppTheme.primaryColor.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.tourData['title'],
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.tourData['location'],
                                  style: AppTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.tourData['duration'],
                                  style: AppTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Booking Details
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Booking Details', style: AppTheme.headlineSmall),
                  const SizedBox(height: 16),
                  // Date Selection
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: Text('Tour Date', style: AppTheme.bodySmall),
                    subtitle: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ),
                  const Divider(),
                  // Number of People
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.people,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: Text('Number of People', style: AppTheme.bodySmall),
                    subtitle: Text(
                      '$_numberOfPeople ${_numberOfPeople == 1 ? 'Person' : 'People'}',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _numberOfPeople > 1
                              ? () {
                                  setState(() {
                                    _numberOfPeople--;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _numberOfPeople++;
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Payment Method
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Method', style: AppTheme.headlineSmall),
                  const SizedBox(height: 16),
                  ..._paymentMethods.map((method) {
                    return RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(method),
                      value: method,
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Price Summary
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Price Summary', style: AppTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tour Price (per person)',
                        style: AppTheme.bodyMedium,
                      ),
                      Text(
                        '₱${widget.tourData['price'].toStringAsFixed(0)}',
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Number of People', style: AppTheme.bodyMedium),
                      Text('x $_numberOfPeople', style: AppTheme.bodyMedium),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₱${_totalPrice.toStringAsFixed(0)}',
                        style: AppTheme.headlineSmall.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              _showBookingSuccessDialog();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Confirm Booking - ₱${_totalPrice.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  void _proceedToPayment() {
    // Create a booking object to pass to payment screen
    // For now, we'll create a mock booking since the full booking flow isn't implemented
    final mockBooking = BookingModel(
      tourTitle: 'title_123',
      id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
      tourId: 'tour_123', // Would get from tour data
      touristId: 'current_user', // Would get from auth service
      guideId: 'guide_123', // Would get from tour data
      bookingDate: DateTime.now(),
      tourStartDate: _selectedDate,
      numberOfParticipants: _numberOfPeople,
      totalPrice: _totalPrice,
      status: BookingStatus.pending,
      specialRequests: '',
      contactNumber: '',
      emergencyContact: '',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentScreen(booking: mockBooking),
      ),
    );
  }

  void _showBookingSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 50,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text('Booking Confirmed!', style: AppTheme.headlineMedium),
                const SizedBox(height: 12),
                Text(
                  'Your tour has been successfully booked.',
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text('Booking Reference', style: AppTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        'TM${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'A confirmation email has been sent to your registered email address.',
                  style: AppTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Back to Home'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddReviewScreen(
                          targetId: widget.tourData['id'],
                          reviewType: ReviewType.tour,
                        ),
                      ),
                    );
                  },
                  child: const Text('Add a Review'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
