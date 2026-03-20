import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/category.dart';
import '../../providers/topic_list/local_filter_provider.dart';

/// 本地话题过滤面板（BottomSheet）
/// 支持：关键字搜索、等级筛选、分类筛选、标签筛选
class LocalFilterSheet extends ConsumerStatefulWidget {
  const LocalFilterSheet({
    super.key,
    required this.categories,
    required this.availableTags,
  });

  final List<Category> categories;
  final List<String> availableTags;

  @override
  ConsumerState<LocalFilterSheet> createState() => _LocalFilterSheetState();
}

class _LocalFilterSheetState extends ConsumerState<LocalFilterSheet> {
  late TextEditingController _keywordController;

  // Linux.do 信任等级标签
  static const _trustLevelLabels = {
    0: '0 新用户',
    1: '1 基本',
    2: '2 成员',
    3: '3 活跃',
    4: '4 领导者',
  };

  @override
  void initState() {
    super.initState();
    final filter = ref.read(localTopicFilterProvider);
    _keywordController = TextEditingController(text: filter.keyword);
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(localTopicFilterProvider);
    final notifier = ref.read(localTopicFilterProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // 把手
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题行
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text('过滤话题', style: textTheme.titleMedium),
                    const Spacer(),
                    if (!filter.isEmpty)
                      TextButton(
                        onPressed: () {
                          notifier.reset();
                          _keywordController.clear();
                        },
                        child: const Text('重置'),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 内容区
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── 关键字 ──
                    Text('关键字', style: textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _keywordController,
                      decoration: InputDecoration(
                        hintText: '标题或摘要关键字',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _keywordController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _keywordController.clear();
                                  notifier.setKeyword('');
                                },
                              )
                            : null,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      onChanged: notifier.setKeyword,
                    ),
                    const SizedBox(height: 20),

                    // ── 信任等级 ──
                    Text('信任等级', style: textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _trustLevelLabels.entries.map((entry) {
                        final selected =
                            filter.trustLevels.contains(entry.key);
                        return FilterChip(
                          label: Text(entry.value),
                          selected: selected,
                          onSelected: (_) =>
                              notifier.toggleTrustLevel(entry.key),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // ── 分类 ──
                    if (widget.categories.isNotEmpty) ...[
                      Text('分类', style: textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: widget.categories.map((cat) {
                          final catIdStr = cat.id.toString();
                          final selected =
                              filter.categoryIds.contains(catIdStr);
                          return FilterChip(
                            avatar: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Color(
                                  int.parse('FF${cat.color}',
                                      radix: 16),
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            label: Text(cat.name),
                            selected: selected,
                            onSelected: (_) =>
                                notifier.toggleCategory(catIdStr),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── 标签 ──
                    if (widget.availableTags.isNotEmpty) ...[
                      Text('标签', style: textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: widget.availableTags.map((tag) {
                          final selected = filter.tags.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: selected,
                            onSelected: (_) => notifier.toggleTag(tag),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 显示过滤面板
void showLocalFilterSheet(
  BuildContext context, {
  required List<Category> categories,
  required List<String> availableTags,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LocalFilterSheet(
      categories: categories,
      availableTags: availableTags,
    ),
  );
}
