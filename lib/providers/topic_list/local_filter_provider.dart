// ignore: depend_on_referenced_packages
import 'package:flutter_riverpod/legacy.dart';
import '../../models/topic.dart';

/// 本地话题过滤条件
class LocalTopicFilter {
  /// 标题/摘要关键字（空字符串表示不过滤）
  final String keyword;

  /// 信任等级白名单（空集合表示不过滤）
  /// Linux.do 对应 trust_level: 0=新用户, 1=基本, 2=成员, 3=活跃, 4=领导者
  final Set<int> trustLevels;

  /// 分类 ID 白名单（空集合表示不过滤）
  final Set<String> categoryIds;

  /// 标签白名单（空集合表示不过滤）
  final Set<String> tags;

  const LocalTopicFilter({
    this.keyword = '',
    this.trustLevels = const {},
    this.categoryIds = const {},
    this.tags = const {},
  });

  /// 是否无任何过滤条件
  bool get isEmpty =>
      keyword.isEmpty &&
      trustLevels.isEmpty &&
      categoryIds.isEmpty &&
      tags.isEmpty;

  /// 对单个话题进行匹配，返回 true 表示通过过滤
  bool matches(Topic topic) {
    // 关键字过滤（标题 + 摘要）
    if (keyword.isNotEmpty) {
      final kw = keyword.toLowerCase();
      final titleMatch = topic.title.toLowerCase().contains(kw);
      final excerptMatch =
          topic.excerpt?.toLowerCase().contains(kw) ?? false;
      if (!titleMatch && !excerptMatch) return false;
    }

    // 分类 ID 过滤
    if (categoryIds.isNotEmpty) {
      if (!categoryIds.contains(topic.categoryId)) return false;
    }

    // 标签过滤（话题至少包含其中一个选中标签）
    if (tags.isNotEmpty) {
      final topicTagNames = topic.tags.map((t) => t.name).toSet();
      if (tags.intersection(topicTagNames).isEmpty) return false;
    }

    return true;
  }

  LocalTopicFilter copyWith({
    String? keyword,
    Set<int>? trustLevels,
    Set<String>? categoryIds,
    Set<String>? tags,
  }) {
    return LocalTopicFilter(
      keyword: keyword ?? this.keyword,
      trustLevels: trustLevels ?? this.trustLevels,
      categoryIds: categoryIds ?? this.categoryIds,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalTopicFilter &&
          keyword == other.keyword &&
          _setEquals(trustLevels, other.trustLevels) &&
          _setEquals(categoryIds, other.categoryIds) &&
          _setEquals(tags, other.tags);

  @override
  int get hashCode =>
      Object.hash(keyword, Object.hashAll(trustLevels), Object.hashAll(categoryIds), Object.hashAll(tags));

  static bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}

/// 本地过滤条件 Notifier
class LocalTopicFilterNotifier extends StateNotifier<LocalTopicFilter> {
  LocalTopicFilterNotifier() : super(const LocalTopicFilter());

  void setKeyword(String keyword) {
    state = state.copyWith(keyword: keyword.trim());
  }

  void toggleTrustLevel(int level) {
    final current = Set<int>.from(state.trustLevels);
    if (current.contains(level)) {
      current.remove(level);
    } else {
      current.add(level);
    }
    state = state.copyWith(trustLevels: current);
  }

  void toggleCategory(String categoryId) {
    final current = Set<String>.from(state.categoryIds);
    if (current.contains(categoryId)) {
      current.remove(categoryId);
    } else {
      current.add(categoryId);
    }
    state = state.copyWith(categoryIds: current);
  }

  void toggleTag(String tag) {
    final current = Set<String>.from(state.tags);
    if (current.contains(tag)) {
      current.remove(tag);
    } else {
      current.add(tag);
    }
    state = state.copyWith(tags: current);
  }

  void reset() {
    state = const LocalTopicFilter();
  }
}

/// 当前本地过滤条件（全局单例，跨 Tab 共享）
final localTopicFilterProvider =
    StateNotifierProvider<LocalTopicFilterNotifier, LocalTopicFilter>(
  (_) => LocalTopicFilterNotifier(),
);
