# 🚢 ShipRate

Professional ship evaluation and navigation safety platform for maritime pilots in Brazil.

## About

ShipRate serves **70+ active maritime pilots**, providing a comprehensive platform for ship evaluations and real-time navigation safety data. Built as a PWA for seamless access across all devices.

## Features

### ⚓ Navigation Safety
- **Depth Registry** — Record total depth, max draft, UKC, speed, and sonar position
- **Location Tracking** — 21+ pre-registered river locations with full history
- **Real-time Notifications** — Email and push alerts when new depths are registered
- **Coordinates** — LAT/LONG input with degrees, minutes, seconds
- **Historical Data** — Browse depth records by location with pilot attribution

### 🚢 Ship Evaluation
- **Ship Search** — Find ships by name or IMO number
- **Rating System** — Evaluate cabin, bridge, food, and crew conditions
- **Dashboard** — Statistics overview with total ships, ratings, and user contribution
- **PDF Reports** — Generate professional evaluation reports in PT or EN
- **MarineTraffic Integration** — Quick access to ship tracking details

### 🔐 Security
- **Email Whitelist** — Only pre-approved pilots can register
- **OTP Verification** — 6-digit code sent via email for new registrations
- **Rate Limiting** — Protection against brute force on OTP
- **Firestore Rules** — Server-side access control per collection
- **Secure API** — Admin endpoints require API key authentication

### 🌐 General
- **Multi-language** — Full support for Portuguese and English
- **Cross-platform** — Web, Android, and iOS via PWA
- **Push Notifications** — FCM-based alerts with opt-in/opt-out
- **Email Notifications** — Automated alerts with preference management

## Tech Stack

- **Frontend** — Flutter & Dart (PWA)
- **Backend** — Firebase (Auth, Firestore, Hosting, Cloud Functions)
- **Cloud Functions** — Node.js (modularized: auth, ratings, navigation safety)
- **Email** — Nodemailer with Gmail SMTP
- **Push** — Firebase Cloud Messaging (FCM)
- **PDF** — Custom generation in PT/EN
- **i18n** — Full internationalization support

## AI Disclosure

This project was developed with assistance from Claude AI (Anthropic) for architecture design, feature implementation, code refactoring, and documentation. All final decisions, testing, and deployment were performed by the developer.

## Author

**Paulo** — Software Development Student at SAIT, Calgary
Seeking co-op opportunities in software development.

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat-square&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/paulo-massao-santos-07009a2a4/)
