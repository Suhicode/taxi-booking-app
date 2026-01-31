# Taxi Booking App

A complete taxi booking application with customer and driver apps, real-time tracking, and payment integration.

## 🚀 Features

- **Customer App**: Book rides, track drivers, make payments
- **Driver App**: Accept rides, navigate to customers, track earnings
- **Real-time Communication**: WebSocket integration for live updates
- **Payment Integration**: Support for multiple payment methods
- **Admin Dashboard**: Manage users, rides, and analytics

## 📱 Apps

### Customer App
- Flutter-based mobile application
- Real-time ride tracking
- Multiple payment options
- Rating and review system

### Driver App
- Flutter-based mobile application  
- Ride acceptance and management
- Navigation integration
- Earnings tracking

### Backend
- Node.js/Express server
- WebSocket support for real-time features
- RESTful API design
- Database integration

## 🛠️ Tech Stack

- **Frontend**: Flutter
- **Backend**: Node.js, Express
- **Database**: MongoDB/PostgreSQL
- **Real-time**: Socket.io
- **Maps**: Google Maps API
- **Payments**: Stripe/Razorpay integration

## 🚀 Quick Start

### Using GitHub Codespaces

Click the "Code" button on this repository and select "Codespaces" to automatically set up a development environment with all dependencies installed.

### Local Development

1. Clone the repository
2. Install Flutter SDK
3. Install Node.js
4. Run backend server:
   ```bash
   cd taxi_app/backend
   npm install
   npm start
   ```
5. Run Flutter apps:
   ```bash
   flutter pub get
   flutter run
   ```

## 📦 Project Structure

```
├── customer_app/          # Customer Flutter app
├── driver_app/           # Driver Flutter app  
├── taxi_app/             # Main Flutter application
│   ├── backend/          # Node.js backend
│   ├── lib/              # Flutter source code
│   └── assets/           # Images and assets
├── backend/              # Additional backend services
└── .devcontainer/        # Codespaces configuration
```

## 🔧 Development

### Codespaces Configuration

This project is configured for GitHub Codespaces with:
- Pre-installed Flutter and Node.js
- VS Code extensions for Flutter development
- Automatic dependency installation
- Port forwarding for local testing

### Environment Variables

Copy `.env.example` to `.env` and configure:
- Database connection strings
- API keys for maps and payments
- WebSocket configuration

## 📱 Building

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
