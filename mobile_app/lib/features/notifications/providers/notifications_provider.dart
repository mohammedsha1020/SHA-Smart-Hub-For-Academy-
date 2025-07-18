import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/api_response.dart';

// Notification data models
class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime? readAt;
  final String createdBy;
  final Map<String, dynamic>? metadata;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.readAt,
    required this.createdBy,
    this.metadata,
  });

  bool get isRead => status == 'read';
  bool get isUnread => status == 'unread';
  bool get isHighPriority => priority == 'high' || priority == 'urgent';

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'unread',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      createdBy: json['createdBy']?['firstName'] ?? json['createdBy'] ?? '',
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'createdBy': createdBy,
      'metadata': metadata,
    };
  }
}

class NotificationStats {
  final int totalNotifications;
  final int unreadCount;
  final int readCount;
  final int archivedCount;
  final Map<String, int> typeBreakdown;
  final Map<String, int> priorityBreakdown;

  NotificationStats({
    required this.totalNotifications,
    required this.unreadCount,
    required this.readCount,
    required this.archivedCount,
    required this.typeBreakdown,
    required this.priorityBreakdown,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      totalNotifications: json['totalNotifications'] ?? 0,
      unreadCount: json['unreadCount'] ?? 0,
      readCount: json['readCount'] ?? 0,
      archivedCount: json['archivedCount'] ?? 0,
      typeBreakdown: Map<String, int>.from(json['typeBreakdown'] ?? {}),
      priorityBreakdown: Map<String, int>.from(json['priorityBreakdown'] ?? {}),
    );
  }
}

// Notification state classes
class NotificationsState {
  final bool isLoading;
  final List<AppNotification> notifications;
  final NotificationStats? stats;
  final String? error;
  final String? typeFilter;
  final String? priorityFilter;
  final String? statusFilter;
  final int currentPage;
  final bool hasMorePages;

  NotificationsState({
    this.isLoading = false,
    this.notifications = const [],
    this.stats,
    this.error,
    this.typeFilter,
    this.priorityFilter,
    this.statusFilter,
    this.currentPage = 1,
    this.hasMorePages = true,
  });

  NotificationsState copyWith({
    bool? isLoading,
    List<AppNotification>? notifications,
    NotificationStats? stats,
    String? error,
    String? typeFilter,
    String? priorityFilter,
    String? statusFilter,
    int? currentPage,
    bool? hasMorePages,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      stats: stats ?? this.stats,
      error: error,
      typeFilter: typeFilter ?? this.typeFilter,
      priorityFilter: priorityFilter ?? this.priorityFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      currentPage: currentPage ?? this.currentPage,
      hasMorePages: hasMorePages ?? this.hasMorePages,
    );
  }

  List<AppNotification> get filteredNotifications {
    var filtered = notifications;

    if (typeFilter != null && typeFilter!.isNotEmpty) {
      filtered = filtered.where((n) => n.type == typeFilter).toList();
    }

    if (priorityFilter != null && priorityFilter!.isNotEmpty) {
      filtered = filtered.where((n) => n.priority == priorityFilter).toList();
    }

    if (statusFilter != null && statusFilter!.isNotEmpty) {
      filtered = filtered.where((n) => n.status == statusFilter).toList();
    }

    return filtered;
  }

  List<AppNotification> get unreadNotifications {
    return notifications.where((n) => n.isUnread).toList();
  }

  List<AppNotification> get highPriorityNotifications {
    return notifications.where((n) => n.isHighPriority).toList();
  }
}

