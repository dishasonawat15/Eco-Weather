# Eco Weather Dashboard

A cross-platform Flutter mobile application for real-time weather tracking, air quality (AQI) monitoring, pollution alerts, and offline caching.

## Features

- **Real-Time Weather & Geolocation:** Fetches live temperature, feels-like temperature, humidity, wind speed, visibility, and atmospheric pressure using GPS coordinates or city search via OpenWeather APIs.
- **Air Quality (AQI) & Pollution Alerts:** Monitors local air pollution levels and triggers local notifications when air quality degrades.
- **Offline Caching:** Automatically caches the latest weather payload locally using `SharedPreferences` so recent conditions remain accessible without an active connection.
- **Modern Dark UI:** Responsive dashboard built with Material dark theme, gradient weather summary cards, and a metric grid.

## Tech Stack

- **Framework:** Flutter & Dart
- **Networking & Storage:** `http`, `shared_preferences`
- **Location & Alerts:** `geolocator`, local notifications service
- **Visualization:** `fl_chart`

## Setup & Installation

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/dishasonawat15/eco-weather.git](https://github.com/dishasonawat15/eco-weather.git)
   cd eco-weather