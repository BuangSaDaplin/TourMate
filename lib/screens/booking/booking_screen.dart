  import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourmate_app/models/tour_model.dart';
import 'package:tourmate_app/models/user_model.dart';
import 'package:tourmate_app/services/auth_service.dart';
import 'package:tourmate_app/services/database_service.dart';
import 'package:tourmate_app/services/notification_service.dart';
import 'package:tourmate_app/models/booking_model.dart';
import 'package:tourmate_app/screens/bookings/bookings_screen.dart';
import 'package:tourmate_app/screens/tour/tour_details_screen.dart';
import 'package:tourmate_app/screens/auth/privacy_policy_screen.dart';
import 'package:tourmate_app/screens/auth/terms_and_conditions_screen.dart';
import '../../utils/app_theme.dart';

class BookingScreen extends StatefulWidget {
  final TourModel? tour;
  final DateTime? initialDate;

  const BookingScreen({super.key, this.tour, this.initialDate});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  final _formKey = GlobalKey<FormState>();

  // User data
  UserModel? currentUser;
  bool isLoadingUser = true;

  // Guide selection
  List<UserModel> guides = [];
  bool isLoadingGuides = false;
  UserModel? selectedGuide;
  String? selectedDayFilter; // NEW: Day filter for guide availability

  // Tour selection
  TourModel? selectedTour;
  final TextEditingController _searchController = TextEditingController();
  List<TourModel> _filteredTours = [];
  List<TourModel> availableTours = [];
  bool isLoadingTours = true;

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
    selectedTour = widget.tour;
    _selectedDate = widget.initialDate ??
        selectedTour?.startTime ??
        DateTime.now().add(const Duration(days: 1));
    _filteredTours = [];
    // Initialize participant name controllers
    for (int i = 0; i < _numberOfParticipants; i++) {
      _participantControllers.add(TextEditingController());
    }
    _fetchCurrentUser();
    _fetchGuides();
    _fetchAvailableTours();
  }

  @override
  void dispose() {
    for (var controller in _participantControllers) {
      controller.dispose();
    }
    _contactController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final user = _authService.getCurrentUser();
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            currentUser = UserModel.fromFirestore(userDoc.data()!);
            isLoadingUser = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        isLoadingUser = false;
      });
      print('Error fetching current user: $e');
    }
  }

  Future<void> _fetchGuides() async {
    setState(() {
      isLoadingGuides = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'guide')
          .get();

      setState(() {
        guides = snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc.data()))
            .toList();
        isLoadingGuides = false;
      });
    } catch (e) {
      setState(() {
        isLoadingGuides = false;
      });
      print('Error fetching guides: $e');
    }
  }

  Future<void> _fetchAvailableTours() async {
    setState(() {
      isLoadingTours = true;
    });

    try {
      final tours = await _db.getToursByStatus('approved');
      setState(() {
        availableTours = tours;
        _filteredTours = List.from(availableTours);
        isLoadingTours = false;
      });
    } catch (e) {
      setState(() {
        isLoadingTours = false;
      });
      print('Error fetching tours: $e');
    }
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

  double get _totalPrice {
    double inclusionTotal = selectedTour?.inclusionPrices.values?.fold<double>(
            0.0, (sum, price) => sum + price * _numberOfParticipants) ??
        0.0;
    return inclusionTotal;
  }

  String _getWeekdayName(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return weekdays[date.weekday - 1];
  }

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
              // Select Tour
              _buildSelectTourSection(),

              const SizedBox(height: 24),

              // Select Guide
              _buildSelectGuideSection(),

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

  void _showTourSelectionDialog() {
    final TextEditingController searchController = TextEditingController();
    List<TourModel> filteredTours = List.from(availableTours);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            void updateFilteredTours(String query) {
              dialogSetState(() {
                filteredTours = availableTours.where((tour) {
                  return tour.title
                          .toLowerCase()
                          .contains(query.toLowerCase()) ||
                      tour.description
                          .toLowerCase()
                          .contains(query.toLowerCase()) ||
                      tour.category.any((cat) =>
                          cat.toLowerCase().contains(query.toLowerCase()));
                }).toList();
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 1000,
                ),
                height: MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Select a Tour',
                          style: AppTheme.headlineMedium,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search tours...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onChanged: updateFilteredTours,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: isLoadingTours
                          ? const Center(child: CircularProgressIndicator())
                          : filteredTours.isEmpty
                              ? const Center(child: Text('No tours available'))
                              : ListView.builder(
                                  itemCount: filteredTours.length,
                                  itemBuilder: (context, index) {
                                    final tour = filteredTours[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          // Use the main screen's setState, not the dialog's
                                          if (mounted) {
                                            setState(() {
                                              selectedTour = tour;
                                            });
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      tour.title,
                                                      style: AppTheme
                                                          .headlineSmall
                                                          .copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  SizedBox(
                                                    width: 100,
                                                    child: TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                TourDetailsScreen(
                                                                    tourId: tour
                                                                        .id),
                                                          ),
                                                        );
                                                      },
                                                      child: const Text(
                                                          'View Details'),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(Icons.calendar_today,
                                                      size: 16,
                                                      color: AppTheme
                                                          .textSecondary),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${tour.startTime.day}/${tour.startTime.month}/${tour.startTime.year}',
                                                    style: AppTheme.bodySmall,
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Icon(Icons.location_on,
                                                      size: 16,
                                                      color: AppTheme
                                                          .textSecondary),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      tour.meetingPoint,
                                                      style: AppTheme.bodySmall,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  _buildInfoChip(
                                                      '${tour.maxParticipants} max',
                                                      Icons.people),
                                                  const SizedBox(width: 8),
                                                  _buildInfoChip(
                                                    tour.category.isNotEmpty
                                                        ? tour.category[0]
                                                        : 'No Category',
                                                    Icons.category,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  _buildInfoChip(
                                                      '${tour.duration} hrs',
                                                      Icons.schedule),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSelectTourSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select a Tour', style: AppTheme.headlineSmall),
        const SizedBox(height: 16),
        if (selectedTour == null)
          InkWell(
            onTap: _showTourSelectionDialog,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    'Select a Tour',
                    style: AppTheme.bodyLarge,
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios,
                      size: 16, color: AppTheme.textSecondary),
                ],
              ),
            ),
          )
        else
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                'assets/images/${selectedTour!.mediaURL.isNotEmpty ? selectedTour!.mediaURL[0] : 'default_tour.jpg'}'),
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
                              selectedTour!.title,
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
                                  '${selectedTour!.startTime.day}/${selectedTour!.startTime.month}/${selectedTour!.startTime.year}',
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
                                    selectedTour!.meetingPoint,
                                    style: AppTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Column(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TourDetailsScreen(
                                        tourId: selectedTour!.id),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryColor,
                                side: BorderSide(color: AppTheme.primaryColor),
                              ),
                              child: const Text('View Details'),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _showTourSelectionDialog,
                              child: const Text('Select Tour'),
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
                          '${selectedTour!.maxParticipants} max', Icons.people),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                          selectedTour!.category.isNotEmpty
                              ? selectedTour!.category[0]
                              : 'No Category',
                          Icons.category),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                          '${selectedTour!.duration} hours', Icons.schedule),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectGuideSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select a Guide', style: AppTheme.headlineSmall),
        const SizedBox(height: 16),
        if (selectedTour == null)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Please select a tour first to choose a guide',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    child: const Icon(
                      Icons.person,
                      size: 30,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedGuide?.displayName ?? 'No guide selected',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (selectedGuide != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${selectedGuide!.averageRating?.toStringAsFixed(1) ?? 'N/A'} • ${selectedGuide!.toursCompleted ?? 0} tours',
                                style: AppTheme.bodySmall,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selectedGuide != null)
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text('View Profile'),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: _showGuideSelectionDialog,
                            child: const Text('Select Guide'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showGuideSelectionDialog() async {
    // Get the selected date's weekday for availability filtering
    final selectedDate = _selectedDate ?? selectedTour!.startTime;
    final selectedWeekday = _getWeekdayName(selectedDate);

    // Filter guides based on specializations matching all tour highlights
    final filteredGuides = guides.where((guide) {
      if (guide.specializations == null || guide.specializations!.isEmpty) {
        return false;
      }
      // Check if guide has availability data and includes the selected weekday
      if (guide.availability == null || guide.availability!.isEmpty) {
        return false; // Exclude guides without availability data
      }
      if (!guide.availability!.contains(selectedWeekday)) {
        return false; // Exclude guides not available on selected day
      }
      return selectedTour!.highlights
          .every((highlight) => guide.specializations!.contains(highlight));
    }).toList();

    // Filter out unavailable guides (those with bookings in pending, confirmed, paid, or inProgress status)
    final availableGuides = <UserModel>[];
    for (final guide in filteredGuides) {
      final bookings = await _db.getBookingsByGuide(guide.uid);
      final unavailableStatuses = [
        0,
        1,
        2,
        3
      ]; // pending, confirmed, paid, inProgress
      final hasUnavailableBooking = bookings
          .any((booking) => unavailableStatuses.contains(booking.status.index));
      if (!hasUnavailableBooking) {
        availableGuides.add(guide);
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Guide'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: isLoadingGuides
                ? const Center(child: CircularProgressIndicator())
                : availableGuides.isEmpty
                    ? const Center(
                        child: Text('No available guides for this tour'))
                    : ListView.builder(
                        itemCount: availableGuides.length,
                        itemBuilder: (context, index) {
                          final guide = availableGuides[index];
                          final isOnline = guide.activeStatus == 1;
                          final color = isOnline ? Colors.black : Colors.grey;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppTheme.primaryColor.withOpacity(0.2),
                              child: Icon(
                                Icons.person,
                                color: isOnline
                                    ? AppTheme.primaryColor
                                    : Colors.grey,
                              ),
                            ),
                            title: Text(
                              guide.displayName ?? guide.email,
                              style: TextStyle(color: color),
                            ),
                            subtitle: Row(
                              children: [
                                Icon(Icons.star,
                                    size: 16,
                                    color:
                                        isOnline ? Colors.amber : Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${guide.averageRating?.toStringAsFixed(1) ?? 'N/A'} • ${guide.toursCompleted ?? 0} tours',
                                  style: TextStyle(color: color),
                                ),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                selectedGuide = guide;
                              });
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
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

        // User's name (read-only)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Row(
            children: [
              Icon(Icons.person, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  currentUser?.displayName ?? 'Loading...',
                  style:
                      AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '(You)',
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Additional Participant Names
        ...List.generate(_numberOfParticipants - 1, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: _participantControllers[index],
              decoration: InputDecoration(
                labelText: 'Participant ${index + 2} Full Name',
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

        // Add Participant Button
        if (selectedTour != null &&
            _numberOfParticipants < selectedTour!.maxParticipants)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _numberOfParticipants++;
                  _updateParticipantControllers(_numberOfParticipants);
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Participant'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: AppTheme.primaryColor),
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ),
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
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          decoration: InputDecoration(
            labelText: 'Contact Number *',
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
            if (value.length != 11) {
              return 'Please enter exactly 11 digits';
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
              initialDate:
                  _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now().add(const Duration(days: 1)),
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
                          text: 'Terms and Conditions',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TermsOfServiceScreen(),
                                ),
                              );
                            }),
                      const TextSpan(text: ' and '),
                      TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PrivacyPolicyScreen(),
                                ),
                              );
                            }),
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
    if (selectedTour == null) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Select a tour to see booking summary',
            style: AppTheme.bodyMedium,
          ),
        ),
      );
    }

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
            if (selectedTour!.inclusionPrices.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...selectedTour!.inclusionPrices.entries.map(
                (entry) => _buildSummaryRow(
                  entry.key,
                  '₱${(entry.value * _numberOfParticipants).toStringAsFixed(2)}',
                ),
              ),
            ],
            const Divider(),
            _buildSummaryRow(
              'Total Amount',
              '₱${_totalPrice.toStringAsFixed(2)}',
              isTotal: true,
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
        onPressed: (_isLoading ||
                !_agreeToTerms ||
                selectedTour == null ||
                selectedGuide == null)
            ? null
            : _submitBooking,
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
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to submit booking'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final additionalParticipantNames = _participantControllers
          .map((controller) => controller.text.trim())
          .where((name) => name.isNotEmpty)
          .toList();

      final participantNames =
          [currentUser?.displayName ?? ''] + additionalParticipantNames;

      final selectedDate = _selectedDate ?? selectedTour!.startTime;
      final tourStartDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTour!.startTime.hour,
        selectedTour!.startTime.minute,
      );

      final newBooking = BookingModel(
        tourTitle: selectedTour!.title,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tourId: selectedTour!.id,
        touristId: user.uid,
        guideId: selectedGuide!.uid,
        bookingDate: DateTime.now(),
        tourStartDate: tourStartDate,
        numberOfParticipants: _numberOfParticipants,
        totalPrice: _totalPrice,
        specialRequests: null,
        participantNames: participantNames,
        contactNumber: _contactController.text.trim(),
        emergencyContact: null,
        duration: selectedTour!.duration,
      );

      await _db.createBooking(newBooking);

      // Create notification for booking submission
      final bookingNotification =
          _notificationService.createBookingSubmittedNotification(
        userId: user.uid,
        tourTitle: selectedTour!.title,
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
