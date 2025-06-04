import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watch_hub/services/order_service.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final OrderService _orderService = OrderService();

  Map<String, dynamic>? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final order = await _orderService.getOrderById(widget.orderId);

      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load order details: ${e.toString()}';
      });
    }
  }

  // Helper method to convert orderDate to DateTime
  DateTime _getOrderDate() {
    final orderDateValue = _order!['orderDate'];
    if (orderDateValue is Timestamp) {
      return orderDateValue.toDate();
    } else if (orderDateValue is String) {
      return DateTime.parse(orderDateValue);
    } else {
      return DateTime.now(); // Fallback
    }
  }

  String _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return '#FFA000'; // Amber
      case 'shipped':
        return '#2196F3'; // Blue
      case 'delivered':
        return '#4CAF50'; // Green
      case 'cancelled':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  int _getOrderStatusStep(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return 0;
      case 'shipped':
        return 1;
      case 'out for delivery':
        return 2;
      case 'delivered':
        return 3;
      case 'cancelled':
        return -1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId.substring(0, 8)}'),
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadOrderDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('TRY AGAIN'),
                    ),
                  ],
                ),
              )
              : _order == null
              ? const Center(child: Text('Order not found'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Status Card
                    _buildOrderStatusCard(theme),

                    const SizedBox(height: 24),

                    // Order Items
                    Text(
                      'Order Items',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildOrderItems(theme),

                    const SizedBox(height: 24),

                    // Order Summary
                    Text(
                      'Order Summary',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildOrderSummary(theme),

                    const SizedBox(height: 24),

                    // Shipping Details
                    Text(
                      'Shipping Details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildShippingDetails(theme),

                    const SizedBox(height: 24),

                    // Payment Details
                    Text(
                      'Payment Details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentDetails(theme),

                    const SizedBox(height: 32),

                    // Actions
                    if (_order!['orderStatus'].toLowerCase() != 'cancelled' &&
                        _order!['orderStatus'].toLowerCase() != 'delivered')
                      _buildActionButtons(theme),
                  ],
                ),
              ),
    );
  }

  Widget _buildOrderStatusCard(ThemeData theme) {
    final orderStatus = _order!['orderStatus'];
    final orderDate = _getOrderDate(); // Use helper method
    final formattedDate = DateFormat('MMMM dd, yyyy').format(orderDate);
    final statusStep = _getOrderStatusStep(orderStatus);

    // Check if screen is small
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(
                            _getOrderStatusColor(orderStatus).substring(1),
                            radix: 16,
                          ) |
                          0xFF000000,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    orderStatus,
                    style: TextStyle(
                      color: Color(
                        int.parse(
                              _getOrderStatusColor(orderStatus).substring(1),
                              radix: 16,
                            ) |
                            0xFF000000,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Order Date: $formattedDate',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            if (statusStep >= 0) ...[
              // Order Timeline - Responsive approach
              if (isSmallScreen)
                _buildVerticalTimeline(statusStep, theme)
              else
                _buildHorizontalTimeline(statusStep),
            ] else ...[
              // Cancelled Order
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Cancelled',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This order has been cancelled and cannot be processed further.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Original horizontal timeline for larger screens
  Widget _buildHorizontalTimeline(int statusStep) {
    return SizedBox(
      height: 100,
      child: Row(
        children: [
          Expanded(
            child: TimelineTile(
              alignment: TimelineAlign.center,
              isFirst: true,
              indicatorStyle: IndicatorStyle(
                width: 20,
                height: 20,
                indicator: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusStep >= 0 ? Colors.black : Colors.grey,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
              ),
              beforeLineStyle: LineStyle(
                color: statusStep >= 1 ? Colors.black : Colors.grey.shade300,
              ),
              endChild: _buildTimelineItem(
                'Processing',
                'Order confirmed',
                statusStep >= 0,
              ),
            ),
          ),
          Expanded(
            child: TimelineTile(
              alignment: TimelineAlign.center,
              indicatorStyle: IndicatorStyle(
                width: 20,
                height: 20,
                indicator: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        statusStep >= 1 ? Colors.black : Colors.grey.shade300,
                  ),
                  child:
                      statusStep >= 1
                          ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          )
                          : null,
                ),
              ),
              beforeLineStyle: LineStyle(
                color: statusStep >= 1 ? Colors.black : Colors.grey.shade300,
              ),
              afterLineStyle: LineStyle(
                color: statusStep >= 2 ? Colors.black : Colors.grey.shade300,
              ),
              endChild: _buildTimelineItem(
                'Shipped',
                'Order shipped',
                statusStep >= 1,
              ),
            ),
          ),
          Expanded(
            child: TimelineTile(
              alignment: TimelineAlign.center,
              indicatorStyle: IndicatorStyle(
                width: 20,
                height: 20,
                indicator: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        statusStep >= 2 ? Colors.black : Colors.grey.shade300,
                  ),
                  child:
                      statusStep >= 2
                          ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          )
                          : null,
                ),
              ),
              beforeLineStyle: LineStyle(
                color: statusStep >= 2 ? Colors.black : Colors.grey.shade300,
              ),
              afterLineStyle: LineStyle(
                color: statusStep >= 3 ? Colors.black : Colors.grey.shade300,
              ),
              endChild: _buildTimelineItem(
                'Out for Delivery',
                'On the way',
                statusStep >= 2,
              ),
            ),
          ),
          Expanded(
            child: TimelineTile(
              alignment: TimelineAlign.center,
              isLast: true,
              indicatorStyle: IndicatorStyle(
                width: 20,
                height: 20,
                indicator: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        statusStep >= 3 ? Colors.black : Colors.grey.shade300,
                  ),
                  child:
                      statusStep >= 3
                          ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          )
                          : null,
                ),
              ),
              beforeLineStyle: LineStyle(
                color: statusStep >= 3 ? Colors.black : Colors.grey.shade300,
              ),
              endChild: _buildTimelineItem(
                'Delivered',
                'Order completed',
                statusStep >= 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // New vertical timeline for small screens
  Widget _buildVerticalTimeline(int statusStep, ThemeData theme) {
    return Column(
      children: [
        _buildVerticalTimelineItem(
          'Processing',
          'Order confirmed',
          0,
          statusStep,
          isFirst: true,
        ),
        _buildVerticalTimelineItem('Shipped', 'Order shipped', 1, statusStep),
        _buildVerticalTimelineItem(
          'Out for Delivery',
          'On the way',
          2,
          statusStep,
        ),
        _buildVerticalTimelineItem(
          'Delivered',
          'Order completed',
          3,
          statusStep,
          isLast: true,
        ),
      ],
    );
  }

  // Timeline item for horizontal layout
  Widget _buildTimelineItem(String title, String subtitle, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isActive ? Colors.black : Colors.grey,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // New timeline item for vertical layout
  Widget _buildVerticalTimelineItem(
    String title,
    String subtitle,
    int step,
    int currentStep, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isActive = currentStep >= step;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.black : Colors.grey.shade300,
                ),
                child:
                    isActive
                        ? const Icon(Icons.check, color: Colors.white, size: 12)
                        : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color:
                        currentStep > step
                            ? Colors.black
                            : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.black : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(ThemeData theme) {
    final items = List<Map<String, dynamic>>.from(_order!['items']);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder:
            (context, index) => Divider(color: Colors.grey.shade200, height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          final name = item['name'];
          final price = item['price'];
          final quantity = item['quantity'];
          final imageUrl = item['imageUrl'];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: Image.memory(
                      base64Decode(imageUrl),
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
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PKR $price x $quantity',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'PKR ${(double.parse(price.toString()) * quantity).toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderSummary(ThemeData theme) {
    final totalAmount = _order!['totalAmount'];
    final shipping = _order!['shippingCost'] ?? 150.0;
    final taxRate = _order!['taxRate'] ?? 0.05;
    final taxAmount = _order!['taxAmount'] ?? (totalAmount * taxRate);
    final grandTotal =
        _order!['grandTotal'] ?? (totalAmount + shipping + taxAmount);
    final paymentMethod = _order!['paymentMethod'];
    final isCashPayment = paymentMethod == 'Cash on Delivery';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryRow(
              'Subtotal',
              'PKR ${totalAmount.toStringAsFixed(2)}',
              theme,
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Shipping',
              'PKR ${shipping.toStringAsFixed(2)}',
              theme,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Tax (${(taxRate * 100).toInt()}%)',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isCashPayment
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isCashPayment ? 'Cash' : 'Card',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color:
                              isCashPayment
                                  ? Colors.orange.shade800
                                  : Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'PKR ${taxAmount.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              'Total',
              'PKR ${grandTotal.toStringAsFixed(2)}',
              theme,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ThemeData theme, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:
              isTotal
                  ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
                  : theme.textTheme.bodyMedium,
        ),
        Text(
          value,
          style:
              isTotal
                  ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
                  : theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
        ),
      ],
    );
  }

  Widget _buildShippingDetails(ThemeData theme) {
    final shippingDetails = _order!['shippingDetails'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Delivery Address',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              shippingDetails['name'],
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(shippingDetails['phone'], style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              '${shippingDetails['addressLine1']}\n'
              '${shippingDetails['addressLine2'].isNotEmpty ? shippingDetails['addressLine2'] + "\n" : ""}'
              '${shippingDetails['city']}, ${shippingDetails['state']} ${shippingDetails['zipCode']}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails(ThemeData theme) {
    bool isLoading = false;
    final paymentMethod = _order!['paymentMethod'];
    final paymentStatus = _order!['paymentStatus'];
    final orderId = _order!['orderId']; // make sure this key exists

    final isCashPayment = paymentMethod.toLowerCase() == 'cash on delivery';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment_outlined, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Payment Method',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      paymentMethod,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            paymentStatus == 'Paid'
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        paymentStatus,
                        style: TextStyle(
                          color:
                              paymentStatus == 'Paid'
                                  ? Colors.green
                                  : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                // Show button only if payment is pending and method is cash on delivery
                if (paymentStatus == 'Pending' && isCashPayment)
                  const SizedBox(height: 12),

                // Check if it's user or admin
                if (paymentStatus == 'Pending' && isCashPayment)
                  SizedBox(
                    height: 40,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          isLoading
                              // ignore: dead_code
                              ? null
                              : () async {
                                setState(() {
                                  isLoading = true;
                                });
                                try {
                                  final service = OrderService();
                                  await service.updatePaymentStatus(
                                    orderId,
                                    'Paid',
                                  );
                                  setState(() {
                                    _order!['paymentStatus'] = 'Paid';
                                  });
                                } catch (e) {
                                  // handle error appropriately
                                } finally {
                                  setState(() {
                                    isLoading = false;
                                  });
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                      child:
                          isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text("Complete Payment"),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    final paymentStatus = _order!['paymentStatus'].toString().toLowerCase();
    final orderStatus = _order!['orderStatus'].toString().toLowerCase();

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Implement contact support functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contacting support...')),
              );
            },
            icon: const Icon(Icons.support_agent),
            label: const Text('CONTACT SUPPORT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (orderStatus == 'processing' && paymentStatus != 'paid')
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Show cancel confirmation dialog
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Cancel Order'),
                        content: const Text(
                          'Are you sure you want to cancel this order? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('NO'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);

                              try {
                                setState(() {
                                  _isLoading = true;
                                });

                                await _orderService.updateOrderStatus(
                                  widget.orderId,
                                  'Cancelled',
                                );

                                await _loadOrderDetails();

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Order cancelled successfully',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to cancel order: ${e.toString()}',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('YES, CANCEL'),
                          ),
                        ],
                      ),
                );
              },
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('CANCEL ORDER'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
