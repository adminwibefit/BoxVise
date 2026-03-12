# 📦 Boxwise - Smart Inventory Management

**Boxwise** is a modern, premium inventory management application built with Flutter. It helps you organize your physical belongings into boxes, generate unique QR codes for instant identification, and keep track of every item with ease.

---

## ✨ Key Features

### 📊 Comprehensive Dashboard
*   **Real-time Statistics**: Instantly see your total boxes, total items, and low-stock alerts.
*   **Quick Actions**: Rapid access to creating boxes, adding items, and scanning QR codes.
*   **Activity Timeline**: Stay updated with a chronological log of recent inventory changes.

### 🔳 Smart QR System
*   **Auto-Generation**: Every box gets a unique UUID and a scannable QR code automatically.
*   **Integrated Scanner**: Identify any box instantly by scanning its QR label.
*   **QR Sheet**: View and print all your box QR codes from a single, organized screen.

### 📦 Inventory Organization
*   **Detailed Box Profiles**: Customize boxes with names, locations, and capacity limits.
*   **Item Tracking**: Add items with descriptions, quantities, and searchable tags.
*   **Search Engine**: A powerful global search to find any item or box in seconds.

### 🔒 Security & Privacy
*   **Pin Lock**: Keep your inventory data private with a secure entry screen.
*   **Local-First**: Data is stored locally on your device using SQLite for maximum privacy and offline access.

---

## 🎨 Design Aesthetics
*   **Glassmorphism**: Sleek, modern interface with subtle transparency and blur effects.
*   **Dark Mode Optimized**: Beautifully curated dark theme for comfortable use in any lighting.
*   **Premium Micro-animations**: Smooth transitions and interactive elements that make the app feel alive.

---

## 🛠️ Technology Stack
*   **Framework**: [Flutter](https://flutter.dev)
*   **State Management**: `Provider`
*   **Database**: `SQLite` (via `sqflite`)
*   **Icons**: Material Design Rounded
*   **Themes**: Custom Glassmorphic Design System

---

## 🚀 Getting Started

1.  **Clone the repo**:
    ```bash
    git clone https://github.com/harshith241005/Boxwise.git
    ```
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the app**:
    ```bash
    flutter run
    ```

---

## 📁 Project Structure
```text
lib/
├── models/      # Data structures (Box, Item, Activity)
├── providers/   # Business logic & state management
├── screens/     # UI Pages (Dashboard, Search, Scanner, etc.)
├── services/    # Data persistence (SQLite)
├── theme/       # Design system & color palettes
└── widgets/     # Reusable UI components
```

---

*Developed with ❤️ by the Boxwise Team*
