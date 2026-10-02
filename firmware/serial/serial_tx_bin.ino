// Example: using timer for ADC
// Connection: PIN 4 --> ADC1
// Connection: PIN 35 --> ADC2
// Connection: PIN 36 --> ADC3

#define PIN_SIGNAL_1 4
#define PIN_SIGNAL_2 5
#define PIN_SIGNAL_3 6


hw_timer_t *timer = NULL;
volatile bool flag = false;
uint16_t cnt = 0;
String cmd = "";

uint16_t val1_cnt = 0;
uint16_t val2_adc = 0;
uint16_t val3_adc = 0;
uint16_t val4_adc = 0;


// callback function when the timer alarms:
void timer_isr() {
  flag = true;
}

void setup() {
  Serial.begin(921600);

  pinMode(PIN_SIGNAL_1, INPUT);
  pinMode(PIN_SIGNAL_2, INPUT);
  pinMode(PIN_SIGNAL_3, INPUT);

  //setup the timer:
  timer = timerBegin(1000000);              //timer 1Mhz resolution
  timerAttachInterrupt(timer, &timer_isr);  //attach callback
  timerAlarm(timer, 1000, true, 0);        //set time in us
//   timerStop(timer);
  Serial.println("Ready.");
}

void loop() {
  cmd = "";

  if (Serial.available() > 0) {
	cmd = Serial.readStringUntil('\n');
  }
  if (cmd != "") {
	//Serial.println("Serial got cmd: " + cmd);
	if (cmd.indexOf("start") != -1)
	  timerStart(timer);
	if (cmd.indexOf("stop") != -1)
	  timerStop(timer);
  }
  if (flag) {
	flag = false;

	//----A 采集数据-----
	cnt++;
	if (cnt>=256){
		cnt = 0;
	}
	val1_cnt = cnt;
	val2_adc = analogRead(PIN_SIGNAL_1);
    val3_adc = analogRead(PIN_SIGNAL_2); // <--- 读取 GPIO 9
    val4_adc = analogRead(PIN_SIGNAL_3); // <--- 读取 GPIO 11

	//----B 发送数据----
	//协议总长10字节[13，10，data*4]

	//1. 发送帧头(CR LF)
	Serial.write(13);
	Serial.write(10);

	//2. 发送4个数据
	Serial.write((const uint8_t*)&val1_cnt, 2);
	Serial.write((const uint8_t *)&val2_adc, 2);
    Serial.write((const uint8_t *)&val3_adc, 2);
    Serial.write((const uint8_t *)&val4_adc, 2);
	//Serial.println();


  }
}
