// lib/features/chat/presentation/widgets/chat_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/aether_card.dart';
import '../../domain/entities/chat_message.dart';
import '../bloc/chat_cubit.dart';
import '../bloc/chat_state.dart';

class ChatCard extends StatefulWidget {
  const ChatCard({super.key});

  @override
  State<ChatCard> createState() => _ChatCardState();
}

class _ChatCardState extends State<ChatCard> {
  late final TextEditingController _inputController;
  late final ScrollController _scrollController;

  // Demo identity — in production this comes from FirebaseAuth.
  static const String _demoUserId = 'demo_player';
  static const String _demoDisplayName = 'Adventurer';

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _scrollController = ScrollController();
    context.read<ChatCubit>().startWatching();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final String text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();

    await context.read<ChatCubit>().sendMessage(
          userId: _demoUserId,
          displayName: _demoDisplayName,
          message: text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return AetherCard(
      accentColor: AppTheme.accentGreen,
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.all(20),
            child: SectionHeader(
              title: 'Engagement Chat',
              subtitle: 'Raid Channel',
              accentColor: AppTheme.accentGreen,
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 280,
            child: BlocConsumer<ChatCubit, ChatState>(
              listenWhen: (ChatState previous, ChatState current) =>
                  current.messages.length != previous.messages.length,
              listener: (BuildContext context, ChatState state) {
                // Auto-scroll when new messages arrive.
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );
              },
              buildWhen: (ChatState previous, ChatState current) =>
                  previous.status != current.status ||
                  previous.messages != current.messages,
              builder: (BuildContext context, ChatState state) {
                if (state.status == ChatStatus.loading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentGreen,
                      strokeWidth: 2,
                    ),
                  );
                }

                if (state.messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Be the first to speak.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: state.messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    final ChatMessage msg = state.messages[index];
                    final bool isOwn = msg.userId == _demoUserId;
                    return _MessageBubble(message: msg, isOwn: isOwn);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          _ChatInputBar(
            controller: _inputController,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isOwn,
  });

  final ChatMessage message;
  final bool isOwn;

  @override
  Widget build(BuildContext context) {
    final String timeStr =
        DateFormat('HH:mm').format(message.timestamp.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          if (!isOwn) ...<Widget>[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.accentGreen.withValues(alpha: 0.2),
              child: Text(
                message.displayName.isNotEmpty
                    ? message.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentGreen,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isOwn
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: <Widget>[
                if (!isOwn)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 2),
                    child: Text(
                      message.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.accentGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isOwn
                        ? AppTheme.accentCyan.withValues(alpha: 0.15)
                        : AppTheme.backgroundElevated,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft:
                          Radius.circular(isOwn ? 12 : 2),
                      bottomRight:
                          Radius.circular(isOwn ? 2 : 12),
                    ),
                    border: Border.all(
                      color: isOwn
                          ? AppTheme.accentCyan.withValues(alpha: 0.2)
                          : AppTheme.borderSubtle,
                    ),
                  ),
                  child: Text(
                    message.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 2, right: 2),
                  child: Text(
                    timeStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'Say something to your raid...',
              ),
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          BlocBuilder<ChatCubit, ChatState>(
            buildWhen: (ChatState previous, ChatState current) =>
                previous.isSending != current.isSending,
            builder: (BuildContext context, ChatState state) {
              return Material(
                color: AppTheme.accentGreen,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: state.isSending ? null : onSend,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: state.isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.backgroundDeep,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            size: 18,
                            color: AppTheme.backgroundDeep,
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
