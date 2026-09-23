# Kruizly Android 🚗💨

[![Flutter](https://img.shields.io/badge/Flutter-3.35.7-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2?logo=dart)](https://dart.dev)
[![State](https://img.shields.io/badge/State-Flutter%20Riverpod%202.6-purple)](https://riverpod.dev)
[![Database](https://img.shields.io/badge/Database-Hostinger%20MySQL%20(Live)-orange)](https://Kruizly.com)
[![License](https://img.shields.io/badge/License-Proprietary-red)](#)

> Modern, high-performance Flutter mobile application for **Kruizly Self-Drive & Chauffeur Car Rentals** in Mumbai & Navi Mumbai. Fully synchronized with live Hostinger production MySQL backend (`u303154098_carRentpe`), real-time booking calculations, glassmorphism aesthetics, background ambient video playback, and complete staff role command centers.

---

## ✨ Features Overview

### 1. 🌐 Live Hostinger MySQL Synchronized Engine
- **Direct Live Synchronization**: Communicates with production Hostinger REST APIs (`https://Kruizly.com/api`).
- **Live 39 Catalog Vehicles**: Real-time vehicle metadata, pricing (hourly and daily), transmission, fuel, seats, bags, deposit, and availability status.
- **Authentic 9 Active Fleets**: Synchronized directly with `/api/vehicles/active-fleet.php` featuring partner owners (Aditi Lotankar, Viren Gupta, Ajay Vishwakarma, Kundan Singh, Tai Phad, Amol Gole, Saif Feroz Shaikh, Kruizly Fleet Host, Anil Kumar Gupta).
- **Live Bookings & Customers**: Audited ledger with live bookings, customer KYC verification, and dynamic monthly revenue metrics.
- **Zero Demo/Mock Data**: Completely clean, zeroed fallbacks when offline; all dynamic metrics recalculate from live data.

### 2. 🔐 Role-Based Command Centers & Portals
Kruizly features purpose-built staff and administrative portals mirroring the web platform (`Kruizly.com`):

#### 👑 Admin Panel (8 Specialized Subtabs)
1. **All Bookings**: Comprehensive booking management with status filters (`All`, `Confirmed`, `Pending`, `Cancelled`), date range picker, and collapsible customer & trip details.
2. **Booking Calendar**: Interactive month calendar grid + agenda view mapping all vehicle allocations.
3. **User Accounts & Verification**: User directory with search, role badges (`Admin`, `Manager`, `Executive`, `Customer`), and identity document verification modal.
4. **Users & Customers Analytics**: Quick date range filters, 5 live KPI cards (Total Users, Active Customers, Conversion Rate, etc.), and monthly user acquisition breakdown.
5. **Bookings & Reservations Analytics**: Revenue performance metrics and monthly booking distribution.
6. **Vehicle Acquisition**: Host onboarding pipeline and vehicle intake review.
7. **Fleet Management**: Active fleet roster (9 removable fleet chips), Add/Edit vehicle form, and complete fleet catalogue.
8. **Coupons**: Configured discount codes management with discount percentages, flat caps, and new coupon creation.

#### 📊 Manager Panel (4 Performance Subtabs)
1. **Revenue & Sales**: Verified monthly revenue ledger (July ₹50.5k, August ₹281.8k, September ₹302.9k, October ₹28k, Total ₹6.63L) with custom date filters.
2. **Fleet Performance (9 Fleets)**: Top performing vehicle spotlight (`MG Hector`), KPI counters, status pills (`All`, `On Trip`, `Yard`), and utilization breakdown.
3. **Bookings Analytics**: 4 KPI cards, verified bookings activity log, and export trigger.
4. **Operations & Reconciliation**: 4 operational KPIs, 9 fleet cards with revenue metrics and utilization progress bars, plus collapsible other fleet catalog.

#### 💳 Accounts Panel
- **Payment Verification Queue**: 2 KPI cards (`Pending Verification`, `Verified Payments`), live search, UTR matching, payment receipt tags, and one-tap approval/rejection.

#### ⚡ Executive Operations Hub (5 Subtabs + Ambient Video)
1. **Operations & Bookings**: Active trips, pickups today, returns today, pending payments, and pending KYC with quick action handovers.
2. **Booking Calendar**: Fleet schedule overview.
3. **Customer ID Verification**: KYC document inspection (Driving License, Aadhaar, PAN).
4. **Fleet Preview**: Catalog browser with live specifications and pricing.
5. **Coupon Preview**: Active coupon code lookup.
- **Ambient Looped Video**: Seamless, muted hardware-accelerated video background (`assets/background-video.mp4`) with glass overlay and instant toggle in AppBar.

### 3. 🚗 Customer Experience & Booking Journey
- **Vehicle Catalog**: Categorized car browser (Luxury, SUV, Sedan, Hatchback) with filter chips, transmission filter, and pricing toggles.
- **Precision Booking Engine**: 
  - 24-hour daily rate calculations & hourly extensions.
  - Chauffeur / Driver option toggle with transparent per-day pricing.
  - Refundable security deposit management.
  - Payment plan flexibility: **20% Advance Booking** or **100% Full Payment**.
  - Dynamic coupon validation with percentage calculation and maximum discount capping.
- **Glassmorphic UI**: High-contrast dark and light themes, crisp typography, borderless vehicle cards with subtle shadows, and intuitive navigation.

---

## 🏗️ Architecture & Technology Stack

- **Framework**: Flutter 3.35.x / Dart 3.9.x
- **State Management**: [Riverpod 2.6](https://riverpod.dev) (`flutter_riverpod`)
- **Routing**: [GoRouter 14.8](https://pub.dev/packages/go_router)
- **HTTP Client**: [Dio 5.8](https://pub.dev/packages/dio) with interceptors and base configuration
- **Media Engine**: [video_player 2.14](https://pub.dev/packages/video_player)
- **Security & Storage**: `flutter_secure_storage` & `shared_preferences`
- **UI & Animations**: `intl`, `cached_network_image`, `shimmer`, custom glass cards

```
lib/
├── core/
│   ├── constants/       # API endpoints, assets, and app keys
│   ├── network/         # Dio HTTP client & exception handling
│   ├── theme/           # AppTheme (Dark & Light palettes)
│   └── utils/           # Formatters, date helpers, validators
├── data/
│   ├── models/          # Vehicle, Booking, User, Coupon, AdminStats
│   ├── repositories/    # Live Hostinger data access layers
│   └── services/        # Storage and background services
└── presentation/
    ├── screens/
    │   ├── auth/        # Login, Register, OTP screens
    │   ├── booking/     # Booking details, breakdown, payment selection
    │   ├── home/        # Fleet catalog, filters, hero banner
    │   ├── profile/     # User profile, KYC upload, reservations
    │   └── staff/       # Admin, Manager, Accounts, and Executive dashboards
    ├── state/           # Riverpod state notifiers and providers
    └── widgets/         # GlassCard, BackgroundVideoWidget, VehicleCard, StatusBadge
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.3.0`)
- Android Studio / VS Code with Flutter extension
- Android SDK (API 34+ recommended)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/AyanChougle/Kruizly-Android.git
   cd Kruizly-Android
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run static analysis:
   ```bash
   flutter analyze
   ```
4. Run all unit and widget tests:
   ```bash
   flutter test
   ```
5. Launch on an Android device or emulator:
   ```bash
   flutter run
   ```

---

## 🧪 Testing

The codebase includes automated tests covering serialization, price calculations, widget rendering, and background video components:

```bash
flutter test
```
All 15 test suites pass with 0 warnings or errors.

---

## 📄 License
© 2026 Kruizly Technologies Pvt. Ltd. All rights reserved.
