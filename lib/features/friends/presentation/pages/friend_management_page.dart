import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lumoni/design_system/design_system.dart';
import 'package:lumoni/features/friends/domain/entities/friendship.dart';
import 'package:lumoni/features/friends/domain/repositories/friend_repository.dart';
import 'package:lumoni/features/friends/presentation/cubits/friend_management_cubit.dart';
import 'package:lumoni/features/friends/presentation/cubits/friend_management_state.dart';
import 'package:lumoni/features/friends/presentation/widgets/friend_row_tile.dart';
import 'package:lumoni/features/friends/presentation/widgets/invite_card.dart';

class FriendManagementPage extends StatefulWidget {
  const FriendManagementPage({super.key});

  @override
  State<FriendManagementPage> createState() => _FriendManagementPageState();
}

class _FriendManagementPageState extends State<FriendManagementPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FriendManagementCubit, FriendManagementState>(
      listener: (context, state) {
        if (state.actionMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.actionMessage!,
                style: AppTypography.bodySmall.copyWith(color: Colors.white),
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusMd,
              ),
            ),
          );
          context.read<FriendManagementCubit>().clearMessages();
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage!,
                style: AppTypography.bodySmall.copyWith(color: Colors.white),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<FriendManagementCubit>().clearMessages();
        }
      },
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Friends'),
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.textPrimary,
            bottom: TabBar(
              indicatorColor: AppColors.accent,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTypography.buttonSmall,
              tabs: const [
                Tab(text: 'Friends'),
                Tab(text: 'Requests'),
                Tab(text: 'Add'),
              ],
            ),
          ),
          body: BlocBuilder<FriendManagementCubit, FriendManagementState>(
            builder: (context, state) {
              if (state.status == FriendManagementStatus.loading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              return TabBarView(
                children: [
                  _FriendsTab(friends: state.friends),
                  _RequestsTab(
                    incoming: state.incomingRequests,
                    outgoing: state.outgoingRequests,
                  ),
                  _AddTab(
                    searchController: _searchController,
                    searchResults: state.searchResults,
                    isSearching: state.isSearching,
                    invite: state.myInvite,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────── Friends Tab ──────────────────────────────────────────────

class _FriendsTab extends StatelessWidget {
  const _FriendsTab({required this.friends});

  final List<Friendship> friends;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.people_outline_rounded,
                size: 48,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No friends yet',
                style: AppTypography.heading6.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Send a friend request or share your invite code.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<FriendManagementCubit>().loadFriends(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.xl),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          return FriendRowTile(
            friendship: friend,
            onRemove: () =>
                context.read<FriendManagementCubit>().removeFriend(friend.id),
            onBlock: () =>
                context.read<FriendManagementCubit>().blockUser(friend.id),
          );
        },
      ),
    );
  }
}

// ─────────────────── Requests Tab ────────────────────────────────────────────

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({required this.incoming, required this.outgoing});

  final List<Friendship> incoming;
  final List<Friendship> outgoing;

  @override
  Widget build(BuildContext context) {
    if (incoming.isEmpty && outgoing.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'No pending requests.',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<FriendManagementCubit>().loadFriends(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          if (incoming.isNotEmpty) ...[
            Text(
              'Incoming',
              style: AppTypography.overline.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...incoming.map((r) => FriendRowTile(
                  friendship: r,
                  onAccept: () => context
                      .read<FriendManagementCubit>()
                      .acceptRequest(r.id),
                  onDecline: () => context
                      .read<FriendManagementCubit>()
                      .declineRequest(r.id),
                )),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (outgoing.isNotEmpty) ...[
            Text(
              'Outgoing',
              style: AppTypography.overline.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...outgoing.map((r) => FriendRowTile(
                  friendship: r,
                  onCancel: () => context
                      .read<FriendManagementCubit>()
                      .removeFriend(r.id),
                )),
          ],
        ],
      ),
    );
  }
}

// ─────────────────── Add Tab ─────────────────────────────────────────────────

class _AddTab extends StatelessWidget {
  const _AddTab({
    required this.searchController,
    required this.searchResults,
    required this.isSearching,
    required this.invite,
  });

  final TextEditingController searchController;
  final List<UserSearchResult> searchResults;
  final bool isSearching;
  final dynamic invite;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        // Redeem invite code
        _RedeemSection(),
        const SizedBox(height: AppSpacing.lg),

        // Search
        Text(
          'Find Friends',
          style: AppTypography.heading6.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: searchController,
          onChanged: (query) =>
              context.read<FriendManagementCubit>().searchUsers(query),
          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search by display name...',
            hintStyle: AppTypography.body.copyWith(
              color: AppColors.textTertiary,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textTertiary,
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMd,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMd,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMd,
              borderSide: const BorderSide(color: AppColors.accent),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (isSearching)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else
          ...searchResults.map((result) => _SearchResultTile(result: result)),

        const SizedBox(height: AppSpacing.xl),

        // Invite card
        Text(
          'Your Invite Code',
          style: AppTypography.heading6.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (invite != null)
          InviteCard(invite: invite!)
        else
          AppButton(
            label: 'Generate Invite Code',
            variant: AppButtonVariant.outlined,
            width: double.infinity,
            onPressed: () =>
                context.read<FriendManagementCubit>().loadInvite(),
          ),
      ],
    );
  }
}

class _RedeemSection extends StatelessWidget {
  final _codeController = TextEditingController();

  _RedeemSection();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Have an invite code?',
            style: AppTypography.heading6.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.none,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter code',
                    hintStyle: AppTypography.body.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    filled: true,
                    fillColor: AppColors.background.withValues(alpha: 0.6),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusMd,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusMd,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusMd,
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: 'Redeem',
                variant: AppButtonVariant.primary,
                onPressed: () {
                  final code = _codeController.text.trim();
                  if (code.isNotEmpty) {
                    context
                        .read<FriendManagementCubit>()
                        .redeemInvite(code.toLowerCase());
                    _codeController.clear();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.result});

  final UserSearchResult result;

  @override
  Widget build(BuildContext context) {
    final hasExisting = result.existingFriendshipStatus != null;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (result.countryCode != null)
                  Text(
                    result.countryCode!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (hasExisting)
            Text(
              _statusLabel(result.existingFriendshipStatus!),
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            )
          else
            GestureDetector(
              onTap: () =>
                  context.read<FriendManagementCubit>().sendRequest(result.uid),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Text(
                  'Add',
                  style: AppTypography.buttonSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _statusLabel(FriendshipStatus status) {
    return switch (status) {
      FriendshipStatus.accepted => 'Already friends',
      FriendshipStatus.pending => 'Pending',
      FriendshipStatus.blocked => 'Blocked',
      FriendshipStatus.declined => 'Declined',
    };
  }
}
