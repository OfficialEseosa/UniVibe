import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ── Scoring weights ───────────────────────────────────────────────────────────
const SHARED_COURSE_PTS = 10;
const MAX_COURSE_SCORE = 60;
const AVAILABILITY_DAY_PTS = 5;
const MAX_AVAILABILITY_SCORE = 30;
const BIO_KEYWORD_PTS = 5;
const MAX_BIO_SCORE = 10;
const DAYS = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"];
const ACADEMIC_KEYWORDS = [
  "study", "research", "engineering", "cs", "biology",
  "math", "science", "programming", "design", "art",
  "music", "chemistry", "physics", "nursing", "business",
];

// ── Study-partner suggestion engine ──────────────────────────────────────────

export const computeStudyMatches = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be signed in to compute study matches."
      );
    }

    const uid = context.auth.uid;
    const currentSnap = await db.collection("users").doc(uid).get();
    const current = currentSnap.data();
    if (!current) {
      throw new functions.https.HttpsError("not-found", "User profile not found.");
    }

    const allUsersSnap = await db.collection("users").get();
    const results: Array<{ uid: string; score: number; data: object }> = [];

    for (const doc of allUsersSnap.docs) {
      if (doc.id === uid) continue;
      const candidate = doc.data();
      const score = scoreCandidate(current, candidate);
      if (score > 0) {
        results.push({ uid: doc.id, score, data: candidate });
      }
    }

    results.sort((a, b) => b.score - a.score);
    const top = results.slice(0, 10);

    const batch = db.batch();
    for (const match of top) {
      const candidate = match.data as Record<string, unknown>;
      const ref = db
        .collection("studyMatches")
        .doc(uid)
        .collection("suggestions")
        .doc(match.uid);

      const sharedCourses = (current.courses as string[]).filter((c: string) =>
        ((candidate.courses as string[]) ?? []).includes(c)
      );
      const overlapDays = computeOverlapDays(
        current.availability ?? {},
        candidate.availability ?? {}
      );

      batch.set(ref, {
        matchName: candidate.displayName ?? "",
        matchPhotoUrl: candidate.profilePhotoUrl ?? "",
        score: match.score,
        sharedCourses,
        availabilityOverlap: Object.fromEntries(overlapDays.map((d) => [d, true])),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    return { matched: top.length };
  }
);

function scoreCandidate(
  current: Record<string, unknown>,
  candidate: Record<string, unknown>
): number {
  const currentCourses = (current.courses as string[]) ?? [];
  const candidateCourses = (candidate.courses as string[]) ?? [];
  const shared = currentCourses.filter((c) => candidateCourses.includes(c));
  const courseScore = Math.min(shared.length * SHARED_COURSE_PTS, MAX_COURSE_SCORE);

  const overlapDays = computeOverlapDays(
    (current.availability as Record<string, unknown>) ?? {},
    (candidate.availability as Record<string, unknown>) ?? {}
  );
  const availScore = Math.min(
    overlapDays.length * AVAILABILITY_DAY_PTS,
    MAX_AVAILABILITY_SCORE
  );

  const bioScore = computeBioScore(
    (current.bio as string) ?? "",
    (candidate.bio as string) ?? ""
  );

  return courseScore + availScore + bioScore;
}

function computeOverlapDays(
  a: Record<string, unknown>,
  b: Record<string, unknown>
): string[] {
  return DAYS.filter((day) => {
    const aSlots = a[day];
    const bSlots = b[day];
    if (aSlots == null || bSlots == null) return false;
    if (Array.isArray(aSlots) && Array.isArray(bSlots)) {
      return aSlots.some((s) => bSlots.includes(s));
    }
    return aSlots === true && bSlots === true;
  });
}

function computeBioScore(bio1: string, bio2: string): number {
  if (!bio1 || !bio2) return 0;
  const words1 = bio1.toLowerCase().split(/\W+/);
  const words2 = bio2.toLowerCase().split(/\W+/);
  const sharedKeywords = ACADEMIC_KEYWORDS.filter(
    (kw) => words1.includes(kw) && words2.includes(kw)
  ).length;
  return Math.min(sharedKeywords * BIO_KEYWORD_PTS, MAX_BIO_SCORE);
}

// ── FCM: notify on new message ────────────────────────────────────────────────

export const onNewMessage = functions.firestore
  .document("messages/{threadId}/messages/{msgId}")
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const threadId = context.params.threadId as string;

    const threadSnap = await db.collection("messages").doc(threadId).get();
    const thread = threadSnap.data();
    if (!thread) return;

    const participants = (thread.participants as string[]) ?? [];
    const senderUid = message.senderUid as string;

    for (const uid of participants) {
      if (uid === senderUid) continue;

      const userSnap = await db.collection("users").doc(uid).get();
      const token = userSnap.data()?.fcmToken as string | undefined;
      if (!token) continue;

      const senderSnap = await db.collection("users").doc(senderUid).get();
      const senderName = (senderSnap.data()?.displayName as string) ?? "Someone";

      await messaging.send({
        token,
        notification: {
          title: `New message from ${senderName}`,
          body: (message.text as string).slice(0, 100),
        },
        data: { type: "message", threadId, senderUid },
      });
    }
  });

// ── FCM: notify on new like ───────────────────────────────────────────────────

export const onPostLiked = functions.firestore
  .document("posts/{postId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if ((after.likesCount as number) <= (before.likesCount as number)) return;

    const postId = context.params.postId as string;
    const authorUid = after.authorUid as string;

    // Identify who added the like
    const beforeLikedBy = new Set(before.likedBy as string[]);
    const newLiker = (after.likedBy as string[]).find(
      (uid) => !beforeLikedBy.has(uid)
    );
    if (!newLiker || newLiker === authorUid) return;

    const [authorSnap, likerSnap] = await Promise.all([
      db.collection("users").doc(authorUid).get(),
      db.collection("users").doc(newLiker).get(),
    ]);

    const token = authorSnap.data()?.fcmToken as string | undefined;
    if (!token) return;

    const likerName = (likerSnap.data()?.displayName as string) ?? "Someone";
    const postPreview = ((after.content as string) ?? "").slice(0, 50);

    await messaging.send({
      token,
      notification: {
        title: `${likerName} liked your post`,
        body: postPreview,
      },
      data: { type: "like", postId },
    });
  });

// ── FCM: notify on event RSVP ─────────────────────────────────────────────────

export const onEventRsvp = functions.firestore
  .document("events/{eventId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if ((after.rsvpCount as number) <= (before.rsvpCount as number)) return;

    const eventId = context.params.eventId as string;
    const clubId = after.clubId as string;
    if (!clubId) return;

    const clubSnap = await db.collection("clubs").doc(clubId).get();
    const adminUid = clubSnap.data()?.adminUid as string | undefined;
    if (!adminUid) return;

    const adminSnap = await db.collection("users").doc(adminUid).get();
    const token = adminSnap.data()?.fcmToken as string | undefined;
    if (!token) return;

    await messaging.send({
      token,
      notification: {
        title: "New RSVP on your event",
        body: `Someone just RSVP'd to "${after.title as string}"`,
      },
      data: { type: "rsvp", eventId },
    });
  });
