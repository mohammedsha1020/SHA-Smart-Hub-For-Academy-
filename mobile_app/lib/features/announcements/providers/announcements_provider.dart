import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/api_response.dart';

// Announcement data models
class Announcement {
  final String id;
  final String title;
  final String content;
  final String type;
  final String priority;
  final String status;
  final List<String> targetAudience;
  final DateTime publishDate;
  final DateTime? expiryDate;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final List<String>? attachments;
  final Map<String, dynamic>? metadata;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.priority,
    required this.status,
    required this.targetAudience,
    required this.publishDate,
    this.expiryDate,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.attachments,
    this.metadata,
  });

  bool get isActive => status == 'published' && 
      (expiryDate == null || expiryDate!.isAfter(DateTime.now()));
  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());
  bool get isHighPriority => priority == 'high' || priority == 'urgent';

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? '',
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'draft',
      targetAudience: List<String>.from(json['targetAudience'] ?? []),
      publishDate: DateTime.parse(json['publishDate'] ?? DateTime.now().toIso8601String()),
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      createdBy: json['createdBy']?['_id'] ?? json['createdBy'] ?? '',
      createdByName: json['createdBy'] is Map 
          ? '${json['createdBy']['firstName'] ?? ''} ${json['createdBy']['lastName'] ?? ''}'.trim()
          : json['createdByName'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      attachments: json['attachments'] != null ? List<String>.from(json['attachments']) : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'content': content,
      'type': type,
      'priority': priority,
      'status': status,
      'targetAudience': targetAudience,
      'publishDate': publishDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt.toIso8601String(),
      'attachments': attachments,
      'metadata': metadata,
    };
  }
}

class AnnouncementStats {
  final int totalAnnouncements;
  final int publishedCount;
  final int draftCount;
  final int expiredCount;
  final Map<String, int> typeBreakdown;
  final Map<String, int> priorityBreakdown;
  final List<Announcement> recentAnnouncements;

  AnnouncementStats({
    required this.totalAnnouncements,
    required this.publishedCount,
    required this.draftCount,
    required this.expiredCount,
    required this.typeBreakdown,
    required this.priorityBreakdown,
    required this.recentAnnouncements,
  });

  factory AnnouncementStats.fromJson(Map<String, dynamic> json) {
    return AnnouncementStats(
      totalAnnouncements: json['totalAnnouncements'] ?? 0,
      publishedCount: json['publishedCount'] ?? 0,
      draftCount: json['draftCount'] ?? 0,
      expiredCount: json['expiredCount'] ?? 0,
      typeBreakdown: Map<String, int>.from(json['typeBreakdown'] ?? {}),
      priorityBreakdown: Map<String, int>.from(json['priorityBreakdown'] ?? {}),
      recentAnnouncements: (json['recentAnnouncements'] as List?)
          ?.map((a) => Announcement.fromJson(a))
          .toList() ?? [],
    );
  }
}

// Announcement state classes
class AnnouncementsState {
  final bool isLoading;
  final List<Announcement> announcements;
  final AnnouncementStats? stats;
  final String? error;
  final String? typeFilter;
  final String? priorityFilter;
  final String? statusFilter;
  final String searchQuery;

  AnnouncementsState({
    this.isLoading = false,
    this.announcements = const [],
    this.stats,
    this.error,
    this.typeFilter,
    this.priorityFilter,
    this.statusFilter,
    this.searchQuery = '',
  });

