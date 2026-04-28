# UniVibe — UI/Frontend Handoff for Aaliyah Fievre

**Date:** April 28, 2026  
**From:** Raphael Omorose (Backend Lead)  
**For:** Aaliyah Fievre (UI/Frontend Lead)  
**Deadline:** May 3, 2026 @ 11:59 PM

---

## Overview

The entire backend is complete and live. Firebase Auth, Firestore, Storage, FCM, Cloud Functions, and security rules are all deployed and working. Every screen is wired up and functional — data flows in and out correctly. **Your job is to make it look good.**

You do not need to touch any files in `lib/models/`, `lib/services/`, `lib/repositories/`, `functions/`, `firestore.rules`, or `storage.rules`. Focus entirely on `lib/screens/` and `lib/main.dart`.

---

## Getting Started

```bash
# Clone and set up
git clone https://github.com/OfficialEseosa/UniVibe.git
cd UniVibe
flutter pub get

# Run on your emulator or device
flutter run
```

The app will launch and connect to the live Firebase project (`univibe-csc4360`) automatically. Register with any `.edu` email address to test.

---

## App Structure

### Navigation
The app uses a **bottom navigation bar** with 5 tabs managed in `lib/main.dart` → `MainShell`:

| Index | Tab | Screen File |
|-------|-----|-------------|
| 0 | Home (Feed) | `lib/screens/feed/feed_screen.dart` |
| 1 | Discover (Study Matches) | `lib/screens/discover/study_match_screen.dart` |
| 2 | Messages | `lib/screens/messages/messages_screen.dart` |
| 3 | Events | `lib/screens/events/events_screen.dart` |
| 4 | Profile | `lib/screens/profile/profile_screen.dart` |

### Auth Flow
- `lib/screens/auth/login_screen.dart` — shown when logged out
- `lib/screens/auth/register_screen.dart` — pushed from login screen

---

## Screen-by-Screen Breakdown

### 1. Login Screen (`lib/screens/auth/login_screen.dart`)
**What it does:** Email/password sign-in, navigates to RegisterScreen.  
**Backend:** Calls `AuthRepository.login()`. Errors are shown inline.  
**What to design:**
- UniVibe logo / branding at the top
- Email + password fields
- "Sign In" button
- "Register" link
- Match the campus identity color scheme

**Key widget:** The form + `FilledButton` are already there — just style them. The `_error` string is shown as red text; style it as a proper error banner if preferred.

---

### 2. Register Screen (`lib/screens/auth/register_screen.dart`)
**What it does:** Creates a new account. Only `.edu` emails are accepted (enforced backend-side).  
**Backend:** Calls `AuthRepository.register()`. Navigates back on success.  
**What to design:**
- Name, email, password fields
- "Register" button
- Onboarding feel — first impression of the app

---

### 3. Feed Screen (`lib/screens/feed/feed_screen.dart`)
**What it does:** Real-time scrollable post list. Tapping a post opens `PostDetailScreen`. FAB opens `CreatePostScreen`.  
**Backend:** `PostRepository.feedStream()` — auto-updates when new posts arrive.  
**What to design:**
- `_PostCard` widget — this is the main thing to polish. Give it a proper card layout: avatar, name, timestamp, content, image (if any), like button with count, comment count
- The `campusTag` is a string like `"academics"` or `"events"` — display it as a colored badge/chip
- Like button should show filled heart when `post.likedBy.contains(currentUid)` (already logic is there)
- FAB style

**Useful data available per post:**
```dart
post.authorName       // String
post.authorPhotoUrl   // String (URL or empty)
post.content          // String
post.imageUrl         // String? (null if no image)
post.likesCount       // int
post.likedBy          // List<String> — check .contains(currentUid) for liked state
post.campusTag        // String
post.createdAt        // DateTime — format with timeago or intl
```

**Packages already installed:** `timeago` (for "2 minutes ago") and `intl` (for date formatting). Use `timeago.format(post.createdAt)`.

