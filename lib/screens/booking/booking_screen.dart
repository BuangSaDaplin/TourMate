import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tourmate_app/models/tour_model.dart';
import 'package:tourmate_app/services/auth_service.dart';
import 'package:tourmate_app/services/database_service.dart';
import 'package:tourmate_app/services/notification_service.dart';
import 'package:tourmate_app/models/booking_model.dart';
import 'package:tourmate_app/screens/bookings/bookings_screen.dart';
import '../../utils/app_theme.dart';

class BookingScreen extends StatefulWidget {
  final TourModel tour;

  const BookingScreen({super.key, required this.tour});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  final _formKey = GlobalKey<FormState>();

  // Booking details
  int _numberOfParticipants = 1;
  final List<TextEditingController> _participantControllers = [];
  final TextEditingController _contactController = TextEditingController();
  DateTime? _selectedDate;

  bool _isLoading = false;
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.tour.startTime;
    // Initialize participant name controllers
    for (int i = 0; i < _numberOfParticipants; i++) {
      _participantControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (var controller in _participantControllers) {
      controller.dispose();
    }
    _contactController.dispose();
    super.dispose();
  }

  void _updateParticipantControllers(int newCount) {
    if (newCount > _participantControllers.length) {
      // Add controllers
      for (int i = _participantControllers.length; i < newCount; i++) {
        _participantControllers.add(TextEditingController());
      }
    } else if (newCount < _participantControllers.length) {
      // Remove controllers
      for (int i = _participantControllers.length - 1; i >= newCount; i--) {
        _participantControllers[i].dispose();
        _participantControllers.removeAt(i);
      }
    }
  }

  double get _totalPrice => widget.tour.price * _numberOfParticipants;
  double get _serviceFee => _totalPrice * 0.05; // 5% service fee
  double get _finalTotal => _totalPrice + _serviceFee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Book Tour'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tour Summary Card
              _buildTourSummaryCard(),

              const SizedBox(height: 24),

              // Participant Details
              _buildParticipantSection(),

              const SizedBox(height: 24),

              // Contact Information
              _buildContactSection(),

              const SizedBox(height: 24),

              // Date Selection
              _buildDateSection(),

              const SizedBox(height: 24),

              // Terms and Conditions
              _buildTermsSection(),

              const SizedBox(height: 32),

              // Booking Summary & Payment
              _buildBookingSummary(),

              const SizedBox(height: 24),

              // Book Now Button
              _buildBookNowButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTourSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: AssetImage(
                          'assets/images/${widget.tour.mediaURL.isNotEmpty ? widget.tour.mediaURL[0] : 'default_tour.jpg'}'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tour.title,
                        style: AppTheme.headlineSmall
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.tour.startTime.day}/${widget.tour.startTime.month}/${widget.tour.startTime.year}',
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.tour.meetingPoint,
                              style: AppTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(
                    '${widget.tour.maxParticipants} max', Icons.people),
                const SizedBox(width: 8),
                _buildInfoChip(
                    widget.tour.category.isNotEmpty
                        ? widget.tour.category[0]
                        : 'No Category',
                    Icons.category),
                const SizedBox(width: 8),
                _buildInfoChip('${widget.tour.duration} hours', Icons.schedule),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Participants', style: AppTheme.headlineSmall),
        const SizedBox(height: 16),

        // Number of Participants
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Number of Participants', style: AppTheme.bodyLarge),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _numberOfParticipants > 1
                        ? () {
                            setState(() {
                              _numberOfParticipants--;
                              _updateParticipantControllers(
                                  _numberOfParticipants);
                            });
                          }
                        : null,
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      '$_numberOfParticipants',
                      style: AppTheme.bodyLarge
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed:
                        _numberOfParticipants < widget.tour.maxParticipants
                            ? () {
                                setState(() {
                                  _numberOfParticipants++;
                                  _updateParticipantControllers(
                                      _numberOfParticipants);
                                });
                              }
                            : null,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Participant Names
        ...List.generate(_numberOfParticipants, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: _participantControllers[index],
              decoration: InputDecoration(
                labelText: 'Participant ${index + 1} Full Name',
                hintText: 'Enter full name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter participant name';
                }
                return null;
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contact Information', style: AppTheme.headlineSmall),
        const SizedBox(height: 16),
        TextFormField(
          controller: _contactController,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Contact Number',
            hintText: '+63 912 345 6789',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter contact number';
            }
            if (value.length < 10) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tour Date', style: AppTheme.headlineSmall),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null && picked != _selectedDate) {
              setState(() {
                _selectedDate = picked;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Select Date',
                  style: AppTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: _agreeToTerms,
                onChanged: (value) {
                  setState(() {
                    _agreeToTerms = value ?? false;
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppTheme.bodyMedium,
                    children: [
                      const TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Cancellation Policy',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSummary() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking Summary', style: AppTheme.headlineSmall),
            const SizedBox(height: 16),
            _buildSummaryRow('Tour Price',
                '₱${widget.tour.price.toStringAsFixed(2)} × $_numberOfParticipants'),
            _buildSummaryRow('Subtotal', '₱${_totalPrice.toStringAsFixed(2)}'),
            _buildSummaryRow(
                'Service Fee (5%)', '₱${_serviceFee.toStringAsFixed(2)}'),
            const Divider(),
            _buildSummaryRow(
                'Total Amount', '₱${_finalTotal.toStringAsFixed(2)}',
                isTotal: true),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment will be collected after guide approval. Free cancellation up to 24 hours before tour.',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.accentColor),
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

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)
                : AppTheme.bodyMedium,
          ),
          Text(
            value,
            style: isTotal
                ? AppTheme.headlineSmall.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  )
                : AppTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBookNowButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isLoading || !_agreeToTerms) ? null : _submitBooking,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Submit Booking Request',
                style: AppTheme.buttonText,
              ),
      ),
    );
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please agree to the terms and conditions')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.getCurrentUser();
      if (user != null) {
        final participantNames = _participantControllers
            .map((controller) => controller.text.trim())
            .where((name) => name.isNotEmpty)
            .toList();

        final selectedDate = _selectedDate ?? widget.tour.startTime;
        final tourStartDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          widget.tour.startTime.hour,
          widget.tour.startTime.minute,
        );

        final newBooking = BookingModel(
          tourTitle: widget.tour.title,
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          tourId: widget.tour.id,
          touristId: user.uid,
          guideId: widget.tour.createdBy,
          bookingDate: DateTime.now(),
          tourStartDate: tourStartDate,
          numberOfParticipants: _numberOfParticipants,
          totalPrice: _finalTotal,
          specialRequests: null,
          participantNames: participantNames,
          contactNumber: _contactController.text.trim(),
          emergencyContact: null,
          duration: widget.tour.duration,
        );

        await _db.createBooking(newBooking);

        // Create notification for booking submission
        final bookingNotification =
            _notificationService.createBookingSubmittedNotification(
          userId: user.uid,
          tourTitle: widget.tour.title,
        );
        await _notificationService.createNotification(bookingNotification);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking request submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const BookingsScreen(initialTab: 0),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit booking: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
