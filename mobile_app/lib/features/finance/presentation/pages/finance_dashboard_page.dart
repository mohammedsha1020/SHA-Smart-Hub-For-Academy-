import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/models/fee.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class FinanceDashboardPage extends ConsumerStatefulWidget {
  const FinanceDashboardPage({Key? key}) : super(key: key);

  @override
  ConsumerState<FinanceDashboardPage> createState() => _FinanceDashboardPageState();
}

class _FinanceDashboardPageState extends ConsumerState<FinanceDashboardPage> {
  bool _isLoading = true;
  
  // Mock data - in real app, this would come from the provider
  final Map<String, dynamic> _dashboardData = {
    'totalAmount': 150000.0,
    'totalPaid': 120000.0,
    'totalPending': 30000.0,
    'overdueAmount': 15000.0,
  };

  final List<Fee> _recentFees = [
    // Mock fee data
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Dashboard'),
        actions: [
          if (user?.role == 'finance' || user?.role == 'admin')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                // Navigate to create fee page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Create fee feature coming soon')),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadDashboardData(),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Finance overview cards
                    _buildFinanceOverview(),
                    
                    SizedBox(height: 24.h),
                    
                    // Quick actions
                    _buildQuickActions(user),
                    
                    SizedBox(height: 24.h),
                    
                    // Recent fees
                    _buildRecentFees(),
                    
                    SizedBox(height: 24.h),
                    
                    // Fee status chart
                    _buildFeeStatusChart(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFinanceOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Overview',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                title: 'Total Fees',
                amount: _dashboardData['totalAmount'],
                color: AppTheme.infoColor,
                icon: Icons.account_balance_wallet,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildOverviewCard(
                title: 'Collected',
                amount: _dashboardData['totalPaid'],
                color: AppTheme.paidColor,
                icon: Icons.check_circle,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                title: 'Pending',
                amount: _dashboardData['totalPending'],
                color: AppTheme.pendingColor,
                icon: Icons.pending,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildOverviewCard(
                title: 'Overdue',
                amount: _dashboardData['overdueAmount'],
                color: AppTheme.overdueColor,
                icon: Icons.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20.sp,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.trending_up,
                  color: Colors.green,
                  size: 16.sp,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(user) {
    final actions = <Map<String, dynamic>>[];
    
    if (user?.role == 'finance' || user?.role == 'admin') {
      actions.addAll([
        {
          'title': 'Collect Payment',
          'icon': Icons.payment,
          'color': AppTheme.successColor,
          'onTap': () => _collectPayment(),
        },
        {
          'title': 'View Reports',
          'icon': Icons.assessment,
          'color': AppTheme.infoColor,
          'onTap': () => _viewReports(),
        },
        {
          'title': 'Send Reminders',
          'icon': Icons.notification_important,
          'color': AppTheme.warningColor,
          'onTap': () => _sendReminders(),
        },
        {
          'title': 'Export Data',
          'icon': Icons.download,
          'color': AppTheme.primaryColor,
          'onTap': () => _exportData(),
        },
      ]);
    } else {
      actions.addAll([
        {
          'title': 'Pay Fees',
          'icon': Icons.payment,
          'color': AppTheme.successColor,
          'onTap': () => _payFees(),
        },
        {
          'title': 'Payment History',
          'icon': Icons.history,
          'color': AppTheme.infoColor,
          'onTap': () => _viewPaymentHistory(),
        },
        {
          'title': 'Download Receipt',
          'icon': Icons.receipt,
          'color': AppTheme.primaryColor,
          'onTap': () => _downloadReceipt(),
        },
        {
          'title': 'Fee Structure',
          'icon': Icons.info,
          'color': AppTheme.warningColor,
          'onTap': () => _viewFeeStructure(),
        },
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: 16.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return Card(
              child: InkWell(
                onTap: action['onTap'],
                borderRadius: BorderRadius.circular(12.r),
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: action['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          action['icon'],
                          color: action['color'],
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          action['title'],
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentFees() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Fees',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            TextButton(
              onPressed: () {
                // Navigate to all fees
              },
              child: const Text('View All'),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        // Mock fee items
        ...List.generate(3, (index) => _buildFeeItem(index)),
      ],
    );
  }

  Widget _buildFeeItem(int index) {
    final statuses = ['paid', 'pending', 'overdue'];
    final amounts = [5000.0, 3000.0, 2000.0];
    final students = ['John Doe', 'Jane Smith', 'Mike Johnson'];
    
    final status = statuses[index];
    final amount = amounts[index];
    final student = students[index];
    
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppTheme.getFeeStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            status == 'paid' ? Icons.check_circle : 
            status == 'pending' ? Icons.pending : Icons.warning,
            color: AppTheme.getFeeStatusColor(status),
          ),
        ),
        title: Text(student),
        subtitle: Text('Tuition Fee - Term 1'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹$amount',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.getFeeStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getFeeStatusColor(status),
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          // Navigate to fee details
        },
      ),
    );
  }

  Widget _buildFeeStatusChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fee Status Distribution',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: 16.h),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                _buildStatusRow('Paid', 65, AppTheme.paidColor),
                SizedBox(height: 8.h),
                _buildStatusRow('Pending', 25, AppTheme.pendingColor),
                SizedBox(height: 8.h),
                _buildStatusRow('Overdue', 10, AppTheme.overdueColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, int percentage, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 60.w,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          '$percentage%',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Action methods
  void _collectPayment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Collect payment feature coming soon')),
    );
  }

  void _viewReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reports feature coming soon')),
    );
  }

  void _sendReminders() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Send reminders feature coming soon')),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export data feature coming soon')),
    );
  }

  void _payFees() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pay fees feature coming soon')),
    );
  }

  void _viewPaymentHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment history feature coming soon')),
    );
  }

  void _downloadReceipt() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download receipt feature coming soon')),
    );
  }

  void _viewFeeStructure() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fee structure feature coming soon')),
    );
  }
}
