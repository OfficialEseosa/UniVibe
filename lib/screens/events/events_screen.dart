import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      appBar: AppBar(title: const Text('Campus Events'), centerTitle: true),
      body: StreamBuilder<List<EventModel>>(
        stream: repo.upcomingEventsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snap.data ?? [];
          if (events.isEmpty) {
            return const Center(child: Text('No upcoming events.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: events.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
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

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.imageUrl != null)
            Image.network(event.imageUrl!,
                height: 160, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 14),
                  const SizedBox(width: 4),
                  Text(event.location,
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${event.startTime.month}/${event.startTime.day}/${event.startTime.year}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ]),
                const SizedBox(height: 8),
                Text(event.description, maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${event.rsvpCount} going',
                        style: Theme.of(context).textTheme.bodySmall),
                    FilledButton.tonal(
                      onPressed: () => repo.toggleRsvp(event.eventId, currentUid),
                      child: Text(hasRsvp ? 'Cancel RSVP' : 'RSVP'),
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