// Notifications provider
class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final ApiService _apiService;

  NotificationsNotifier(this._apiService) : super(NotificationsState());

  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        notifications: [],
        currentPage: 1,
        hasMorePages: true,
      );
    }

    if (state.isLoading || !state.hasMorePages) return;

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final queryParams = <String, String>{
        'page': state.currentPage.toString(),
        'limit': '20',
      };

      if (state.typeFilter != null) queryParams['type'] = state.typeFilter!;
      if (state.priorityFilter != null) queryParams['priority'] = state.priorityFilter!;
      if (state.statusFilter != null) queryParams['isRead'] = state.statusFilter == 'read' ? 'true' : 'false';

      final response = await _apiService.get('/notifications', queryParams: queryParams);
      if (response.isSuccess && response.data != null) {
        final List<dynamic> notificationsJson = response.data!['notifications'] ?? [];
        final newNotifications = notificationsJson.map((n) => AppNotification.fromJson(n)).toList();
        
        final currentNotifications = refresh ? <AppNotification>[] : state.notifications;
        final updatedNotifications = [...currentNotifications, ...newNotifications];
        
        final totalPages = response.data!['totalPages'] ?? 1;
        final hasMore = state.currentPage < totalPages;

        state = state.copyWith(
          isLoading: false,
          notifications: updatedNotifications,
          currentPage: state.currentPage + 1,
          hasMorePages: hasMore,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message ?? 'Failed to load notifications',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notifications: $e',
      );
    }
  }

  Future<void> loadStats() async {
    try {
      final response = await _apiService.get('/notifications/stats');
      if (response.isSuccess && response.data != null) {
        final stats = NotificationStats.fromJson(response.data!);
        state = state.copyWith(stats: stats);
      }
    } catch (e) {
      print('Failed to load notification stats: $e');
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _apiService.patch('/notifications/$notificationId/read');
      
      if (response.isSuccess) {
        // Update local state
        final updatedNotifications = state.notifications.map((notification) {
          if (notification.id == notificationId) {
            return AppNotification.fromJson({
              ...notification.toJson(),
              'status': 'read',
              'readAt': DateTime.now().toIso8601String(),
            });
          }
          return notification;
        }).toList();
        
        state = state.copyWith(notifications: updatedNotifications);
        await loadStats();
        return true;
      } else {
        state = state.copyWith(error: response.message ?? 'Failed to mark notification as read');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiService.patch('/notifications/mark-all/read');
      
      if (response.isSuccess) {
        // Update local state - mark all as read
        final updatedNotifications = state.notifications.map((notification) {
          if (notification.isUnread) {
            return AppNotification.fromJson({
              ...notification.toJson(),
              'status': 'read',
              'readAt': DateTime.now().toIso8601String(),
            });
          }
          return notification;
        }).toList();
        
        state = state.copyWith(notifications: updatedNotifications);
        await loadStats();
        return true;
      } else {
        state = state.copyWith(error: response.message ?? 'Failed to mark all notifications as read');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark all notifications as read: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await _apiService.delete('/notifications/$notificationId');
      
      if (response.isSuccess) {
        // Remove from local state
        final updatedNotifications = state.notifications.where((n) => n.id != notificationId).toList();
        state = state.copyWith(notifications: updatedNotifications);
        await loadStats();
        return true;
      } else {
        state = state.copyWith(error: response.message ?? 'Failed to delete notification');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete notification: $e');
      return false;
    }
  }

  void setTypeFilter(String? type) {
    state = state.copyWith(
      typeFilter: type,
      notifications: [],
      currentPage: 1,
      hasMorePages: true,
    );
    loadNotifications();
  }

  void setPriorityFilter(String? priority) {
    state = state.copyWith(
      priorityFilter: priority,
      notifications: [],
      currentPage: 1,
      hasMorePages: true,
    );
    loadNotifications();
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(
      statusFilter: status,
      notifications: [],
      currentPage: 1,
      hasMorePages: true,
    );
    loadNotifications();
  }

  void clearFilters() {
    state = state.copyWith(
      typeFilter: null,
      priorityFilter: null,
      statusFilter: null,
      notifications: [],
      currentPage: 1,
      hasMorePages: true,
    );
    loadNotifications();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void refresh() {
    loadNotifications(refresh: true);
    loadStats();
  }
}

// Provider instances
final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return NotificationsNotifier(apiService);
});

// Computed providers
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationsState = ref.watch(notificationsProvider);
  return notificationsState.unreadNotifications.length;
});

final highPriorityNotificationsProvider = Provider<List<AppNotification>>((ref) {
  final notificationsState = ref.watch(notificationsProvider);
  return notificationsState.highPriorityNotifications;
});

final notificationsByTypeProvider = Provider<Map<String, List<AppNotification>>>((ref) {
  final notificationsState = ref.watch(notificationsProvider);
  final Map<String, List<AppNotification>> byType = {};
  
  for (final notification in notificationsState.notifications) {
    if (!byType.containsKey(notification.type)) {
      byType[notification.type] = [];
    }
    byType[notification.type]!.add(notification);
  }
  
  return byType;
});

final recentNotificationsProvider = Provider<List<AppNotification>>((ref) {
  final notificationsState = ref.watch(notificationsProvider);
  final notifications = [...notificationsState.notifications];
  notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return notifications.take(5).toList();
});
