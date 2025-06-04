import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:watch_hub/models/recent_activity.model.dart';
import 'package:watch_hub/services/cart_service.dart';
import 'package:watch_hub/services/order_service.dart';
import 'package:watch_hub/services/recent_activity_service.dart';
import 'package:watch_hub/services/user_service.dart';
import 'package:watch_hub/services/watch_service.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartService _cartService = CartService();
  final OrderService _orderService = OrderService();
  final UserService _userService = UserService();
  final WatchService _watchService = WatchService();
  final RecentActivityService _recentActivityService = RecentActivityService();
  final User? _user = FirebaseAuth.instance.currentUser;

  int _currentStep = 0;
  bool _isProcessing = false;
  bool _stockUpdateFailed = false;
  List<String> _stockUpdateErrors = [];

  // Form keys for validation
  final _shippingFormKey = GlobalKey<FormState>();
  final _paymentFormKey = GlobalKey<FormState>();

  // Controllers for shipping information
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();

  // Payment method
  String _selectedPaymentMethod = 'Cash on Delivery';
  final List<String> _paymentMethods = [
    'Cash on Delivery',
    'Credit/Debit Card',
    'EasyPaisa',
    'JazzCash',
  ];

  // Card details controllers
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  // Tax rates
  final double _cardPaymentTaxRate = 0.05; // 5% for card payments
  final double _cashPaymentTaxRate = 0.15; // 15% for cash on delivery

  // Shipping cost
  final double _shippingCost = 150.0;

  // User ID
  late final String? userId = _user?.uid;

  // Calculated values
  double _taxAmount = 0.0;
  double _grandTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _calculateTaxAndTotal();
  }

  void _calculateTaxAndTotal() {
    // Determine tax rate based on payment method
    final taxRate =
        _isCashPayment() ? _cashPaymentTaxRate : _cardPaymentTaxRate;

    // Calculate tax amount
    _taxAmount = widget.totalAmount * taxRate;

    // Calculate grand total
    _grandTotal = widget.totalAmount + _shippingCost + _taxAmount;

    setState(() {});
  }

  bool _isCashPayment() {
    return _selectedPaymentMethod == 'Cash on Delivery';
  }

  Future<void> _loadUserDetails() async {
    if (userId == null) return;

    try {
      final userDetails = await _userService.getUserDetails(userId!);
      if (userDetails != null) {
        setState(() {
          _nameController.text = userDetails['name'] ?? '';
          _phoneController.text = userDetails['phone'] ?? '';
          _addressLine1Controller.text = userDetails['address'] ?? '';
          _addressLine2Controller.text = userDetails['address2'] ?? '';
          _cityController.text = userDetails['city'] ?? '';
          _stateController.text = userDetails['state'] ?? '';
          _zipCodeController.text = userDetails['zipCode'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading user details: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  // New method to update stock counts
  Future<bool> _updateStockCounts() async {
    _stockUpdateErrors = [];
    bool allUpdatesSuccessful = true;

    try {
      // Create a list to track stock updates for logging
      final List<Map<String, dynamic>> stockUpdates = [];

      // Process each item in the cart
      for (var item in widget.cartItems) {
        final String watchId = item['watchId'];
        final int quantity = item['quantity'];
        final int currentStock = item['stockCount'] ?? 0;
        final String watchName = item['name'] ?? 'Unknown Watch';

        // Calculate new stock count
        final int newStockCount = currentStock - quantity;

        // Validate stock count
        if (newStockCount < 0) {
          _stockUpdateErrors.add(
            'Not enough stock for $watchName (ID: $watchId)',
          );
          allUpdatesSuccessful = false;
          continue;
        }

        try {
          // Update the stock in Firestore
          await _watchService.updateWatchStock(watchId, newStockCount);

          // Add to successful updates list for logging
          stockUpdates.add({
            'watchId': watchId,
            'name': watchName,
            'previousStock': currentStock,
            'newStock': newStockCount,
            'quantitySold': quantity,
          });
        } catch (e) {
          _stockUpdateErrors.add('Failed to update stock for $watchName: $e');
          allUpdatesSuccessful = false;
        }
      }

      // Log the stock update activity
      if (stockUpdates.isNotEmpty) {
        await _recentActivityService.addRecentActivity(
          RecentActivity(
            type: 'Stock_Update',
            title: 'Stock Updated After Purchase',
            description:
                'Updated stock for ${stockUpdates.length} products after order completion',
            timestamp: DateTime.now(),
          ),
        );
      }

      return allUpdatesSuccessful;
    } catch (e) {
      _stockUpdateErrors.add('Error updating stock: $e');
      return false;
    }
  }

  Future<void> _placeOrder() async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be logged in to place an order'),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _stockUpdateFailed = false;
    });

    try {
      // Determine tax rate based on payment method
      final taxRate =
          _isCashPayment() ? _cashPaymentTaxRate : _cardPaymentTaxRate;

      // Create order object
      final orderData = {
        'userId': userId,
        'items': widget.cartItems,
        'totalAmount': widget.totalAmount,
        'shippingCost': _shippingCost,
        'taxRate': taxRate,
        'taxAmount': _taxAmount,
        'grandTotal': _grandTotal,
        'shippingDetails': {
          'name': _nameController.text,
          'phone': _phoneController.text,
          'addressLine1': _addressLine1Controller.text,
          'addressLine2': _addressLine2Controller.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'zipCode': _zipCodeController.text,
        },
        'paymentMethod': _selectedPaymentMethod,
        'paymentStatus':
            _selectedPaymentMethod == 'Cash on Delivery' ? 'Pending' : 'Paid',
        'orderStatus': 'Processing',
        'orderDate': Timestamp.now(),
      };

      // Create the order
      final orderId = await _orderService.createOrder(orderData);

      // Update stock counts for each product
      final stockUpdateSuccess = await _updateStockCounts();

      if (!stockUpdateSuccess) {
        setState(() {
          _stockUpdateFailed = true;
        });

        // Show warning but continue with order process
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Warning: Some stock updates failed. Please check inventory.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'DETAILS',
                onPressed: () {
                  _showStockUpdateErrorsDialog();
                },
              ),
            ),
          );
        }
      }

      // Clear the cart
      await _cartService.clearCart(userId!);

      // Add to recent activity
      await _recentActivityService.addRecentActivity(
        RecentActivity(
          type: 'New_Order',
          title: 'New Order Placed',
          description:
              'Order #$orderId placed for PKR ${_grandTotal.toStringAsFixed(2)}',
          timestamp: DateTime.now(),
        ),
      );

      // Show success and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order placed successfully! Order ID: $orderId'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to order confirmation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => OrderConfirmationScreen(
                  orderId: orderId,
                  stockUpdateFailed: _stockUpdateFailed,
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: ${e.toString()}'),
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

  void _showStockUpdateErrorsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Stock Update Issues'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The following issues occurred while updating stock:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    _stockUpdateErrors.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(child: Text(_stockUpdateErrors[index])),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Please check your inventory and update stock manually if needed.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CLOSE'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout'), elevation: 0),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0) {
            if (_shippingFormKey.currentState!.validate()) {
              setState(() {
                _currentStep += 1;
              });
            }
          } else if (_currentStep == 1) {
            if (_selectedPaymentMethod == 'Credit/Debit Card') {
              if (_paymentFormKey.currentState!.validate()) {
                setState(() {
                  _currentStep += 1;
                });
              }
            } else {
              setState(() {
                _currentStep += 1;
              });
            }
          } else if (_currentStep == 2) {
            _placeOrder();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep -= 1;
            });
          } else {
            Navigator.pop(context);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _currentStep == 2 ? 'PLACE ORDER' : 'CONTINUE',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      child: const Text('BACK'),
                    ),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Shipping'),
            content: _buildShippingForm(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Payment'),
            content: _buildPaymentForm(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Review'),
            content: _buildOrderSummary(),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
        ],
      ),
    );
  }

  Widget _buildShippingForm() {
    return Form(
      key: _shippingFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressLine1Controller,
            decoration: const InputDecoration(
              labelText: 'Address Line 1',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressLine2Controller,
            decoration: const InputDecoration(
              labelText: 'Address Line 2 (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(
                    labelText: 'State/Province',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _zipCodeController,
            decoration: const InputDecoration(
              labelText: 'ZIP/Postal Code',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your ZIP code';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Payment Method',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          _paymentMethods.length,
          (index) => RadioListTile<String>(
            title: Row(
              children: [
                Text(_paymentMethods[index]),
                if (_paymentMethods[index] == 'Cash on Delivery')
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '15% Tax',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (_paymentMethods[index] == 'Credit/Debit Card' ||
                    _paymentMethods[index] == 'EasyPaisa' ||
                    _paymentMethods[index] == 'JazzCash')
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '5% Tax',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            value: _paymentMethods[index],
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
                _calculateTaxAndTotal();
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedPaymentMethod == 'Credit/Debit Card')
          Form(
            key: _paymentFormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _cardNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Card Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your card number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cardHolderController,
                  decoration: const InputDecoration(
                    labelText: 'Card Holder Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter card holder name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiryDateController,
                        decoration: const InputDecoration(
                          labelText: 'Expiry Date (MM/YY)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvController,
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal:'),
                  Text('PKR ${widget.totalAmount.toStringAsFixed(2)}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Shipping:'),
                  Text('PKR ${_shippingCost.toStringAsFixed(2)}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Tax:'),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _isCashPayment()
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _isCashPayment() ? '15%' : '5%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color:
                                _isCashPayment()
                                    ? Colors.orange.shade800
                                    : Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text('PKR ${_taxAmount.toStringAsFixed(2)}'),
                ],
              ),
              Divider(height: 24, color: Colors.grey.shade300),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'PKR ${_grandTotal.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.cartItems.length,
            separatorBuilder:
                (context, index) =>
                    Divider(color: Colors.grey.shade300, height: 1),
            itemBuilder: (context, index) {
              final item = widget.cartItems[index];
              final name = item['name'];
              final price = item['price'];
              final quantity = item['quantity'];
              final imageUrl = item['imageUrl'];
              final stockCount = item['stockCount'] ?? 0;

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: Image.memory(
                      base64Decode(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            stockCount > quantity
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Stock: $stockCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color:
                              stockCount > quantity
                                  ? Colors.green.shade800
                                  : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text('PKR $price x $quantity'),
                trailing: Text(
                  'PKR ${(double.parse(price.toString()) * quantity).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        _buildPriceRow(
          'Subtotal',
          'PKR ${widget.totalAmount.toStringAsFixed(2)}',
        ),
        _buildPriceRow('Shipping', 'PKR ${_shippingCost.toStringAsFixed(2)}'),
        _buildPriceRow(
          _isCashPayment() ? 'Tax (15%)' : 'Tax (5%)',
          'PKR ${_taxAmount.toStringAsFixed(2)}',
          taxType: _isCashPayment() ? 'cash' : 'card',
        ),
        const Divider(height: 32),
        _buildPriceRow(
          'Total',
          'PKR ${_grandTotal.toStringAsFixed(2)}',
          isTotal: true,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shipping Details',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${_nameController.text}\n'
                '${_addressLine1Controller.text}\n'
                '${_addressLine2Controller.text.isNotEmpty ? _addressLine2Controller.text + "\n" : ""}'
                '${_cityController.text}, ${_stateController.text} ${_zipCodeController.text}\n'
                'Phone: ${_phoneController.text}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment Method',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(_selectedPaymentMethod),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _isCashPayment()
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _isCashPayment() ? '15% Tax' : '5% Tax',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color:
                            _isCashPayment()
                                ? Colors.orange.shade800
                                : Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_isProcessing)
          const Padding(
            padding: EdgeInsets.only(top: 24.0),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isTotal = false,
    String? taxType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 18 : 16,
                ),
              ),
              if (taxType != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        taxType == 'cash'
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    taxType == 'cash' ? 'Cash' : 'Card',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color:
                          taxType == 'cash'
                              ? Colors.orange.shade800
                              : Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }
}

class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;
  final bool stockUpdateFailed;

  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
    this.stockUpdateFailed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF000000), // Pure black
                      Color(0xFF333333), // Dark gray
                      Color(0xFF555555), // Medium gray
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 32),
              const Text(
                'Order Confirmed!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Your order #$orderId has been placed successfully.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              const Text(
                'We\'ll send you a confirmation email with your order details and tracking information.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              if (stockUpdateFailed) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange.shade800,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Stock Update Warning',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'There were some issues updating the stock for some items. Our team has been notified and will resolve this soon.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/user_index',
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'CONTINUE SHOPPING',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/user_orders');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'VIEW MY ORDERS',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
