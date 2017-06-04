/* The code below has been modified for the purpose of the Gas Sensor Capstone
   Project for ECE 412 and ECE 413 through Portland State University. Modifications
   are made by Alec Wiese, Kam Robertson, Arsalan Sabet Sarvestani, and Noah Harvey.
*/

/*
   This code will connect the ESP8266 WiFi module on the transmitter side where the gas
   sensor is connected to the receiver side where the actuator is placed. The ESP8266 will
   detect the output from the gas sensor and handle sending information about he presence
   of gas to the actuator.
*/
extern "C" {
#include "user_interface.h"
}
// Required ESP8266 libraries
#include <ESP8266WiFi.h>
#include <ESP8266WiFiMulti.h>

ESP8266WiFiMulti WiFiMulti;

// Variable to store logic level for the presence of gas
int my_in = 0;

// Setup code to connect to the actuator's WiFi access point and GPIO4 pin
void setup() {
  // Set baud rate for communication
  Serial.begin(115200);
  delay(10);
  delay(10);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println("Gas_Sensor");
  wifi_set_sleep_type(NONE_SLEEP_T);
  WiFi.persistent(false);     //These 3 lines are a required work-around
  WiFi.mode(WIFI_OFF);    //otherwise the module will not reconnect
  WiFi.mode(WIFI_STA);    //if it gets disconnected
  // Connect to the actuator's a WiFi network with SSID and Password
  WiFi.begin("Gas_Sensor", "eceCapstone");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  delay(500);

  // Set GPIO4 as input to detect gas sensor logic level
  pinMode(4, INPUT);
  delay(50);

}


void loop() {
  // Read GPIO4 to detect if gas is present and store it's logic level
  my_in = digitalRead(4);

  // If statement to make decision regarding gas sensor's logic level from GPIO4
  // If GPIO4 detects a logic "1" where gas is present this will be communicated to the actuator
  if (my_in)
  {
    // Message showing gas detected for serial monitor
    Serial.println("Houston, we have a 1!");

    // Store the host and IP address in order to connect to the actuator's server
    const uint16_t port = 80;
    const char * host = "192.168.4.1";

    // Attempt to connect to the actuator
    Serial.print("connecting to ");
    Serial.println(host);

    // Use WiFiClient class to create connection
    WiFiClient client;

    delay(100);
    // In case connection fails another attempt will be made in 5 seconds
    if (!client.connect(host, port)) {
      Serial.println("connection failed");
      Serial.println("wait 5 sec...");
      delay(5000);
      //return;
    }

    // This will send the request to the actuator with logic level "1"
    client.print("http://server_ip/gpio/1");

    // Read back one line from server
    String line = client.readStringUntil('\r');
    client.println(line);

    // Close the connection
    Serial.println("closing connection");
    client.stop();

    Serial.println("wait 5 sec...");
    delay(5000);
  }

  // If GPIO4 detects a logic "0" where gas isn't present communication to the actuator isn't necessary
  else if (!my_in)
  {
    Serial.println("Meh, it's a 0");
  }

  // In case GPIO4 detects a logic level that is not 0 or 1. This does not happen.
  else
  {
    Serial.println("This is not 0 or 1...");
  }

  delay(1000);
}

