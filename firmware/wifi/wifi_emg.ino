#include <WiFi.h>
#include <WebSocketsServer.h>

// ================== 用户配置 ==================
const char *ssid = "ESP32-EMG-Host";  // 热点名称
const char *password = "12345678";    // 热点密码
const int SAMPLE_RATE_HZ = 1000;      // 目标采样率 1000Hz
const int BATCH_SIZE = 25;            // 每包包含的采样点数 (25个点发一次包)

// ================== 引脚定义 ==================
const int PIN_CH1 = 4;
const int PIN_CH2 = 5;
const int PIN_CH3 = 6;

// ================== 数据结构 ==================
// 必须与前端解析一致，单点占用 8 字节
// __attribute__((packed)) 防止编译器进行内存对齐填充
struct __attribute__((packed)) DataPoint {
    uint16_t cnt;    // 2 bytes
    uint16_t val1;   // 2 bytes
    uint16_t val2;   // 2 bytes
    uint16_t val3;   // 2 bytes
};

// 数据缓冲区
DataPoint dataBuffer[BATCH_SIZE];
int bufferIndex = 0;
uint16_t globalPacketCounter = 0;
unsigned long lastSampleTime = 0;
unsigned long sampleInterval = 1000000 / SAMPLE_RATE_HZ; // 1000us = 1ms

// WebSocket 服务器运行在 81 端口
WebSocketsServer webSocket = WebSocketsServer(81);

void setup() {
    Serial.begin(115200);

    // 1. 设置 WiFi 热点 (AP模式)
    WiFi.softAP(ssid, password);
    Serial.println();
    Serial.print("IP Address: ");
    Serial.println(WiFi.softAPIP());

    // 2. 启动 WebSocket
    webSocket.begin();
    webSocket.onEvent(webSocketEvent);
    Serial.println("WebSocket Server Started");

    // 3. 配置 ADC (根据需要调整衰减，这里默认 11db 可以读 0-3.3V)
    analogSetAttenuation(ADC_11db);
}

void loop() {
    webSocket.loop();

    unsigned long now = micros();

    // 非阻塞式精确定时采样
    if (now - lastSampleTime >= sampleInterval) {
        lastSampleTime = now;

        // 1. 采集数据
        dataBuffer[bufferIndex].cnt = globalPacketCounter++;
        dataBuffer[bufferIndex].val1 = analogRead(PIN_CH1);
        dataBuffer[bufferIndex].val2 = analogRead(PIN_CH2);
        dataBuffer[bufferIndex].val3 = analogRead(PIN_CH3);

        bufferIndex++;

        // 2. 缓冲区满，发送数据
        if (bufferIndex >= BATCH_SIZE) {
            // 将整个结构体数组作为二进制发送
            // 大小 = 25 * 8 = 200 字节
            webSocket.broadcastBIN((uint8_t*)dataBuffer, sizeof(dataBuffer));

            // 重置索引
            bufferIndex = 0;
        }
    }
}

// WebSocket 事件回调
void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length) {
    switch(type) {
        case WStype_DISCONNECTED:
            Serial.printf("[%u] Disconnected!\n", num);
            break;
        case WStype_CONNECTED:
            {
                IPAddress ip = webSocket.remoteIP(num);
                Serial.printf("[%u] Connected from %d.%d.%d.%d\n", num, ip[0], ip[1], ip[2], ip[3]);
            }
            break;
    }
}