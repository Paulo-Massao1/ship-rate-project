# 🚢 ShipRate Pro

Professional ship evaluation, depth recording, crossing coordination, and maneuver reporting platform for maritime pilots in Brazil.

## About

ShipRate Pro serves **100+ active maritime pilots** in the Amazon Basin, providing a comprehensive platform for ship evaluations, real-time navigation depth data, ship crossing coordination, maneuver reporting, and tide table consultation. Available as a **PWA** and as a **native iOS app** on the App Store.

## Features

### 🚢 Ship Evaluation
- **Ship Search** — Find ships by name or IMO number across 300+ registered vessels
- **Rating System** — Evaluate cabin temperature, cleanliness, bridge equipment, food, crew relationship, boarding device.
- **PDF Reports** — Export professional ship reports with averages and individual observations in PT or EN
- **MarineTraffic Integration** — Quick access to ship tracking details

### ⚓ Depths - Records
- **Depth Registry** — Record total depth, max draft, UKC, speed, direction, and sonar position
- **File Attachments** — Attach photos, PDFs, GPX, SeaIQ files, and any other document type per record
- **Location Management** — 25+ river locations with full history, sorted alphabetically
- **Depth Trend Charts** — Interactive line charts showing depth variation per location over time (Premium)
- **Like System** — React to depth records from other pilots
- **Coordinates** — LAT/LONG input in degrees and decimal minutes
- **WhatsApp Sharing** — Share depth records with formatted messages
- **Contribution Rankings** — Anonymous leaderboards with personal position highlighted

### 🔄 Ship Crossing
- **Crossing Registration** — Register ship crossings with location, time, ship name, direction, and draft
- **Preset Locations** — Quick selection from common crossing points
- **Scale Calendar** — Toggle alerts on/off with shift end date for automatic disable
- **WhatsApp Sharing** — Share crossing details with other pilots

### ⚓ Maneuvers (Plus)
- **Port Database** — 4 regions with 15+ ports
- **Port Information** — Limits, initial info, and mooring details in expandable sections
- **Maneuver Reports** — Record ship data, approach conditions, current, wind, tugboats, and mooring
- **Tugboat Registry** — Select from existing tugboats or register new ones with name, bollard pull, and type
- **Media Attachments** — Attach photos and videos to maneuver reports

### 🌊 Navigation Info
- **Tide Tables** — Official Brazilian Navy tide data for 5 locations, full year 2026, offline
- **Barra Norte** — Restricted area with POB scheduling, procedures for 1 and 2 pilots, waypoints, and operational PDFs (14 documents)
- **Operational Restrictions** — ZP-01 operational parameters with in-app PDF viewer
- **Maximum Drafts** — Draft limits by port document

### ⭐ Subscription (In-App Purchase)
- **ShipRate Plus** — Monthly report with PDF export + Maneuvers module access
- **ShipRate Premium** — Everything in Plus + depth trend charts
- **Monthly Report** — Automated PDF with ratings, depths, crossings, and ranking positions per module
- **RevenueCat Integration** — Subscription management with Apple App Store billing

### 🔔 Notifications
- **Push Notifications** — FCM-based with APNs support for iOS
- **Separate Controls** — Independent toggles for depth records, ratings/likes, and crossings
- **Scale Calendar** — Set shift end date to auto-disable crossing alerts
- **Email Notifications** — Automated alerts for new depth records
- **Inactivity Reminder** — Weekly reminder for pilots inactive 90+ days

### 🔐 Security
- **Email Whitelist** — Only pre-approved maritime pilots can register
- **OTP Verification** — 6-digit code sent via email for new registrations
- **Firestore Rules** — Server-side access control with public pilotStats collection for rankings
- **Account Deletion** — Full account removal with re-authentication and rollback protection
- **Privacy Manifest** — Apple-compliant privacy declarations

### 🌐 General
- **Multi-language** — Full support for Portuguese and English 
- **iOS Native** — Available on the App Store as ShipRate Pro
- **PWA** — Web app with vendorized Firebase SDKs for Safari/iOS compatibility

## Tech Stack

- **Frontend** — Flutter 3.44.2 & Dart 3.12.2 
- **Backend** — Firebase (Auth, Firestore, Hosting, Cloud Functions, Storage, Cloud Messaging)
- **Cloud Functions** — Node.js (24 modular functions: auth, ratings, navigation safety, crossings, notifications, stats, backfills)
- **Subscriptions** — RevenueCat SDK with Apple StoreKit 2
- **Email** — Nodemailer with Gmail SMTP
- **Push** — Firebase Cloud Messaging (FCM) with APNs for iOS
- **PDF** — Custom generation in PT/EN (ship reports + monthly contribution reports)
- **CI/CD** — Codemagic with pinned Flutter/Xcode versions for reproducible builds

## AI Disclosure

This project was developed with assistance from Claude AI (Anthropic) and Claude Code for architecture design, feature implementation, prompt engineering, code review, and documentation. All final decisions, testing, and deployment were performed by the developer.

## Author

**Paulo Massao Santos** — Software Development Student at SAIT, Calgary


[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat-square&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/paulo-massao-santos-07009a2a4/)
