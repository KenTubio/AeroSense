# 🌬️ AeroSense PH — Air Quality Monitoring System

**AeroSense PH** is a real-time air quality monitoring system that combines an NodeMCU-based hardware setup with a Flutter mobile application. This project empowers users to monitor temperature, humidity, and air quality through an intuitive and visually appealing mobile interface.


[Download the App Here: ](https://drive.google.com/file/d/103qOiepXECoP2Kikui-eDEJjB3VBAlDo/view?usp=drive_link)


---

## 📱 Flutter Mobile App

### 🔧 Built With
- **Flutter** (Dart)
- **Firebase Firestore** (for storing daily gas data)
- **Blynk API** (to retrieve real-time sensor data)

### 💡 Features
- Real-time display of:
  - 🌡️ Temperature
  - 💧 Humidity
  - 🏭 Gas/air quality index
- Dynamic gauge and alert message based on AQI levels
- Chart-based history view using Syncfusion
- Sensor ID registration and locator assignment
- Weather data for cities in the Philippines
- Notification alerts for poor air quality
- Firebase integration for persistent daily averages

---

## 🔌 Hardware Component

### 🧩 Components Used
- **NodeMCU ESP8266**
- **DHT11 Sensor** – for temperature and humidity
- **MQ135 Sensor** – for gas detection / air quality
- **Jumper Wires, Breadboard**
- **Power Source (USB / Battery)**

### 🛠 Hardware Features
- Connects to WiFi using `WiFiManager`
- Sends sensor data to Blynk every few seconds
- Calculates and stores daily average gas readings
- Sends categorized AQI messages to Blynk

---

## 🔗 Data Flow Overview

