//This is our global input variable
//We declare it at the top so it is not "forgotten"
//every time the loop restarts
int my_in = 0;

void setup() {
  Serial.begin(115200);//This sets the serial speed for the monitor
  delay(10);//wait
  // prepare GPIO2
  pinMode(2, INPUT);//Set GPIO2 as an inout

}

void loop() { //This is our loop that runs forever where we will put all of our code
  my_in = digitalRead(2);//Read GPIO2
  if (my_in)
    Serial.println("Houston, we have a 1!");
  else if (!my_in)
    Serial.println("Meh, it's a 0");
  else
    Serial.println("WTF is this, not 0 or 1...");

  delay(1000);  //wait
  

}

