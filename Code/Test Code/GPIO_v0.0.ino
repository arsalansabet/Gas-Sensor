//This is our global variable toggle
//We declare it at the top so it is not "forgotten"
//every time the loop restarts
int toggle = 0;

void setup() {
  Serial.begin(115200);//This sets the serial speed for the monitor
  delay(10);//wait
  // prepare GPIO2
  pinMode(2, OUTPUT);//Set GPIO2 as an output
  digitalWrite(2, 0);//Initialize GPIO2 as a logic "0"
}

void loop() { //This is our loop that runs forever where we will put all of our code
  
  if (toggle)
    toggle = 0; //If toggle is 1, set to 0
  else
    toggle = 1; //Otherwise set it high

  digitalWrite(2, toggle); //Write variable toggle to GPIO2
  Serial.println("Toggled"); //Print a line saying that pin was toggled
  Serial.println(toggle); //Print the value of the toggle
  delay(1000);  //wait
  

}

