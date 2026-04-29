package com.mqttnativemodule

import com.facebook.fbreact.specs.NativeMqttSpec
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.hivemq.client.mqtt.MqttGlobalPublishFilter
import com.hivemq.client.mqtt.datatypes.MqttQos
import com.hivemq.client.mqtt.mqtt3.Mqtt3AsyncClient
import com.hivemq.client.mqtt.mqtt3.Mqtt3Client
import java.net.URI
import java.nio.charset.StandardCharsets

class MQTTModule(reactContext: ReactApplicationContext) : NativeMqttSpec(reactContext) {

    private var mqttClient: Mqtt3AsyncClient? = null
    private var currentClientId: String = ""

    override fun getName() = NAME

    override fun connect(brokerUrl: String, clientId: String, promise: Promise) {
        try {
            val uri = URI(brokerUrl)
            val host = uri.host
            val port = if (uri.port > 0) uri.port else 1883
            currentClientId = clientId

            mqttClient = Mqtt3Client.builder()
                .identifier(clientId)
                .serverHost(host)
                .serverPort(port)
                .buildAsync()

            mqttClient!!.connectWith()
                .send()
                .whenComplete { _, throwable ->
                    if (throwable != null) {
                        promise.reject("Connection failed", throwable)
                    } else {
                        mqttClient!!.publishes(MqttGlobalPublishFilter.ALL) { publish ->
                            val params = Arguments.createMap()
                            params.putString("topic", publish.topic.toString())
                            val payload = publish.payload
                                .map { StandardCharsets.UTF_8.decode(it).toString() }
                                .orElse("")
                            params.putString("message", payload)
                            sendEvent("messageArrived", params)
                        }
                        promise.resolve("Connected to $brokerUrl")
                    }
                }
        } catch (e: Exception) {
            promise.reject("Connection error", e)
        }
    }

    override fun disconnect(promise: Promise) {
        val client = mqttClient ?: run {
            promise.reject("Not connected", "MQTT client is not initialized")
            return
        }
        client.disconnect()
            .whenComplete { _, throwable ->
                if (throwable != null) {
                    promise.reject("Disconnection error", throwable)
                } else {
                    val params = Arguments.createMap()
                    params.putString("message", "Disconnected")
                    sendEvent("connectionLost", params)
                    promise.resolve("Disconnected")
                }
            }
    }

    override fun reconnect(promise: Promise) {
        val client = mqttClient ?: run {
            promise.reject("Client not initialized", "MQTT client is not initialized")
            return
        }
        client.connectWith()
            .send()
            .whenComplete { _, throwable ->
                if (throwable != null) {
                    promise.reject("Reconnection failed", throwable)
                } else {
                    promise.resolve("Reconnected")
                }
            }
    }

    override fun subscribe(topic: String, promise: Promise) {
        val client = mqttClient ?: run {
            promise.reject("Not connected", "MQTT client is not initialized")
            return
        }
        client.subscribeWith()
            .topicFilter(topic)
            .qos(MqttQos.AT_LEAST_ONCE)
            .send()
            .whenComplete { _, throwable ->
                if (throwable != null) {
                    promise.reject("Subscription error", throwable)
                } else {
                    promise.resolve("Subscribed to $topic")
                }
            }
    }

    override fun unsubscribe(topic: String, promise: Promise) {
        val client = mqttClient ?: run {
            promise.reject("Not connected", "MQTT client is not initialized")
            return
        }
        client.unsubscribeWith()
            .topicFilter(topic)
            .send()
            .whenComplete { _, throwable ->
                if (throwable != null) {
                    promise.reject("Unsubscription error", throwable)
                } else {
                    promise.resolve("Unsubscribed from $topic")
                }
            }
    }

    override fun publish(topic: String, message: String, promise: Promise) {
        val client = mqttClient ?: run {
            promise.reject("Not connected", "MQTT client is not initialized")
            return
        }
        client.publishWith()
            .topic(topic)
            .payload(message.toByteArray(StandardCharsets.UTF_8))
            .qos(MqttQos.AT_LEAST_ONCE)
            .send()
            .whenComplete { _, throwable ->
                if (throwable != null) {
                    promise.reject("Publish error", throwable)
                } else {
                    val params = Arguments.createMap()
                    params.putString("messageId", System.currentTimeMillis().toString())
                    sendEvent("deliveryComplete", params)
                    promise.resolve("Message published to $topic")
                }
            }
    }

    override fun clientId(promise: Promise) {
        if (mqttClient != null) {
            promise.resolve(currentClientId)
        } else {
            promise.reject("Client not initialized", "MQTT client is not initialized")
        }
    }

    override fun addListener(eventName: String?) {
        // Required for RN Event Emitter
    }

    override fun removeListeners(count: Double) {
        // Required for RN Event Emitter
    }

    private fun sendEvent(eventName: String, params: Any?) {
        reactApplicationContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit(eventName, params)
    }

    companion object {
        const val NAME = "MQTTModule"
    }
}
