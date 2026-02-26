import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/notification.dart';
import '../providers/discourse_providers.dart';

import 'topic_detail_page/topic_detail_page.dart';
import 'user_profile_page.dart';
import 'badge_page.dart';
import '../widgets/common/emoji_text.dart';
import '../widgets/common/smart_avatar.dart';
import '../widgets/notification/notification_list_skeleton.dart';
import '../widgets/common/error_view.dart';
import '../widgets/common/relative_time_text.dart';
import '../constants.dart';

// discourse-follow 插件的自定义 SVG 图标
const _followNewFollowerSvg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 33 30">'
    '<path d="M23.1 29.2h1.5c.8 0 1.5-.7 1.5-1.5v-5.3h5.1c.8 0 1.5-.7 1.5-1.5v-1.5c0-.8-.7-1.5-1.5-1.5h-5.1v-5c0-.8-.7-1.5-1.5-1.5h-1.5c-.8 0-1.5.7-1.5 1.5v5h-4.7c-.8 0-1.5.7-1.5 1.5v1.5c0 .8.7 1.5 1.5 1.5h4.7v5.3c0 .8.6 1.5 1.5 1.5zM18.4 29.1v-3.9c0-.1-.1-.1-.1-.1h-2.5c-2.7 0-3.7-2.1-3.7-4V18c0-.2-.2-.2-.2-.2-1.3 0-2.6-.4-4-1h-.5c-4.1 0-7.4 3.3-7.4 7.4v1.9c0 1.7 1.4 3.1 3.1 3.1h15.2c0 .1.1 0 .1-.1z"/>'
    '<circle cx="12.5" cy="7.1" r="7.1"/>'
    '</svg>';

const _followNewTopicSvg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 33 30">'
    '<path d="M32.6 21.6c-.6-.7-1.8-1.7-1.8-5 0-2.4-1.6-4.3-3.8-4.9-.3-1.6-2.4-1.6-2.7 0-2.2.6-3.9 2.5-3.9 4.9 0 3.3-1.2 4.3-1.8 5-.2.2-.3.5-.3.7 0 .5.4 1 1 1h12.5c.9 0 1.4-1.1.8-1.7zM20.1 29.2h-17c-1.7 0-3.1-1.4-3.1-3.1v-1.9c0-4.3 3.7-7.7 8-7.4 2.6 1.3 6 1.4 8.6.1 0 0 .1-.1.1 0 0 2.4-.5 2.8-1.2 3.5-2 2.1-.7 5.9 2.4 5.7h.8c.1 0 .1.3.1.4.1 1.1.6 1.8 1.3 2.7M25.6 29.2c1.7 0 3-1.3 3-2.9h-6c0 1.5 1.3 2.9 3 2.9zM12.3 14.2c3.9 0 7.1-3.2 7.1-7.1-.3-9.5-14-9.5-14.3 0 0 3.9 3.2 7.1 7.2 7.1z"/>'
    '</svg>';

const _followNewReplySvg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 33 30">'
    '<path d="M15.2 29.3H3.1c-1.7 0-3.1-1.4-3.1-3.1v-1.8C0 20.3 3.3 17 7.4 17h.5c1.3.6 2.8 1 4.4 1 .2 0 .6 0 1.2-.2 0 0 .3 0 .1.3-.8 1.5-1.1 3.2-1.1 4.8 0 2.5 1 4.7 2.7 6.3 0 0 .2.1 0 .1zM12.3 14.3c4 0 7.2-3.2 7.2-7.2S16.3 0 12.3 0 5.1 3.2 5.1 7.2s3.2 7.1 7.2 7.1zM32.4 17.1 26 11.6c-.6-.5-1.5-.1-1.5.7V15.1c-4.8.5-8.4 2.2-8.4 7.6 0 2.6 1.5 5.1 3.2 6.4.5.4 1.3-.1 1.1-.8-1.4-5 .1-7 4.1-7.5v2.4c0 .7.9 1.1 1.5.7l6.4-5.5c.4-.3.4-1 0-1.3z"/>'
    '</svg>';

