import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tourmate_app/models/booking_model.dart';
import 'package:tourmate_app/models/payment_model.dart';
import 'package:tourmate_app/services/payment_service.dart';
import 'package:tourmate_app/services/auth_service.dart';
import 'package:tourmate_app/services/wallet_service.dart';
import '../../utils/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  final BookingModel booking;

  const PaymentScreen({super.key, required this.booking});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final WalletService _walletService = WalletService();
  StreamSubscription<double>? _balanceSubscription;
  double _currentWalletBalance = 0.0;

  PaymentMethod _selectedPaymentMethod = PaymentMethod.creditCard;
  bool _isProcessing = false;
  bool _saveCardForFuture = false;
  bool _termsAccepted = false;

  // Card details
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardholderNameController =
      TextEditingController();

  // E-wallet details
  final TextEditingController _phoneNumberController = TextEditingController();

  // Bank transfer details
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  String _selectedBank = 'BDO';

  final List<String> _banks = [
    'BDO',
    'BPI',
    'Metrobank',
    'PNB',
    'UnionBank',
    'Security Bank',
  ];

  @override
  void initState() {
    super.initState();
    final user = _authService.getCurrentUser();
    if (user != null) {
      _balanceSubscription = _walletService.getBalanceStream(user.uid).listen((
        balance,
      ) {
        setState(() {
          _currentWalletBalance = balance;
        });
      });
    }
  }

  @override
  void dispose() {
    _balanceSubscription?.cancel();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardholderNameController.dispose();
    _phoneNumberController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Payment'),
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
              // Booking Summary
              _buildBookingSummary(),

              const SizedBox(height: 24),

              // Payment Method Selection
              _buildPaymentMethodSelection(),

              const SizedBox(height: 24),

              // Payment Details Form
              _buildPaymentDetailsForm(),

              const SizedBox(height: 24),

              // Terms and Conditions
              _buildTermsSection(),

              const SizedBox(height: 32),

              // Pay Now Button
              _buildPayNowButton(),
            ],
          ),
        ),
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
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/default_tour.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tour Booking', // Would be tour title
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.booking.numberOfParticipants} participants • ${widget.booking.tourStartDate.day}/${widget.booking.tourStartDate.month}/${widget.booking.tourStartDate.year}',
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Tour Price',
              '₱${widget.booking.totalPrice.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment will be processed securely. You will receive a confirmation email once payment is completed.',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryColor,
                      ),
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

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.bodyMedium),
        Text(
          value,
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Method', style: AppTheme.headlineSmall),
        const SizedBox(height: 16),
        ...PaymentMethod.values.map(
          (method) => _buildPaymentMethodOption(method),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodOption(PaymentMethod method) {
    final isSelected = _selectedPaymentMethod == method;
    final isInsufficientFunds =
        method == PaymentMethod.tourMateWallet &&
        _currentWalletBalance < widget.booking.totalPrice;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                method.paymentMethodIcon,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  method.paymentMethodDisplayText,
                  style: AppTheme.bodyLarge.copyWith(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (method == PaymentMethod.tourMateWallet &&
                  !isInsufficientFunds)
                Text(
                  '₱${_currentWalletBalance.toStringAsFixed(2)}',
                  style: AppTheme.bodySmall.copyWith(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary,
                  ),
                ),
              if (method == PaymentMethod.tourMateWallet && isInsufficientFunds)
                Text(
                  'Insufficient Funds',
                  style: AppTheme.bodySmall.copyWith(color: Colors.red),
                ),
              if (isSelected)
                Icon(Icons.check_circle, color: AppTheme.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsForm() {
    switch (_selectedPaymentMethod) {
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        return _buildCardPaymentForm();
      case PaymentMethod.paypal:
        return _buildPayPalForm();
      case PaymentMethod.gcash:
      case PaymentMethod.paymaya:
        return _buildEWalletForm();
      case PaymentMethod.bankTransfer:
        return _buildBankTransferForm();
      case PaymentMethod.cash:
        return _buildCashPaymentForm();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCardPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Card Details', style: AppTheme.headlineSmall),
        const SizedBox(height: 16),

        // Card Number
        TextFormField(
          controller: _cardNumberController,
          decoration: InputDecoration(
            labelText: 'Card Number',
            hintText: '1234 5678 9012 3456',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            _CardNumberFormatter(),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter card number';
            }
            if (value.replaceAll(' ', '').length != 16) {
              return 'Please enter a valid 16-digit card number';
            }
            return null;
          },
        ),

        const SizedBox(height: 12),

        // Expiry and CVV
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryController,
                decoration: InputDecoration(
                  labelText: 'Expiry Date',
                  hintText: 'MM/YY',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _ExpiryDateFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (value.length != 5) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  hintText: '123',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (value.length < 3) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Cardholder Name
        TextFormField(
          controller: _cardholderNameController,
          decoration: InputDecoration(
            labelText: 'Cardholder Name',
            hintText: 'John Doe',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter cardholder name';
            }
            return null;
          },
        ),

        const SizedBox(height: 12),

        // Save card option
        CheckboxListTile(
          value: _saveCardForFuture,
          onChanged: (value) {
            setState(() {
              _saveCardForFuture = value ?? false;
            });
          },
          title: Text(
            'Save card for future payments',
            style: AppTheme.bodyMedium,
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildPayPalForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PayPal Payment', style: AppTheme.headlineSmall),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0070BA).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF0070BA).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Image.asset(
                'assets/images/paypal_logo.png',
                height: 40,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.account_balance_wallet,
                    size: 40,
                    color: Color(0xFF0070BA),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'You will be redirected to PayPal to complete your payment securely.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEWalletForm() {
    final walletName = _selectedPaymentMethod == PaymentMethod.gcash
        ? 'GCash'
        : 'PayMaya';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$walletName Payment', style: AppTheme.headlineSmall),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _selectedPaymentMethod == PaymentMethod.gcash
                ? const Color(0xFF0066CC).withOpacity(0.1)
                : const Color(0xFFFF6600).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedPaymentMethod == PaymentMethod.gcash
                  ? const Color(0xFF0066CC).withOpacity(0.3)
                  : const Color(0xFFFF6600).withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                _selectedPaymentMethod.paymentMethodIcon,
                size: 40,
                color: _selectedPaymentMethod == PaymentMethod.gcash
                    ? const Color(0xFF0066CC)
                    : const Color(0xFFFF6600),
              ),
              const SizedBox(height: 12),
              Text('Enter your $walletName number', style: AppTheme.bodyMedium),
            ],
          ),
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _phoneNumberController,
          decoration: InputDecoration(
            labelText: '$walletName Number',
            hintText: '+63 912 345 6789',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $walletName number';
            }
            if (value.length < 10) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'You will receive a payment confirmation SMS from $walletName after completing the transaction.',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.accentColor),
          ),
        ),
      ],
    );
  }

  Widget _buildBankTransferForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bank Transfer Details', style: AppTheme.headlineSmall),
        const SizedBox(height: 16),

        // Bank Selection
        DropdownButtonFormField<String>(
          value: _selectedBank,
          decoration: InputDecoration(
            labelText: 'Select Bank',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: _banks.map((bank) {
            return DropdownMenuItem(value: bank, child: Text(bank));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedBank = value!;
            });
          },
        ),

        const SizedBox(height: 12),

        // Account Number
        TextFormField(
          controller: _accountNumberController,
          decoration: InputDecoration(
            labelText: 'Account Number',
            hintText: 'Enter your account number',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter account number';
            }
            return null;
          },
        ),

        const SizedBox(height: 12),

        // Account Name
        TextFormField(
          controller: _accountNameController,
          decoration: InputDecoration(
            labelText: 'Account Name',
            hintText: 'Enter account holder name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter account name';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bank Transfer Instructions:',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Transfer ₱${widget.booking.totalPrice.toStringAsFixed(2)} to the account details above\n'
                '2. Use booking reference: ${widget.booking.id}\n'
                '3. Payment will be verified within 24 hours\n'
                '4. You will receive confirmation once payment is processed',
                style: AppTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCashPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cash Payment', style: AppTheme.headlineSmall),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(Icons.money, size: 40, color: AppTheme.successColor),
              const SizedBox(height: 12),
              Text(
                'Cash Payment at Office',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Please visit our office to make cash payment. Bring your booking confirmation and valid ID.',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Office Details:',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'TourMate Office\n123 Rizal Avenue, Cebu City\nPhone: +63 32 123 4567\nHours: Mon-Fri 9AM-6PM',
                style: TextStyle(fontSize: 14),
              ),
            ],
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
                value: _termsAccepted,
                onChanged: (value) {
                  setState(() {
                    _termsAccepted = value ?? false;
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
                        text: 'Refund Policy',
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

  Widget _buildPayNowButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Pay ₱${widget.booking.totalPrice.toStringAsFixed(2)}',
                style: AppTheme.buttonText,
              ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Prepare payment details based on method
      Map<String, dynamic>? paymentDetails;
      switch (_selectedPaymentMethod) {
        case PaymentMethod.creditCard:
        case PaymentMethod.debitCard:
          paymentDetails = {
            'cardNumber': _cardNumberController.text.replaceAll(' ', ''),
            'expiry': _expiryController.text,
            'cvv': _cvvController.text,
            'cardholderName': _cardholderNameController.text,
            'saveCard': _saveCardForFuture,
          };
          break;
        case PaymentMethod.gcash:
        case PaymentMethod.paymaya:
          paymentDetails = {'phoneNumber': _phoneNumberController.text};
          break;
        case PaymentMethod.bankTransfer:
          paymentDetails = {
            'bank': _selectedBank,
            'accountNumber': _accountNumberController.text,
            'accountName': _accountNameController.text,
          };
          break;
        default:
          paymentDetails = {};
      }

      final payment = await _paymentService.processPayment(
        bookingId: widget.booking.id,
        userId: user.uid,
        guideId: widget.booking.guideId ?? '',
        amount: widget.booking.totalPrice,
        paymentMethod: _selectedPaymentMethod,
        paymentDetails: paymentDetails,
      );

      if (payment != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return success
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}

// Custom input formatters
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && i + 1 != text.length) {
        buffer.write('/');
      }
    }

    return TextEditingValue(
      text: buffer.length <= 5
          ? buffer.toString()
          : buffer.toString().substring(0, 5),
      selection: TextSelection.collapsed(
        offset: buffer.length <= 5 ? buffer.length : 5,
      ),
    );
  }
}
