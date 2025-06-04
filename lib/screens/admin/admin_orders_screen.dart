import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:watch_hub/components/snackbar.component.dart';
import 'package:watch_hub/screens/admin/admin_drawer.dart';
import 'package:watch_hub/screens/admin/admin_order_details_screen.dart';
import 'package:watch_hub/services/order_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final OrderService _orderService = OrderService();

  // Filter states
  String _selectedPaymentFilter = 'All';
  String _selectedStatusFilter = 'All';
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';

  // Filter options
  final List<String> _paymentFilters = [
    'All',
    'Paid',
    'Pending',
    'Failed',
    'Cancelled',
  ];
  final List<String> _statusFilters = [
    'All',
    'Processing',
    'Shipped',
    'Out for Delivery',
    'Delivered',
    'Cancelled',
  ];

  // Controllers
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Safe date parsing function to handle both Timestamp and String
  DateTime? _parseOrderDate(dynamic orderDate) {
    try {
      if (orderDate == null) return null;

      // Handle Firestore Timestamp
      if (orderDate is Timestamp) {
        return orderDate.toDate();
      }

      // Handle String dates
      if (orderDate is String) {
        // Try different date formats
        try {
          // ISO 8601 format
          return DateTime.parse(orderDate);
        } catch (e) {
          try {
            // Try common date formats
            return DateFormat('yyyy-MM-dd HH:mm:ss').parse(orderDate);
          } catch (e) {
            try {
              return DateFormat('yyyy-MM-dd').parse(orderDate);
            } catch (e) {
              try {
                return DateFormat('dd/MM/yyyy').parse(orderDate);
              } catch (e) {
                debugPrint('Unable to parse date string: $orderDate');
                return null;
              }
            }
          }
        }
      }

      // Handle int (milliseconds since epoch)
      if (orderDate is int) {
        return DateTime.fromMillisecondsSinceEpoch(orderDate);
      }

      debugPrint('Unknown date format: ${orderDate.runtimeType} - $orderDate');
      return null;
    } catch (e) {
      debugPrint('Error parsing order date: $e');
      return null;
    }
  }

  // Get color based on order status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.amber;
      case 'out for delivery':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get color based on payment status
  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.amber;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Filter orders based on selected criteria
  List<QueryDocumentSnapshot> _filterOrders(
    List<QueryDocumentSnapshot> orders,
  ) {
    return orders.where((order) {
      final data = order.data() as Map<String, dynamic>;

      // Payment filter
      if (_selectedPaymentFilter != 'All') {
        final paymentStatus = data['paymentStatus'] ?? '';
        final isCancelled =
            (data['orderStatus'] ?? '').toLowerCase() == 'cancelled';
        final displayPaymentStatus = isCancelled ? 'Cancelled' : paymentStatus;

        if (displayPaymentStatus != _selectedPaymentFilter) {
          return false;
        }
      }

      // Status filter
      if (_selectedStatusFilter != 'All') {
        final orderStatus = data['orderStatus'] ?? '';
        if (orderStatus != _selectedStatusFilter) {
          return false;
        }
      }

      // Date filter with safe parsing
      if (_selectedDateRange != null) {
        final orderDate = _parseOrderDate(data['orderDate']);
        if (orderDate == null) return false;

        final startDate = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );
        final endDate = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
          23,
          59,
          59,
        );

        if (orderDate.isBefore(startDate) || orderDate.isAfter(endDate)) {
          return false;
        }
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final orderId = (data['orderId'] ?? '').toLowerCase();
        final customerName = (data['customerName'] ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();

        if (!orderId.contains(query) && !customerName.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Show date range picker
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  // Clear all filters
  void _clearFilters() {
    setState(() {
      _selectedPaymentFilter = 'All';
      _selectedStatusFilter = 'All';
      _selectedDateRange = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  // Show order status progression dialog
  void _showOrderStatusDialog(QueryDocumentSnapshot order) {
    showDialog(
      context: context,
      builder:
          (context) => _OrderStatusDialog(
            order: order,
            orderService: _orderService,
            onStatusUpdated: () {
              // Refresh the list
              setState(() {});
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Orders'),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Orders refreshed'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const AdminDrawer(selectedIndex: 5),
      body: Column(
        children: [
          // Search and filter summary
          _buildSearchAndFilterSummary(),

          // Orders list
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('orders')
                        .orderBy('orderDate', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorState();
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allOrders = snapshot.data!.docs;
                  final filteredOrders = _filterOrders(allOrders);

                  if (filteredOrders.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _buildOrderCard(order);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSummary() {
    final hasActiveFilters =
        _selectedPaymentFilter != 'All' ||
        _selectedStatusFilter != 'All' ||
        _selectedDateRange != null ||
        _searchQuery.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by Order ID',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          if (hasActiveFilters) ...[
            const SizedBox(height: 12),
            // Active filters summary
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_selectedPaymentFilter != 'All')
                  _buildFilterChip('Payment: $_selectedPaymentFilter', () {
                    setState(() {
                      _selectedPaymentFilter = 'All';
                    });
                  }),
                if (_selectedStatusFilter != 'All')
                  _buildFilterChip('Status: $_selectedStatusFilter', () {
                    setState(() {
                      _selectedStatusFilter = 'All';
                    });
                  }),
                if (_selectedDateRange != null)
                  _buildFilterChip(
                    'Date: ${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd').format(_selectedDateRange!.end)}',
                    () {
                      setState(() {
                        _selectedDateRange = null;
                      });
                    },
                  ),
                // Clear all filters button
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: Colors.blue.shade50,
      deleteIconColor: Colors.blue.shade700,
      labelStyle: TextStyle(color: Colors.blue.shade700),
    );
  }

  Widget _buildOrderCard(QueryDocumentSnapshot order) {
    final data = order.data() as Map<String, dynamic>;
    final orderStatus = data['orderStatus'] ?? 'Unknown';
    final paymentStatus = data['paymentStatus'] ?? 'Unknown';
    final orderId = data['orderId'] ?? 'N/A';
    final orderDate = _parseOrderDate(data['orderDate']); // Safe parsing
    final totalAmount = data['totalAmount'] ?? 0.0;

    final isCancelled = orderStatus.toLowerCase() == 'cancelled';
    final displayPaymentStatus =
        isCancelled ? 'Cancelled Payment' : paymentStatus;
    final paymentStatusColor =
        isCancelled ? Colors.red : _getPaymentStatusColor(paymentStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => AdminOrderDetailsScreen(orderId: order.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Order Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getStatusColor(orderStatus).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: _getStatusColor(orderStatus),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Order Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  orderId,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Safe date display
                              if (orderDate != null)
                                Text(
                                  DateFormat('MMM dd, yyyy').format(orderDate),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                )
                              else
                                Text(
                                  'Invalid Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total: PKR ${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Status Row
                          Row(
                            children: [
                              // Order Status
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    orderStatus,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _getStatusColor(orderStatus),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  orderStatus,
                                  style: TextStyle(
                                    color: _getStatusColor(orderStatus),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Payment Status
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: paymentStatusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: paymentStatusColor,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.payment,
                                      size: 12,
                                      color: paymentStatusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      displayPaymentStatus,
                                      style: TextStyle(
                                        color: paymentStatusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Order Status Management Section
                _buildOrderStatusManagement(order),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderStatusManagement(QueryDocumentSnapshot order) {
    final data = order.data() as Map<String, dynamic>;
    final orderStatus = data['orderStatus'] ?? 'Unknown';
    final paymentStatus = data['paymentStatus'] ?? 'Unknown';

    // Define the order progression
    final statusSteps = [
      'Processing',
      'Shipped',
      'Out for Delivery',
      'Delivered',
    ];
    final currentStepIndex = statusSteps.indexOf(orderStatus);

    final canProgress =
        currentStepIndex >= 0 &&
        currentStepIndex < statusSteps.length - 1 &&
        paymentStatus.toLowerCase() == 'paid' &&
        orderStatus.toLowerCase() != 'cancelled';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                'Order Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress steps
          Row(
            children: [
              Expanded(
                child: _buildProgressSteps(statusSteps, currentStepIndex),
              ),
              const SizedBox(width: 12),

              // Action button
              if (canProgress)
                ElevatedButton.icon(
                  onPressed: () => _showOrderStatusDialog(order),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: Text(
                    'Advance to\n${statusSteps[currentStepIndex + 1]}',
                    style: const TextStyle(fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(80, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusMessage(orderStatus, paymentStatus),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSteps(List<String> steps, int currentIndex) {
    return Row(
      children:
          steps.asMap().entries.map((entry) {
            final index = entry.key;
            final _ = entry.value;
            final isCompleted = index <= currentIndex;
            final isCurrent = index == currentIndex;

            return Expanded(
              child: Row(
                children: [
                  // Step circle
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? Colors.blue : Colors.grey.shade300,
                      border: Border.all(
                        color: isCurrent ? Colors.blue : Colors.grey.shade400,
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child:
                        isCompleted
                            ? const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            )
                            : null,
                  ),

                  // Connecting line (except for last step)
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted ? Colors.blue : Colors.grey.shade300,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
    );
  }

  String _getStatusMessage(String orderStatus, String paymentStatus) {
    if (orderStatus.toLowerCase() == 'cancelled') {
      return 'Order\nCancelled';
    }
    if (orderStatus.toLowerCase() == 'delivered') {
      return 'Order\nCompleted';
    }
    if (paymentStatus.toLowerCase() == 'pending') {
      return 'Awaiting\nPayment';
    }
    if (paymentStatus.toLowerCase() == 'failed') {
      return 'Payment\nFailed';
    }
    return 'No Action\nNeeded';
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => _FilterBottomSheet(
            selectedPaymentFilter: _selectedPaymentFilter,
            selectedStatusFilter: _selectedStatusFilter,
            selectedDateRange: _selectedDateRange,
            paymentFilters: _paymentFilters,
            statusFilters: _statusFilters,
            onFiltersChanged: (paymentFilter, statusFilter, dateRange) {
              setState(() {
                _selectedPaymentFilter = paymentFilter;
                _selectedStatusFilter = statusFilter;
                _selectedDateRange = dateRange;
              });
            },
            onDateRangeSelect: _selectDateRange,
          ),
    );
  }
}

// Filter bottom sheet widget (same as before)
class _FilterBottomSheet extends StatefulWidget {
  final String selectedPaymentFilter;
  final String selectedStatusFilter;
  final DateTimeRange? selectedDateRange;
  final List<String> paymentFilters;
  final List<String> statusFilters;
  final Function(String, String, DateTimeRange?) onFiltersChanged;
  final VoidCallback onDateRangeSelect;

  const _FilterBottomSheet({
    required this.selectedPaymentFilter,
    required this.selectedStatusFilter,
    required this.selectedDateRange,
    required this.paymentFilters,
    required this.statusFilters,
    required this.onFiltersChanged,
    required this.onDateRangeSelect,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String _tempPaymentFilter;
  late String _tempStatusFilter;
  late DateTimeRange? _tempDateRange;

  @override
  void initState() {
    super.initState();
    _tempPaymentFilter = widget.selectedPaymentFilter;
    _tempStatusFilter = widget.selectedStatusFilter;
    _tempDateRange = widget.selectedDateRange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Orders',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Payment Status Filter
          const Text(
            'Payment Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                widget.paymentFilters.map((filter) {
                  return FilterChip(
                    label: Text(filter),
                    selected: _tempPaymentFilter == filter,
                    onSelected: (selected) {
                      setState(() {
                        _tempPaymentFilter = filter;
                      });
                    },
                  );
                }).toList(),
          ),

          const SizedBox(height: 20),

          // Order Status Filter
          const Text(
            'Order Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                widget.statusFilters.map((filter) {
                  return FilterChip(
                    label: Text(filter),
                    selected: _tempStatusFilter == filter,
                    onSelected: (selected) {
                      setState(() {
                        _tempStatusFilter = filter;
                      });
                    },
                  );
                }).toList(),
          ),

          const SizedBox(height: 20),

          // Date Range Filter
          const Text(
            'Date Range',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              Navigator.pop(context);
              widget.onDateRangeSelect();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range),
                  const SizedBox(width: 8),
                  Text(
                    _tempDateRange == null
                        ? 'Select date range'
                        : '${DateFormat('MMM dd, yyyy').format(_tempDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_tempDateRange!.end)}',
                  ),
                ],
              ),
            ),
          ),

          if (_tempDateRange != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _tempDateRange = null;
                });
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear date range'),
            ),
          ],

          const SizedBox(height: 30),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _tempPaymentFilter = 'All';
                      _tempStatusFilter = 'All';
                      _tempDateRange = null;
                    });
                  },
                  child: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onFiltersChanged(
                      _tempPaymentFilter,
                      _tempStatusFilter,
                      _tempDateRange,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

// Order status dialog (same as before)
class _OrderStatusDialog extends StatefulWidget {
  final QueryDocumentSnapshot order;
  final OrderService orderService;
  final VoidCallback onStatusUpdated;

  const _OrderStatusDialog({
    required this.order,
    required this.orderService,
    required this.onStatusUpdated,
  });

  @override
  State<_OrderStatusDialog> createState() => _OrderStatusDialogState();
}

class _OrderStatusDialogState extends State<_OrderStatusDialog> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.order.data() as Map<String, dynamic>;
    final orderStatus = data['orderStatus'] ?? 'Unknown';
    final paymentStatus = data['paymentStatus'] ?? 'Unknown';
    final orderId = data['orderId'] ?? 'N/A';

    final statusSteps = [
      'Processing',
      'Shipped',
      'Out for Delivery',
      'Delivered',
    ];
    final currentStepIndex = statusSteps.indexOf(orderStatus);
    final nextStatus =
        currentStepIndex >= 0 && currentStepIndex < statusSteps.length - 1
            ? statusSteps[currentStepIndex + 1]
            : null;

    return AlertDialog(
      title: const Text('Update Order Status'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order ID: $orderId'),
          const SizedBox(height: 8),
          Text('Current Status: $orderStatus'),
          Text('Payment Status: $paymentStatus'),

          if (nextStatus != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Next Action',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This will advance the order status from "$orderStatus" to "$nextStatus".',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Make sure the order is ready for the next stage before proceeding.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'This order cannot be advanced further.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isUpdating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (nextStatus != null)
          ElevatedButton(
            onPressed:
                _isUpdating ? null : () => _updateOrderStatus(nextStatus),
            child:
                _isUpdating
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text('Update to $nextStatus'),
          ),
      ],
    );
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await widget.orderService.updateOrderStatus(widget.order.id, newStatus);

      if (mounted) {
        Navigator.pop(context);
        widget.onStatusUpdated();

        showSnackBar(
          context,
          'Order status updated to $newStatus',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });

        showSnackBar(
          context,
          'Failed to update order status: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    }
  }
}