---

### 4. Post Detail Screen (`lib/screens/feed/post_detail_screen.dart`)
**What it does:** Full post + threaded comments. Comment input at the bottom.  
**Backend:** `PostRepository.commentsStream(postId)` — live comment updates.  
**What to design:**
- Full post view at top (same card style as feed, but expanded)
- Comment list — each comment shows avatar, name, text, like count
- Comment input bar at the bottom (already functional, just style it)

---

### 5. Create Post Screen (`lib/screens/feed/create_post_screen.dart`)
**What it does:** Tag selector, text input, optional image picker, posts on submit.  
**Backend:** `PostRepository.createPost()` — handles image upload automatically.  
**What to design:**
- Clean compose UI — think Twitter/Instagram compose style
- Image preview with remove button (already functional)
- `campusTag` dropdown — style the dropdown items with colored dots or icons per tag:

| Tag | Suggested Icon |
|-----|---------------|
| general | `Icons.public` |
| academics | `Icons.school` |
| events | `Icons.event` |
| sports | `Icons.sports` |
| clubs | `Icons.groups` |
| housing | `Icons.home` |
| jobs | `Icons.work` |

---

### 6. Messages Screen (`lib/screens/messages/messages_screen.dart`)
**What it does:** List of active DM threads, sorted by most recent. Shows recipient name, last message preview, unread badge.  
**Backend:** `MessageRepository.threadsStream(uid)` — live updates.  
**What to design:**
- Thread list tiles with avatar, name, last message snippet, timestamp
- Unread badge (already rendered — just styled as a white-on-primary `CircleAvatar`)
- Empty state: "No conversations yet. Start chatting with a study partner!"

**Note:** Recipient display names are already resolved from Firestore — `name` and `photoUrl` are available in the `_ThreadTile` widget.

---

### 7. Chat Screen (`lib/screens/messages/chat_screen.dart`)
**What it does:** Real-time 1:1 chat. Messages bubble left/right by sender.  
**Backend:** `MessageRepository.messagesStream(threadId)` — live.  
**What to design:**
- Sent bubbles: right-aligned, primary color background
- Received bubbles: left-aligned, `surfaceContainerHighest` background (already set)
- Timestamp under each bubble or grouped by time
- Input bar with send button

---

### 8. Events Screen (`lib/screens/events/events_screen.dart`)
**What it does:** Upcoming campus events. Tap RSVP to toggle attendance.  
**Backend:** `EventRepository.upcomingEventsStream()` — only shows future events, sorted by date.  
**What to design:**
- Event card: banner image (if any), title, location, date/time, RSVP count, RSVP button
- RSVP button should visually differ when user has RSVP'd (`event.rsvpedBy.contains(currentUid)` is available)
- Empty state: "No upcoming events. Check back soon!"

**Useful data:**
```dart
event.title
event.description
event.location
event.startTime    // DateTime
event.imageUrl     // String?
event.rsvpCount    // int
event.rsvpedBy     // List<String>
```

---

### 9. Profile Screen (`lib/screens/profile/profile_screen.dart`)
**What it does:** Shows the logged-in user's profile. Edit button opens `EditProfileScreen`. Logout in AppBar.  
**Backend:** `FirestoreService.userStream(uid)` — live profile updates.  
**What to design:**
- Avatar (large), display name, email, bio
- Course chips row
- Availability summary (days/times set in Edit Profile)
- "Edit Profile" button
- Post grid or list showing this user's posts (optional enhancement — not required)

---

### 10. Edit Profile Screen (`lib/screens/profile/edit_profile_screen.dart`)
**What it does:** Edit name, bio, courses, profile photo, and weekly availability.  
**Backend:** Saves to Firestore and Firebase Storage automatically.  
**What to design:**
- Profile photo upload circle at top (tap to change — already functional)
- Form fields for name and bio
- Courses field (comma-separated)
- **Availability grid** — day × time-slot `FilterChip`s (already implemented and functional). Style the chips to look clean — selected state uses `cs.primary` background

