# Resource Swap

A campus peer-to-peer item rental app built with Flutter. Students can list items they own for rent, and others can request them — with a verified OTP handoff and automatic rent calculation.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| Image Storage | Supabase Storage |

---

## How It Works

### Listing an Item
A student lists an item with a name, hourly rent, description, and photos. Images are uploaded to Supabase Storage and the item appears on the marketplace for other users.

### Requesting an Item
Any other student can browse the marketplace and send a rental request. Only one active request is allowed per item at a time.

### OTP Handoff
The owner sees incoming requests and can accept or reject them. On acceptance, a 4-digit OTP is generated and shown to the owner. The requester enters this code in the app — this confirms the physical exchange happened in person.

### Rent Completion
Either party can mark the rent as complete. The app calculates the total amount based on actual time elapsed since the OTP was verified, at the listed hourly rate.

---

## Key Features

- Real-time request updates via Firestore streams
- OTP-based verified handoff (physical exchange confirmation)
- Automatic time-based rent calculation
- Image lifecycle management (cleanup of unused uploads)
- Dual backend: Firebase for auth/data, Supabase for image storage
