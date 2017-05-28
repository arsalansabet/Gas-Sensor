/*
 * Copyright (c) 2015, Majenko Technologies
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 * 
 * * Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 * 
 * * Redistributions in binary form must reproduce the above copyright notice, this
 *   list of conditions and the following disclaimer in the documentation and/or
 *   other materials provided with the distribution.
 * 
 * * Neither the name of Majenko Technologies nor the names of its
 *   contributors may be used to endorse or promote products derived from
 *   this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

 /* The code below has been modified for the purpose of the Gas Sensor Capstone
  * Project for ECE 412 and ECE 413 through Portland State University. Modifications
  * are made by Alec Wiese, Kam Robertson, Arsalan Sabet Sarvestani, and Noah Harvey.
  */

/* 
 * This code will Create a WiFi access point and provide a web server on it. This code
 * will be uploaded to the receiver side of the gas sensor. It is responsible for 
 * triggering the actuator when gas is detected. 
*/

// Required ESP8266 libraries
#include <ESP8266WiFi.h>
#include <WiFiClient.h> 
#include <ESP8266WebServer.h>

// Integer to clear gas sensor after detection
int clearGPIO2=0;
// Value to keep track of time for client to send data
unsigned long clientStartTime;
unsigned long clientWaitTime;
// Set these to your desired SSID and Passowrd credentials for security
const char *ssid = "Gas_Sensor";
const char *password = "eceCapstone";

// Create a server on port 80
WiFiServer server(80);

// Setup to create a HTTP server and WiFi Access Point
void setup() {
  delay(1000);
  // Set baud rate for communication
  Serial.begin(115200);
  delay(10);
  Serial.println();
  Serial.print("Configuring access point...\n");

  // Read SSID and Password strings and establish gas sensor WiFi AP 
  WiFi.softAP(ssid, password);
 

  // Establish IP address, store, and print IP Address
  IPAddress myIP = WiFi.softAPIP();
  Serial.print("AP IP address: ");
  Serial.println(myIP);
  Serial.println("HTTP server started");
  
  // GPIO4 is used to trip the actuator
  // Set GPIO4 as an output and initialize it as a logic "0"
  pinMode(4, OUTPUT);
  digitalWrite(4, 0);

  // GPIO2 is used to clear the gas sensor 
  // Set GPIO2 as an intput
  pinMode(2, INPUT);
  
  // Start the server
  server.begin();
  Serial.println("Server started");

  // Print the IP address
  Serial.println(WiFi.localIP());
}

// This loop checks if a client has connected
void loop() {
  // Check if a client has connected
  WiFiClient client = server.available();
  // If there is no client connected you can clear the gas sensor
  if (!client) {
    // Read GPIO2 and store it's value
    clearGPIO2 = digitalRead(2);
    // If GPIO2 is a logic "1" then clear the gas sensor at GPIO4 by writing logic "0"
    if (clearGPIO2){
      Serial.println("Clear!");
      digitalWrite(4, 0);
    }
    return;
  }
  
  //We must have a new client if we got to this point
  Serial.println("new client");
  clientStartTime = millis(); //This marks time of client communication
  while(!client.available()){
    delay(1);
    clientWaitTime = millis() - clientStartTime;
    //Return to the beginning of the loop if the client takes more than 1 second
    if(clientWaitTime > 1000 or clientWaitTime < 0) {
      client.stop();
      return;
    }
  }
  
  // Read the first line of the request
  String req = client.readStringUntil('\r'); //get request from client
  Serial.println(req);  //print client's request
  client.flush();
  
  // Integer to store the logic level from the transmitter
  int val;
  // Store the correct logic level in val depending on the GPIO value from the transmitter (gas sensor)
  if (req.indexOf("/gpio/0") != -1)
    val = 0;  //currently the client cannot request a "0" or clear but it is possible here
  else if (req.indexOf("/gpio/1") != -1)
    val = 1;  //We prepare to assert the gas shutoff if the client requests a "1"
  else {
    Serial.println("invalid request"); //Error handler, prints to screen
    client.stop();
    return;
  }

  // Do a check on GPIO2 in case user wants to clear the gas sesnor 
  // Read GPIO2 and store it's vlaue
  clearGPIO2 = digitalRead(2);
  // If GPIO2 is logic "0" than clear
  if (clearGPIO2)
  {
    Serial.println("Clear!");
    // Store logic "0" so actuator doesn't trip
    val = 0;
  }

  // Write to GPIO4 to trip the actuator if necessary depending on val logic level
  digitalWrite(4, val);

  // Wait one second
  delay(1000);
  
  client.flush();

  // Prepare the response
  String s = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n<!DOCTYPE HTML>\r\n<html>\r\nGPIO is now ";
  s += (val)?"high":"low";
  s += "</html>\n";

  // Send the response to the client
  client.print(s);
  delay(1);
  Serial.println("Client disonnected");
  return;
  // The client will actually be disconnected 
  // when the function returns and 'client' object is detroyed
}
