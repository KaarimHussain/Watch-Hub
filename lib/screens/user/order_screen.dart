import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:watch_hub/services/order_service.dart';
import 'package:watch_hub/screens/user/order_details_screen.dart';
import 'package:watch_hub/components/snackbar.component.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();
  late final String? userId = FirebaseAuth.instance.currentUser?.uid;

  // Data
  List<Map<String, dynamic>> _allOrders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  bool _isLoading = true;
  String? _error;

  // Filter states
  String _selectedStatusFilter = 'All';
  String _selectedPaymentFilter = 'All';
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  String _sortBy = 'Date (Newest)';

  // Filter options
  final List<String> _statusFilters = [
    'All',
    'Processing',
    'Shipped',
    'Out for Delivery',
    'Delivered',
    'Cancelled',
  ];
  final List<String> _paymentFilters = [
    'All',
    'Paid',
    'Pending',
    'Failed',
    'Cancelled Payment',
  ];
  final List<String> _sortOptions = [
    'Date (Newest)',
    'Date (Oldest)',
    'Amount (High to Low)',
    'Amount (Low to High)',
  ];

  // Controllers
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'You need to be logged in to view your orders';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final orders = await _orderService.getUserOrders(userId!);

      setState(() {
        _allOrders = orders;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
        debugPrint(e.toString());
        _error = 'Failed to load orders: ${e.toString()}';
      });
    }
  }

  // Apply all filters and sorting
  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allOrders);

    // Apply status filter
    if (_selectedStatusFilter != 'All') {
      filtered =
          filtered.where((order) {
            return order['orderStatus'] == _selectedStatusFilter;
          }).toList();
    }

    // Apply payment filter
    if (_selectedPaymentFilter != 'All') {
      filtered =
          filtered.where((order) {
            final orderStatus = order['orderStatus'] ?? '';
            final paymentStatus = order['paymentStatus'] ?? '';
            final isCancelled = orderStatus.toLowerCase() == 'cancelled';
            final displayPaymentStatus =
                isCancelled ? 'Cancelled Payment' : paymentStatus;

            return displayPaymentStatus == _selectedPaymentFilter;
          }).toList();
    }

    // Apply date filter
    // In _applyFilters method, replace this section:
    if (_selectedDateRange != null) {
      filtered =
          filtered.where((order) {
            try {
              // Handle both Timestamp and String formats
              DateTime orderDate;
              final orderDateValue = order['orderDate'];

              if (orderDateValue is Timestamp) {
                orderDate = orderDateValue.toDate();
              } else if (orderDateValue is String) {
                orderDate = DateTime.parse(orderDateValue);
              } else {
                return false; // Skip if neither Timestamp nor String
              }

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

              return orderDate.isAfter(
                    startDate.subtract(const Duration(days: 1)),
                  ) &&
                  orderDate.isBefore(endDate.add(const Duration(days: 1)));
            } catch (e) {
              return false;
            }
          }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((order) {
            final orderId = (order['orderId'] ?? '').toLowerCase();
            final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
            final itemNames = items
                .map((item) => (item['name'] ?? '').toLowerCase())
                .join(' ');
            final query = _searchQuery.toLowerCase();

            return orderId.contains(query) || itemNames.contains(query);
          }).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'Date (Newest)':
        filtered.sort((a, b) {
          try {
            // Handle both Timestamp and String formats
            DateTime orderDate;
            final orderDateValue = a['orderDate'];

            if (orderDateValue is Timestamp) {
              orderDate = orderDateValue.toDate();
            } else if (orderDateValue is String) {
              orderDate = DateTime.parse(orderDateValue);
            } else {
              return 0; // Skip if neither Timestamp nor String
            }

            final dateA = orderDate;
            final dateB = DateTime.parse(b['orderDate']);
            return dateB.compareTo(dateA);
          } catch (e) {
            return 0;
          }
        });
        break;
      case 'Date (Oldest)':
        filtered.sort((a, b) {
          try {
            DateTime dateA, dateB;

            // Handle Timestamp for dateA
            final dateAValue = a['orderDate'];
            if (dateAValue is Timestamp) {
              dateA = dateAValue.toDate();
            } else if (dateAValue is String) {
              dateA = DateTime.parse(dateAValue);
            } else {
              return 0;
            }

            // Handle Timestamp for dateB
            final dateBValue = b['orderDate'];
            if (dateBValue is Timestamp) {
              dateB = dateBValue.toDate();
            } else if (dateBValue is String) {
              dateB = DateTime.parse(dateBValue);
            } else {
              return 0;
            }

            return dateA.compareTo(dateB);
          } catch (e) {
            return 0;
          }
        });
        break;
      case 'Amount (High to Low)':
        filtered.sort((a, b) {
          final amountA = (a['totalAmount'] ?? 0.0) as double;
          final amountB = (b['totalAmount'] ?? 0.0) as double;
          return amountB.compareTo(amountA);
        });
        break;
      case 'Amount (Low to High)':
        filtered.sort((a, b) {
          final amountA = (a['totalAmount'] ?? 0.0) as double;
          final amountB = (b['totalAmount'] ?? 0.0) as double;
          return amountA.compareTo(amountB);
        });
        break;
    }

    setState(() {
      _filteredOrders = filtered;
    });
  }

  String _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return '#FFA000'; // Amber
      case 'shipped':
        return '#2196F3'; // Blue
      case 'out for delivery':
        return '#FF9800'; // Orange
      case 'delivered':
        return '#4CAF50'; // Green
      case 'cancelled':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  // Check if order can be cancelled
  bool _canCancelOrder(String orderStatus, String paymentStatus) {
    return orderStatus.toLowerCase() == 'processing' &&
        (paymentStatus.toLowerCase() == 'pending' ||
            paymentStatus.toLowerCase() == 'paid');
  }

  // Show cancel confirmation dialog
  Future<void> _showCancelDialog(
    String orderId,
    String orderStatus,
    String paymentStatus,
  ) async {
    if (!_canCancelOrder(orderStatus, paymentStatus)) {
      showSnackBar(
        context,
        "This order cannot be cancelled",
        type: SnackBarType.error,
      );
      return;
    }

    final bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Order'),
          content: const Text(
            'Are you sure you want to cancel this order? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep Order'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancel Order'),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true) {
      await _cancelOrder(orderId);
    }
  }

  // Cancel order function
  Future<void> _cancelOrder(String orderId) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Update order status to cancelled
      await _orderService.updateOrderStatus(orderId, 'Cancelled');

      // Update payment status to cancelled
      await _orderService.updatePaymentStatus(orderId, 'Cancelled');

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Refresh orders list
      await _loadOrders();

      // Show success message
      if (mounted) {
        showSnackBar(
          context,
          "Order cancelled successfully",
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        showSnackBar(
          context,
          "Failed to cancel order: ${e.toString()}",
          type: SnackBarType.error,
        );
      }
    }
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
            ).colorScheme.copyWith(primary: Colors.black),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _applyFilters();
    }
  }

  // Clear all filters
  void _clearFilters() {
    setState(() {
      _selectedStatusFilter = 'All';
      _selectedPaymentFilter = 'All';
      _selectedDateRange = null;
      _searchQuery = '';
      _sortBy = 'Date (Newest)';
      _searchController.clear();
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(),
          ),
          IconButton(onPressed: _loadOrders, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          // Search and filter summary
          _buildSearchAndFilterSummary(theme),

          // Orders list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadOrders,
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? _buildErrorState(theme)
                      : _filteredOrders.isEmpty
                      ? _buildEmptyState(theme)
                      : _buildOrdersList(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSummary(ThemeData theme) {
    final hasActiveFilters =
        _selectedStatusFilter != 'All' ||
        _selectedPaymentFilter != 'All' ||
        _selectedDateRange != null ||
        _searchQuery.isNotEmpty ||
        _sortBy != 'Date (Newest)';

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
              hintText: 'Search by Order ID or Product Name',
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
                          _applyFilters();
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
                borderSide: const BorderSide(color: Colors.black),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();
            },
          ),

          // Results count and sort
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filteredOrders.length} ${_filteredOrders.length == 1 ? 'order' : 'orders'} found',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              DropdownButton<String>(
                value: _sortBy,
                underline: const SizedBox(),
                icon: const Icon(Icons.sort, size: 20),
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                items:
                    _sortOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _sortBy = newValue;
                    });
                    _applyFilters();
                  }
                },
              ),
            ],
          ),

          if (hasActiveFilters) ...[
            const SizedBox(height: 12),
            // Active filters summary
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_selectedStatusFilter != 'All')
                  _buildFilterChip('Status: $_selectedStatusFilter', () {
                    setState(() {
                      _selectedStatusFilter = 'All';
                    });
                    _applyFilters();
                  }),
                if (_selectedPaymentFilter != 'All')
                  _buildFilterChip('Payment: $_selectedPaymentFilter', () {
                    setState(() {
                      _selectedPaymentFilter = 'All';
                    });
                    _applyFilters();
                  }),
                if (_selectedDateRange != null)
                  _buildFilterChip(
                    'Date: ${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd').format(_selectedDateRange!.end)}',
                    () {
                      setState(() {
                        _selectedDateRange = null;
                      });
                      _applyFilters();
                    },
                  ),
                if (_sortBy != 'Date (Newest)')
                  _buildFilterChip('Sort: $_sortBy', () {
                    setState(() {
                      _sortBy = 'Date (Newest)';
                    });
                    _applyFilters();
                  }),
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
      backgroundColor: Colors.black.withOpacity(0.1),
      deleteIconColor: Colors.black,
      labelStyle: const TextStyle(color: Colors.black),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadOrders,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('TRY AGAIN'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final hasFilters =
        _selectedStatusFilter != 'All' ||
        _selectedPaymentFilter != 'All' ||
        _selectedDateRange != null ||
        _searchQuery.isNotEmpty;

    return Center(
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
            child: Icon(
              hasFilters ? Icons.search_off : Icons.shopping_bag_outlined,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            hasFilters ? 'No Orders Found' : 'No Orders Yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Try adjusting your filters to see more results'
                : 'Your order history will appear here',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (hasFilters)
            ElevatedButton(
              onPressed: _clearFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('CLEAR FILTERS'),
            )
          else
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/user_home',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('START SHOPPING'),
            ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        final orderId = order['orderId'];

        // Handle Timestamp conversion
        DateTime orderDate;
        final orderDateValue = order['orderDate'];
        if (orderDateValue is Timestamp) {
          orderDate = orderDateValue.toDate();
        } else if (orderDateValue is String) {
          orderDate = DateTime.parse(orderDateValue);
        } else {
          orderDate = DateTime.now(); // Fallback
        }

        final formattedDate = DateFormat('MMM dd, yyyy').format(orderDate);

        final orderStatus = order['orderStatus'];
        final paymentStatus = order['paymentStatus'];
        final totalAmount = order['totalAmount'];
        final items = List<Map<String, dynamic>>.from(order['items']);
        final itemCount = items.length;

        // Get the first item for display
        final firstItem = items.first;
        final firstItemImage = firstItem['imageUrl'];

        // Check if order is cancelled
        final isCancelled = orderStatus.toLowerCase() == 'cancelled';
        final displayPaymentStatus =
            isCancelled ? 'Cancelled Payment' : paymentStatus;
        final paymentStatusColor =
            isCancelled
                ? Colors.red
                : (paymentStatus == 'Paid' ? Colors.green : Colors.orange);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailsScreen(orderId: orderId),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Order #${orderId.substring(0, 8)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Order image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 70,
                          height: 70,
                          child: Image.memory(
                            base64Decode(firstItemImage),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Order details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PKR ${totalAmount.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(
                                      int.parse(
                                            _getOrderStatusColor(
                                              orderStatus,
                                            ).substring(1),
                                            radix: 16,
                                          ) |
                                          0xFF000000,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    orderStatus,
                                    style: TextStyle(
                                      color: Color(
                                        int.parse(
                                              _getOrderStatusColor(
                                                orderStatus,
                                              ).substring(1),
                                              radix: 16,
                                            ) |
                                            0xFF000000,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: paymentStatusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    displayPaymentStatus,
                                    style: TextStyle(
                                      color: paymentStatusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Cancel button or arrow icon
                      if (_canCancelOrder(orderStatus, paymentStatus))
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          child: IconButton(
                            onPressed:
                                () => _showCancelDialog(
                                  orderId,
                                  orderStatus,
                                  paymentStatus,
                                ),
                            icon: const Icon(
                              Icons.cancel_outlined,
                              color: Colors.red,
                              size: 24,
                            ),
                            tooltip: 'Cancel Order',
                          ),
                        )
                      else
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
            selectedStatusFilter: _selectedStatusFilter,
            selectedPaymentFilter: _selectedPaymentFilter,
            selectedDateRange: _selectedDateRange,
            statusFilters: _statusFilters,
            paymentFilters: _paymentFilters,
            onFiltersChanged: (statusFilter, paymentFilter, dateRange) {
              setState(() {
                _selectedStatusFilter = statusFilter;
                _selectedPaymentFilter = paymentFilter;
                _selectedDateRange = dateRange;
              });
              _applyFilters();
            },
            onDateRangeSelect: _selectDateRange,
          ),
    );
  }
}

// Filter bottom sheet widget
class _FilterBottomSheet extends StatefulWidget {
  final String selectedStatusFilter;
  final String selectedPaymentFilter;
  final DateTimeRange? selectedDateRange;
  final List<String> statusFilters;
  final List<String> paymentFilters;
  final Function(String, String, DateTimeRange?) onFiltersChanged;
  final VoidCallback onDateRangeSelect;

  const _FilterBottomSheet({
    required this.selectedStatusFilter,
    required this.selectedPaymentFilter,
    required this.selectedDateRange,
    required this.statusFilters,
    required this.paymentFilters,
    required this.onFiltersChanged,
    required this.onDateRangeSelect,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String _tempStatusFilter;
  late String _tempPaymentFilter;
  late DateTimeRange? _tempDateRange;

  @override
  void initState() {
    super.initState();
    _tempStatusFilter = widget.selectedStatusFilter;
    _tempPaymentFilter = widget.selectedPaymentFilter;
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
                    selectedColor: Colors.black.withOpacity(0.1),
                    checkmarkColor: Colors.black,
                  );
                }).toList(),
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
                    selectedColor: Colors.black.withOpacity(0.1),
                    checkmarkColor: Colors.black,
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
                      _tempStatusFilter = 'All';
                      _tempPaymentFilter = 'All';
                      _tempDateRange = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black),
                  ),
                  child: const Text(
                    'Clear All',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onFiltersChanged(
                      _tempStatusFilter,
                      _tempPaymentFilter,
                      _tempDateRange,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
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
