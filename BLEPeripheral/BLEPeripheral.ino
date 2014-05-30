/*********************************************************************
This is an example for our nRF8001 Bluetooth Low Energy Breakout

  Pick one up today in the adafruit shop!
  ------> http://www.adafruit.com/products/1697

Adafruit invests time and resources providing this open source code, 
please support Adafruit and open-source hardware by purchasing 
products from Adafruit!

Written by Kevin Townsend/KTOWN  for Adafruit Industries.
MIT license, check LICENSE for more information
All text above, and the splash screen below must be included in any redistribution
*********************************************************************/

// This version uses the internal data queing so you can treat it like Serial (kinda)!

#include <SPI.h>
#include "Adafruit_BLE_UART.h"
//#include "Waveforms.h"

// Connect CLK/MISO/MOSI to hardware SPI
// e.g. On UNO & compatible: CLK = 13, MISO = 12, MOSI = 11
#define ADAFRUITBLE_REQ 10
#define ADAFRUITBLE_RDY 2     // This should be an interrupt pin, on Uno thats #2 or #3
#define ADAFRUITBLE_RST 9

#define RED_LED 3
#define GRN_LED 4

Adafruit_BLE_UART BTLEserial = Adafruit_BLE_UART(ADAFRUITBLE_REQ, ADAFRUITBLE_RDY, ADAFRUITBLE_RST);
/**************************************************************************/
/*!
    Configure the Arduino and start advertising with the radio
*/
/**************************************************************************/

uint8_t sendbuffer[20];
int probe;
int prev_val;

void setup(void)
{ 
  probe = 0;
  prev_val = -1;
  Serial.begin(9600);
  pinMode(RED_LED, OUTPUT);
  pinMode(GRN_LED, OUTPUT);
  while(!Serial); // Leonardo/Micro should wait for serial init
  Serial.println(F("Adafruit Bluefruit Low Energy nRF8001 Print echo demo"));  
  BTLEserial.begin();
}

/**************************************************************************/
/*!
    Constantly checks for new events on the nRF8001
*/
/**************************************************************************/
aci_evt_opcode_t laststatus = ACI_EVT_DISCONNECTED;

void loop()
{
  // Tell the nRF8001 to do whatever it should be working on.
  BTLEserial.pollACI();

  // Ask what is our current status
  aci_evt_opcode_t status = BTLEserial.getState();
  // If the status changed....
  if (status != laststatus) {
    // print it out!
    if (status == ACI_EVT_DEVICE_STARTED) {
        Serial.println(F("* Advertising started"));
    }
    if (status == ACI_EVT_CONNECTED) 
    {
        Serial.println(F("* Connected!"));
    }
    if (status == ACI_EVT_DISCONNECTED) {
        Serial.println(F("* Disconnected or advertising timed out"));
    }
    // OK set the last status change to this one
    laststatus = status;
  }

  if (status == ACI_EVT_CONNECTED) {
    // Lets see if there's any data for us!
    if (BTLEserial.available()) {
      Serial.print("* "); Serial.print(BTLEserial.available()); Serial.println(F(" bytes available from BTLE"));
    }
    // OK while we still have something to read, get a character and print it out
    int i = 0;
    char recv_buf[20] = "";
    while (BTLEserial.available()) {
      char c = BTLEserial.read();
        recv_buf[i] = c;
      Serial.print(recv_buf[i]);
      Serial.print(" (");
      Serial.print(recv_buf[i], DEC);
      Serial.print(") ");
      i++;
    }
    recv_buf[i] = '\0';
    String str(recv_buf);
    
     if(str.equals("RED_ON"))
      {
        Serial.println("OK FOR RED HIGH");
            digitalWrite(RED_LED, HIGH);
      }
      else if(str.equals("RED_OFF"))
      {
        Serial.println("OK FOR RED LOW");
            digitalWrite(RED_LED, LOW);
      }
      else if(str.equals("GRN_ON"))
      {
        Serial.println("OK FOR GREEN HIGH");
            digitalWrite(GRN_LED, HIGH);
      }
      else if(str.equals("GRN_OFF"))
      {
        Serial.println("OK FOR GREEN LOW");
            digitalWrite(GRN_LED, LOW);
      }
      
      if(str.equals("BEGIN_TX") || probe == 1)
      {
          int val = analogRead(A0);
          if(val != prev_val)
          {
            probe = 1;
            prev_val = val;
            String tmp = String(val, DEC);
            Serial.println(tmp);
            uint8_t sendbuffer[20];
            tmp.getBytes(sendbuffer, 20);
            BTLEserial.write(sendbuffer, tmp.length());
          }
      }
    }
  
}