  AnnouncementsState copyWith({
    bool? isLoading,
    List<Announcement>? announcements,
    AnnouncementStats? stats,
    String? error,
    String? typeFilter,
    String? priorityFilter,
    String? statusFilter,
    String? searchQuery,
  }) {
    return AnnouncementsState(
      isLoading: isLoading ?? this.isLoading,
      announcements: announcements ?? this.announcements,
      stats: stats ?? this.stats,
      error: error,
      typeFilter: typeFilter ?? this.typeFilter,
      priorityFilter: priorityFilter ?? this.priorityFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Announcement> get filteredAnnouncements {
    var filtered = announcements;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((announcement) =>
          announcement.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          announcement.content.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }

    // Apply type filter
    if (typeFilter != null && typeFilter!.isNotEmpty) {
      filtered = filtered.where((a) => a.type == typeFilter).toList();
    }

    // Apply priority filter
    if (priorityFilter != null && priorityFilter!.isNotEmpty) {
      filtered = filtered.where((a) => a.priority == priorityFilter).toList();
    }

    // Apply status filter
    if (statusFilter != null && statusFilter!.isNotEmpty) {
      filtered = filtered.where((a) => a.status == statusFilter).toList();
    }

    return filtered;
  }

  List<Announcement> get activeAnnouncements {
    return announcements.where((a) => a.isActive).toList();
  }

  List<Announcement> get highPriorityAnnouncements {
    return announcements.where((a) => a.isHighPriority && a.isActive).toList();
  }
}

// Announcements provider
class AnnouncementsNotifier extends StateNotifier<AnnouncementsState> {
  final ApiService _apiService;

  AnnouncementsNotifier(this._apiService) : super(AnnouncementsState());

  Future<void> loadAnnouncements() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final queryParams = <String, String>{};
      if (state.typeFilter != null) queryParams['type'] = state.typeFilter!;
      if (state.priorityFilter != null) queryParams['priority'] = state.priorityFilter!;
      if (state.statusFilter != null) queryParams['status'] = state.statusFilter!;
      
      final response = await _apiService.get('/announcements', queryParams: queryParams);
      if (response.isSuccess && response.data != null) {
        final List<dynamic> announcementsJson = response.data!['announcements'] ?? [];
        final announcements = announcementsJson.map((a) => Announcement.fromJson(a)).toList();
        
        state = state.copyWith(
          isLoading: false,
          announcements: announcements,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message ?? 'Failed to load announcements',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load announcements: $e',
      );
    }
  }

  Future<void> loadStats() async {
    try {
      final response = await _apiService.get('/announcements/stats');
      if (response.isSuccess && response.data != null) {
        final stats = AnnouncementStats.fromJson(response.data!);
        state = state.copyWith(stats: stats);
      }
    } catch (e) {
      print('Failed to load announcement stats: $e');
    }
  }

  Future<bool> createAnnouncement({
    required String title,
    required String content,
    required String type,
    required String priority,
    required List<String> targetAudience,
    DateTime? publishDate,
    DateTime? expiryDate,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
    bool publish = false,
  }) async {
    try {
      final response = await _apiService.post('/announcements', data: {
        'title': title,
        'content': content,
        'type': type,
        'priority': priority,
        'targetAudience': targetAudience,
        'publishDate': (publishDate ?? DateTime.now()).toIso8601String(),
        'expiryDate': expiryDate?.toIso8601String(),
        'attachments': attachments,
        'metadata': metadata,
        'status': publish ? 'published' : 'draft',
      });
      
      if (response.isSuccess) {
        // Reload announcements to get updated data
        await loadAnnouncements();
        await loadStats();
        return true;
      } else {
        state = state.copyWith(error: response.message ?? 'Failed to create announcement');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to create announcement: $e');
      return false;
    }
  }

  Future<bool> updateAnnouncement(String announcementId, Map<String, dynamic> updates) async {
    try {
      final response = await _apiService.put('/announcements/$announcementId', data: updates);
      
      if (response.isSuccess) {
        // Update local state
        final updatedAnnouncements = state.announcements.map((announcement) {
          if (announcement.id == announcementId) {
            final updatedData = announcement.toJson()..addAll(updates);
            return Announcement.fromJson(updatedData);
          }
          return announcement;
        }).toList();
        
        state = state.copyWith(announcements: updatedAnnouncements);
        await loadStats();
        return true;
      } else {
        state = state.copyWith(error: response.message ?? 'Failed to update announcement');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to update announcement: $e');
      return false;
    }
  }

  Future<bool> publishAnnouncement(String announcementId) async {
    return updateAnnouncement(announcementId, {
      'status': 'published',
      'publishDate': DateTime.now().toIso8601String(),
    });
  }

  Future<bool> unpublishAnnouncement(String announcementId) async {
    return updateAnnouncement(announcementId, {'status': 'draft'});
  }

  Future<bool> deleteAnnouncement(String announcementId) async {
    try {
      final response = await _apiService.delete('/announcements/$announcementId');
      
      if (response.isSuccess) {
        // Remove from local state
        final updatedAnnouncements = state.announcements.where((a) => a.id != announcementId).toList();
        state = state.copyWith(announcements: updatedAnnouncements);
        await loadStats();
        return true;
      } else {
        state = state.copyWith(error: response.message ?? 'Failed to delete announcement');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete announcement: $e');
      return false;
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setTypeFilter(String? type) {
    state = state.copyWith(typeFilter: type);
    loadAnnouncements();
  }

  void setPriorityFilter(String? priority) {
    state = state.copyWith(priorityFilter: priority);
    loadAnnouncements();
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status);
    loadAnnouncements();
  }

  void clearFilters() {
    state = state.copyWith(
      typeFilter: null,
      priorityFilter: null,
      statusFilter: null,
      searchQuery: '',
    );
    loadAnnouncements();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void refresh() {
    loadAnnouncements();
    loadStats();
  }
}

// Provider instances
final announcementsProvider = StateNotifierProvider<AnnouncementsNotifier, AnnouncementsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AnnouncementsNotifier(apiService);
});

// Computed providers
final activeAnnouncementsProvider = Provider<List<Announcement>>((ref) {
  final announcementsState = ref.watch(announcementsProvider);
  return announcementsState.activeAnnouncements;
});

final highPriorityAnnouncementsProvider = Provider<List<Announcement>>((ref) {
  final announcementsState = ref.watch(announcementsProvider);
  return announcementsState.highPriorityAnnouncements;
});

final announcementsByTypeProvider = Provider<Map<String, List<Announcement>>>((ref) {
  final announcementsState = ref.watch(announcementsProvider);
  final Map<String, List<Announcement>> byType = {};
  
  for (final announcement in announcementsState.announcements) {
    if (!byType.containsKey(announcement.type)) {
      byType[announcement.type] = [];
    }
    byType[announcement.type]!.add(announcement);
  }
  
  return byType;
});

final recentAnnouncementsProvider = Provider<List<Announcement>>((ref) {
  final announcementsState = ref.watch(announcementsProvider);
  final announcements = [...announcementsState.activeAnnouncements];
  announcements.sort((a, b) => b.publishDate.compareTo(a.publishDate));
  return announcements.take(5).toList();
});