---

### 11. Study Match Screen (`lib/screens/discover/study_match_screen.dart`)
**What it does:** Shows top-10 study partner suggestions ranked by compatibility score. Tapping a match opens a DM chat with them. Refresh button re-runs the scoring engine.  
**Backend:** `StudyMatchRepository.suggestionsStream(uid)` — live from Firestore.  
**What to design:**
- Match card: avatar, name, score badge, shared courses list, "Message" CTA
- Score is 0–100 — consider a visual indicator (progress bar, star rating, colored badge)
- Empty state with a "Find Study Partners" button (already wired — just style it)
- Refresh icon in AppBar (already functional)

**Useful data:**
```dart
match.matchName          // String
match.matchPhotoUrl      // String
match.score              // double (0–100)
match.sharedCourses      // List<String>
match.availabilityOverlap // Map<String, dynamic> — days that overlap
```

---

## Color Scheme & Theming

The app theme is defined in `lib/main.dart`:

```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF5C6BC0),  // indigo-ish purple
    brightness: Brightness.light,
  ),
  useMaterial3: true,
),
```

You can adjust the `seedColor` to match whatever campus identity color you choose. All Material 3 color roles (`primary`, `secondary`, `surface`, `onPrimary`, etc.) derive from it automatically.

To add a dark theme, add a `darkTheme` alongside `theme` in `UniVibeApp`.

---

## Packages Already Available

All of these are in `pubspec.yaml` — no new `pub add` needed:

| Package | Use for |
|---------|---------|
| `cached_network_image` | Smooth network image loading with placeholder/error states |
| `timeago` | Human-readable timestamps ("3 minutes ago") |
| `intl` | Date formatting (`DateFormat('MMM d, yyyy').format(date)`) |
| `image_picker` | Already used in Create Post and Edit Profile |
| `provider` | Already wired — access repos via `context.read<SomeRepo>()` |

### Using `cached_network_image`
Replace `Image.network(url)` with:
```dart
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => const Icon(Icons.broken_image),
)
```

Replace `NetworkImage(url)` inside `CircleAvatar` with:
```dart
CircleAvatar(
  backgroundImage: CachedNetworkImageProvider(url),
)
```

---

## How to Access Backend Data in Any Screen

All repositories are available via `Provider`. In any widget:

```dart
// Read once
final repo = context.read<PostRepository>();

// React to changes (inside build)
final repo = context.watch<PostRepository>();
```

Available via `context.read<T>()`:
- `PostRepository` — feed, create/delete post, like, comments
- `MessageRepository` — threads, send message, mark read
- `EventRepository` — events, RSVP
- `ClubRepository` — clubs, join/leave
- `StudyMatchRepository` — suggestions, refresh
- `AuthRepository` — login, logout, register
- `FirestoreService` — direct Firestore access (user streams, etc.)
- `StorageService` — upload images

---

## Testing Checklist (Section 10 of Proposal)

After your UI is complete, we need evidence for each of these:

| Test | Evidence Needed |
|------|----------------|
| Firebase Auth | Screenshot of Firebase Console Auth dashboard showing registered users |
| Real-time feed | Screen recording of a post appearing on two emulators simultaneously |
| Likes & comments | Screenshot of Firestore document + UI video showing count update |
| Direct messaging | Chat demo screenshots + Firestore message document screenshot |
| FCM push | Device screenshot showing notification banner (send a message while app is in background) |
| Study-partner engine | Cloud Function logs + UI screenshot of match results |
| Security rules | Firebase Rules Simulator passing tests |

---

## Git Workflow

We are both working on `main`. Please **pull before you push**:

```bash
git pull origin main
# make your changes
git add .
git commit -m "ui: describe what you changed"
git push origin main
```

If there's a conflict, come find me.

---

## Questions?

Text me or open an issue at https://github.com/OfficialEseosa/UniVibe/issues.