/// 通知列表页面
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationListProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(notificationListProvider.notifier).refresh();
  }

  void _onNotificationTap(DiscourseNotification notification) async {
    // 如果通知未读，先标记为已读
    if (!notification.read) {
      // 立即更新本地状态，让 UI 显示为已读
      ref.read(notificationListProvider.notifier).markAsRead(notification.id);

      // 异步发送标记已读请求（不等待结果）
      ref.read(discourseServiceProvider).markNotificationRead(notification.id).catchError((e) {
        debugPrint('标记通知已读失败: $e');
      });
    }

    // 根据通知类型决定跳转逻辑
    if (!mounted) return;

    switch (notification.notificationType) {
      case NotificationType.inviteeAccepted:
      case NotificationType.following:
        // 跳转到用户页
        if (notification.username != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserProfilePage(username: notification.username!),
            ),
          );
        }
        break;

      case NotificationType.grantedBadge:
        // 跳转到徽章页面
        if (notification.data.badgeId != null) {
          final currentUser = ref.read(currentUserProvider).value;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BadgePage(
                badgeId: notification.data.badgeId!,
                badgeSlug: notification.data.badgeSlug,
                username: currentUser?.username,
              ),
            ),
          );
        }
        break;

      case NotificationType.membershipRequestAccepted:
        // 群组通知暂时不跳转（需要群组页面）
        break;

      default:
        // 大部分通知：如果有 topicId，跳转到话题详情
        if (notification.topicId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TopicDetailPage(
                topicId: notification.topicId!,
                scrollToPostNumber: notification.postNumber,
              ),
            ),
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationListProvider);
    final systemAvatarTemplate = ref.watch(systemUserAvatarTemplateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () => ref.read(notificationListProvider.notifier).markAllAsRead(),
            tooltip: '全部标为已读',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('暂无通知', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              itemCount: notifications.length + 1,
              itemBuilder: (context, index) {
                if (index == notifications.length) {
                  final hasMore = ref.read(notificationListProvider.notifier).hasMore;
                  if (!hasMore) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text('没有更多了', style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }
                  if (notificationsAsync.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return const SizedBox();
                }
                final notification = notifications[index];
                return _NotificationItem(
                  notification: notification,
                  systemAvatarTemplate: systemAvatarTemplate,
                  onTap: () => _onNotificationTap(notification),
                );
              },
            );
          },
          loading: () => const NotificationListSkeleton(),
          error: (error, stack) => ErrorView(
            error: error,
            stackTrace: stack,
            onRetry: _onRefresh,
          ),
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final DiscourseNotification notification;
  final String? systemAvatarTemplate;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    this.systemAvatarTemplate,
    required this.onTap,
  });

  IconData _getNotificationIcon() {
    switch (notification.notificationType) {
      case NotificationType.mentioned:
        return Icons.alternate_email;
      case NotificationType.replied:
        return Icons.reply;
      case NotificationType.quoted:
        return Icons.format_quote;
      case NotificationType.liked:
      case NotificationType.likedConsolidated:
        return Icons.favorite;
      case NotificationType.reaction:
        return Icons.thumb_up; // 或者使用具体的 reaction 图标如果数据支持
      case NotificationType.privateMessage:
      case NotificationType.invitedToPrivateMessage:
        return Icons.mail;
      case NotificationType.posted:
        return Icons.post_add;
      case NotificationType.grantedBadge:
        return Icons.military_tech;
      case NotificationType.linked:
        return Icons.link;
      case NotificationType.bookmarkReminder:
        return Icons.bookmark;
      case NotificationType.groupMentioned:
        return Icons.group;
      case NotificationType.watchingFirstPost:
        return Icons.visibility;
      case NotificationType.following:
      case NotificationType.followingCreatedTopic:
      case NotificationType.followingReplied:
        return Icons.person_add; // follow 类型使用 SVG 图标，此处不会被调用
      case NotificationType.watchingCategoryOrTag:
        return Icons.label;
      case NotificationType.newFeatures:
        return Icons.new_releases;
      case NotificationType.adminProblems:
        return Icons.warning;
      case NotificationType.linkedConsolidated:
        return Icons.link;
      case NotificationType.chatWatchedThread:
        return Icons.chat_bubble;
      case NotificationType.invitedToTopic:
        return Icons.mail_outline;
      case NotificationType.inviteeAccepted:
        return Icons.check_circle;
      case NotificationType.movedPost:
        return Icons.drive_file_move;
      case NotificationType.topicReminder:
        return Icons.alarm;
      case NotificationType.eventReminder:
      case NotificationType.eventInvitation:
        return Icons.event;
      case NotificationType.chatMention:
      case NotificationType.chatMessage:
      case NotificationType.chatInvitation:
      case NotificationType.chatGroupMention:
      case NotificationType.chatQuotedPost:
        return Icons.chat;
      case NotificationType.assignedTopic:
        return Icons.assignment;
      case NotificationType.questionAnswerUserCommented:
        return Icons.question_answer;
      case NotificationType.circlesActivity:
        return Icons.groups;
      default:
        return Icons.notifications;
    }
  }

  /// 获取头像 URL，无 acting_user 时使用系统用户头像
  String? _getAvatarUrl() {
    final url = notification.getAvatarUrl();
    if (url.isNotEmpty) return url;
    // 使用系统用户头像作为 fallback
    if (systemAvatarTemplate != null && systemAvatarTemplate!.isNotEmpty) {
      final template = systemAvatarTemplate!;
      if (template.startsWith('http')) return template;
      return '${AppConstants.baseUrl}$template';
    }
    return null;
  }

  /// 构建角标图标，follow 类型使用 SVG，其他使用 Material Icon
  Widget _buildBadgeIcon(Color color) {
    String? svgData;
    switch (notification.notificationType) {
      case NotificationType.following:
        svgData = _followNewFollowerSvg;
        break;
      case NotificationType.followingCreatedTopic:
        svgData = _followNewTopicSvg;
        break;
      case NotificationType.followingReplied:
        svgData = _followNewReplySvg;
        break;
      default:
        break;
    }
    if (svgData != null) {
      return SvgPicture.string(
        svgData,
        width: 14,
        height: 14,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    return Icon(
      _getNotificationIcon(),
      size: 14,
      color: color,
    );
  }

  Color _getNotificationColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (notification.notificationType) {
      case NotificationType.liked:
      case NotificationType.likedConsolidated:
      case NotificationType.reaction:
        return Colors.red;
      case NotificationType.privateMessage:
      case NotificationType.invitedToPrivateMessage:
        return Colors.blue;
      case NotificationType.grantedBadge:
        return Colors.amber;
      case NotificationType.mentioned:
      case NotificationType.groupMentioned:
        return colorScheme.primary;
      case NotificationType.following:
        return Colors.green;
      case NotificationType.adminProblems:
        return Colors.red;
      case NotificationType.newFeatures:
        return Colors.purple;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }



  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = _getNotificationColor(context);
    final titleStyle = TextStyle(
      fontWeight: notification.read ? FontWeight.normal : FontWeight.w600,
    );

    return ListTile(
      leading: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 底层：用户头像（无头像时使用系统用户头像）
            Align(
              alignment: Alignment.center,
              child: SmartAvatar(
                imageUrl: _getAvatarUrl(),
                radius: 20,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
            // 右上角：通知类型图标
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: notification.read
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.surface,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: _buildBadgeIcon(
                  notification.read ? colorScheme.onSurfaceVariant : iconColor,
                ),
              ),
            ),
          ],
        ),
      ),
      title: Text.rich(
        TextSpan(
          children: EmojiText.buildEmojiSpans(
            context,
            notification.title,
            titleStyle,
          ),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: titleStyle,
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              notification.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          RelativeTimeText(
            dateTime: notification.createdAt,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
      onTap: onTap,
      // 未读通知显示圆点标记
      trailing: !notification.read
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }

}
