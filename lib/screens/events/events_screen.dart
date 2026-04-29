import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../repositories/event_repository.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final repo = context.read<EventRepository>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Campus Events',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: repo.upcomingEventsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snap.data ?? [];
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No upcoming events.',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Check back soon for new campus events!',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: events.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _EventCard(event: events[i], currentUid: uid),
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final String currentUid;

  const _EventCard({required this.event, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EventRepository>();
    final hasRsvp = event.rsvpedBy.contains(currentUid);
    final dateStr = DateFormat('EEE, MMM d • h:mm a').format(event.startTime);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner image or gradient placeholder
          if (event.imageUrl != null)
            CachedNetworkImage(
              imageUrl: event.imageUrl!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                  height: 160, color: Colors.grey.shade100),
              errorWidget: (context, url, error) =>
                  _EventPlaceholder(title: event.title),
            )
          else
            _EventPlaceholder(title: event.title),

          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: dateStr,
                ),
                const SizedBox(height: 4),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: event.location,
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people_outline,
                            size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${event.rsvpCount} going',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    FilledButton(
                      onPressed: () =>
                          repo.toggleRsvp(event.eventId, currentUid),
                      style: FilledButton.styleFrom(
                        backgroundColor: hasRsvp
                            ? Colors.grey.shade200
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: hasRsvp
                            ? Colors.grey.shade700
                            : Colors.white,
                        minimumSize: const Size(100, 36),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                      ),
                      child: Text(
                        hasRsvp ? '✓ Going' : 'RSVP',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _EventPlaceholder extends StatelessWidget {
  final String title;
  const _EventPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A73E8), Color(0xFF6EA8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16),
        ),
      ),
    );
  }
}
