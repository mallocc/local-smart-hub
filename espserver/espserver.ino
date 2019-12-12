#include "ESP8266WiFi.h"
#include "ESP8266WebServer.h"
#include <ESP8266HTTPClient.h>
#include <sstream>

 #define ledPin 2
ESP8266WebServer server(80);
WiFiClient client;
HTTPClient http;

bool lightOn = true;

char host[] = "192.168.150.1";
int port = 8000;


bool sendConnectionRequest()
{
  String json = "{\"name\":\"esp2\"}";  
  String url = "/connect?id=" + json;

  bool success = false;

  http.begin(host,port,url);
  int httpCode = http.GET();
  if (httpCode) {
    if (httpCode == 200) {
      String payload = http.getString();
      Serial.println(payload);
      success = payload == "connected";        
    }
  }
  Serial.println("closing connection");
  http.end();

  return success;
}

void tryConnection()
{
  while (!sendConnectionRequest());
}

void setup() {
 
  Serial.begin(115200);

  pinMode(ledPin,OUTPUT);
  analogWrite(ledPin,1000 * lightOn);
    
  WiFi.begin("MyNetwork", "");  //Connect to the WiFi network
 
  while (WiFi.status() != WL_CONNECTED) {  //Wait for connection
 
    delay(500);
    Serial.println("Waiting to connect…");
 
  }
 
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());  //Print the local IP
 
  server.on("/other", []() {   //Define the handling function for the path
 
    server.send(200, "text / plain", "Other URL");
 
  });
 
  server.on("/", handleRootPath);    //Associate the handler function to the path
  server.on("/alive", handleAliveRequest);
  server.begin();                    //Start the server
  Serial.println("Server listening...");

  Serial.println("Aquiring connection...");
  tryConnection();
}
 
void loop() {
 
  server.handleClient();         //Handling of incoming requests
 
}

void handleAliveRequest()
{
  std::stringstream ss;
  ss << "{ \"alive\": \"" << "TRUE" << "\" }";
  server.send(200, "text/plain", ss.str().c_str());
    Serial.println("Received request ALIVE");
}

void handleRootPath() {            //Handler for the rooth path

  std::stringstream ss;

  ss << "{ \"onState\": \"" << (lightOn ? "ON" : "OFF") << "\" }";
  
  server.send(200, "text/plain", ss.str().c_str());
  Serial.println("Received GET request");
  lightOn = !lightOn;
  analogWrite(ledPin,1000 * lightOn);  
  
}
