/*
 *  This sketch sends a message to a TCP server
 *
 */

#include <ESP8266WiFi.h>
#include <ESP8266WiFiMulti.h>

ESP8266WiFiMulti WiFiMulti;
int my_in = 0;

void setup() {
    Serial.begin(115200);
    delay(10);

    // We start by connecting to a WiFi network
    WiFiMulti.addAP("ESPap"); //ADD YOUR SSID and PASSWORD HERE!!!!

    Serial.println();
    Serial.println();
    Serial.print("Wait for WiFi... ");

    while(WiFiMulti.run() != WL_CONNECTED) {
        Serial.print(".");
        delay(500);
    }

    Serial.println("");
    Serial.println("WiFi connected");
    Serial.println("IP address: ");
    Serial.println(WiFi.localIP());

    delay(500);
    pinMode(4, OUTPUT);//Set GPIO4 as an input
    digitalWrite(4, 0);
    // prepare GPIO4
    pinMode(4, INPUT);//Set GPIO4 as an input
    delay(50);

}


void loop() {
  my_in = digitalRead(4);//Read GPIO4
  if (my_in)
  {
    Serial.println("Houston, we have a 1!");

    const uint16_t port = 80;
    const char * host = "192.168.4.1"; // Check your IP address of server

    Serial.print("connecting to ");
    Serial.println(host);

    // Use WiFiClient class to create TCP connections
    WiFiClient client;

      if (!client.connect(host, port)) {
        Serial.println("connection failed");
        Serial.println("wait 5 sec...");
        delay(5000);
        return;
      }

    // This will send the request to the server
    client.print("http://server_ip/gpio/1");

    //read back one line from server
    String line = client.readStringUntil('\r');
    client.println(line);

    Serial.println("closing connection");
    client.stop();
    
    Serial.println("wait 5 sec...");
    delay(5000);
  }

  else if (!my_in)
  {
    Serial.println("Meh, it's a 0");
  }
  else
  {
    Serial.println("WTF is this, not 0 or 1...");
  }

  delay(1000);  //wait
}

