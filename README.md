# 🚢 ShipRate Pro

Professional ship evaluation, depth recording, and ship crossing coordination platform for maritime pilots in Brazil.

## About

ShipRate Pro serves **80+ active maritime pilots** in the Amazon Basin, providing a comprehensive platform for ship evaluations, real-time navigation depth data, and ship crossing coordination. Available as a **PWA** and as a **native iOS app** on the App Store.

## Features

### 🚢 Ship Evaluation
- **Ship Search** — Find ships by name or IMO number across 215+ registered vessels
- **Rating System** — Evaluate cabin temperature, cleanliness, bridge equipment, food, crew relationship, and boarding device
- **Like System** — React to ratings from other pilots
- **Dashboard** — Real-time statistics with total ships, ratings, pilot ranking, and personal contribution
- **PDF Reports** — Export professional ship reports with averages and individual observations in PT or EN
- **MarineTraffic Integration** — Quick access to ship tracking details

### ⚓ Depths - Records
- **Depth Registry** — Record total depth, max draft, UKC, speed, direction, and sonar position
- **Photo Attachments** — Attach up to 3 photos of sonar/ECDIS readings per record
- **Location Management** — 25+ river locations with full history, sorted alphabetically
- **Like System** — React to depth records from other pilots
- **Coordinates** — LAT/LONG input in degrees and decimal minutes
- **WhatsApp Sharing** — Share depth records with formatted messages
- **Historical Data** — Browse depth records by location with pilot attribution

### 🔄 Ship Crossing
- **Crossing Registration** — Register ship crossings with location, time, ship name, direction, and draft
- **Preset Locations** — Quick selection from common crossing points
- **Draft Categories** — Three draft ranges: up to 6.5m, 6.5-9.5m, above 9.5m
- **Edit Crossing** — Update crossing time with automatic push notification to all pilots
- **Scale Calendar** — Toggle alerts on/off with shift end date for automatic disable
- **Auto-Cleanup** — Expired crossings are automatically removed hourly
- **Crossing Stats** — Ranking and historical crossing count
- **WhatsApp Sharing** — Share crossing details with other pilots

### 🔔 Notifications
- **Push Notifications** — FCM-based with APNs support for iOS
- **Separate Controls** — Independent toggles for depth records, ratings/likes, and crossings
- **Scale Calendar** — Set shift end date to auto-disable crossing alerts
- **Email Notifications** — Automated alerts for new depth records
- **Inactivity Reminder** — Weekly reminder for pilots inactive 90+ days

### 🔐 Security
- **Email Whitelist** — Only pre-approved maritime pilots can register
- **OTP Verification** — 6-digit code sent via email for new registrations
- **Rate Limiting** — Protection against brute force on OTP
- **Firestore Rules** — Server-side access control per collection
- **Account Deletion** — Full account removal with re-authentication and rollback protection
- **Privacy Manifest** — Apple-compliant privacy declarations

### 🌐 General
- **Multi-language** — Full support for Portuguese and English
- **iOS Native** — Available on the App Store as ShipRate Pro
- **PWA** — Web app accessible on any browser
- **Instant Loading** — Cache-first strategy with Firestore offline persistence
- **Deep Links** — Push notifications open directly to relevant pages
- **Cross-platform Sharing** — WhatsApp sharing works on both web and iOS

## Tech Stack

- **Frontend** — Flutter & Dart (PWA + iOS native)
- **Backend** — Firebase (Auth, Firestore, Hosting, Cloud Functions, Storage, Cloud Messaging)
- **Cloud Functions** — Node.js (21 modular functions: auth, ratings, navigation safety, crossings, notifications, stats)
- **Email** — Nodemailer with Gmail SMTP
- **Push** — Firebase Cloud Messaging (FCM) with APNs for iOS
- **PDF** — Custom generation in PT/EN
- **i18n** — Full internationalization support

## AI Disclosure

This project was developed with assistance from Claude AI (Anthropic) and OpenAI Codex for architecture design, feature implementation, prompt engineering, code review, and documentation. All final decisions, testing, and deployment were performed by the developer.

## Author

**Paulo Massao Santos** — Software Development Student at SAIT, Calgary

Seeking co-op opportunities in software development.

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat-square&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/paulo-massao-santos-07009a2a4/)
