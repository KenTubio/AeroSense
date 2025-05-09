#define BLYNK_TEMPLATE_ID "TMPL6Kdlzq_Gc"
#define BLYNK_TEMPLATE_NAME "Air Monitor"
#define BLYNK_AUTH_TOKEN "Cc4I-8AMONW2CZwWkd-bZEz10otAcMOw"

#define BLYNK_PRINT Serial    
#include <SPI.h>
#include <ESP8266WiFi.h>
#include <BlynkSimpleEsp8266.h>
#include <WiFiManager.h>      
#include <DHT.h>
#include <MQ135.h>            
#include <ArduinoOTA.h>       

#define DHTPIN 2             
#define DHTTYPE DHT11         
DHT dht(DHTPIN, DHTTYPE);

const int mq135Pin = A0;      
MQ135 mq135(mq135Pin);       

BlynkTimer timer;             

double gasSum = 0;            
int gasReadingsCount = 0;     


void sendSensor() {
    double h = dht.readHumidity();
    double t = dht.readTemperature(); 

    if (isnan(h) || isnan(t)) {
        Serial.println("Failed to read from DHT sensor!");
        return;
    }

    Serial.print("Temperature: ");
    Serial.print(t);
    Serial.print("°C, Humidity: ");
    Serial.print(h);
    Serial.println("%");

  
    Blynk.virtualWrite(V4, h);  
    Blynk.virtualWrite(V3, t);  
}


void sendGasValue() {
    double gasValue = mq135.getPPM();  

    
    Serial.print("Gas Value: ");
    Serial.println(gasValue);

   
    Blynk.virtualWrite(V0, gasValue);  

   
    gasSum += gasValue;
    gasReadingsCount++;

 
    String alertMessage = "";  /
    if (gasValue >= 0 && gasValue <= 50) {
        alertMessage = "Good";
    } else if (gasValue > 50 && gasValue <= 100) {
        alertMessage = "Moderate";
    } else if (gasValue > 100 && gasValue <= 150) {
        alertMessage = "Sensitive Levels";
    } else if (gasValue > 150 && gasValue <= 200) {
        alertMessage = "Unhealthy";
    } else if (gasValue > 200 && gasValue <= 300) {
        alertMessage = "Harmful";
    } else if (gasValue > 300) {
        alertMessage = "Hazardous";
    }

    
    Blynk.virtualWrite(V2, alertMessage);  
}


void sendDailyAverage() {
    if (gasReadingsCount > 0) {
        double dailyAverage = gasSum / gasReadingsCount;  // Calculate average
        Serial.print("Daily Average Gas Value: ");
        Serial.println(dailyAverage);

        
        Blynk.virtualWrite(V1, dailyAverage);  

        
        Serial.println("Daily average sent to V1");

        
        gasSum = 0;
        gasReadingsCount = 0;
    }
}

void setup() {
    Serial.begin(9600);
    Serial.println("Starting NodeMCU...");
    Serial.println("Booting up...");

    
    dht.begin();
    Serial.println("DHT sensor initialized.");

  
    WiFiManager wifiManager;
    wifiManager.autoConnect("AeroSensor_Connect");

    Serial.println("Connected to WiFi!");

    
    Blynk.config(BLYNK_AUTH_TOKEN);
    while (Blynk.connect() == false) {
        // Wait for connection
    }

    
    timer.setInterval(1000L, sendSensor);       
    timer.setInterval(2000L, sendGasValue);     
    timer.setInterval(3600000L, sendDailyAverage);  


    
    ArduinoOTA.begin();
}

void loop() {
    Blynk.run();   
    timer.run();   
    ArduinoOTA.handle();  
}