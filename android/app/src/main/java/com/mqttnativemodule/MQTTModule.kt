package com.mqttnativemodule

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.modules.core.DeviceEventManagerModule
import org.eclipse.paho.android.service.MqttAndroidClient
import org.eclipse.paho.client.mqttv3.IMqttActionListener
import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken
import org.eclipse.paho.client.mqttv3.IMqttToken
import org.eclipse.paho.client.mqttv3.MqttCallback
import org.eclipse.paho.client.mqttv3.MqttConnectOptions
import org.eclipse.paho.client.mqttv3.MqttException
import org.eclipse.paho.client.mqttv3.MqttMessage

class MQTTModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext), MqttCallback {

    private lateinit var mqttClient: MqttAndroidClient

    override fun getName(): String {
        return "MQTTModule"
    }

    @ReactMethod
    fun connect(brokerUrl: String, clientId: String, promise: Promise) {
        mqttClient = MqttAndroidClient(reactApplicationContext, brokerUrl, clientId)
        mqttClient.setCallback(this)

        try {
            val options = MqttConnectOptions()
            options.keepAliveInterval = 10
            mqttClient.connect(options, null, object : IMqttActionListener {
                override fun onSuccess(asyncActionToken: IMqttToken) {
                    promise.resolve("Connected to $brokerUrl")
                }

                override fun onFailure(asyncActionToken: IMqttToken, exception: Throwable) {
                    promise.reject("Connection failed", exception)
                }
            })
        } catch (e: MqttException) {
            promise.reject("Connection error", e)
        }
    }

    @ReactMethod
    fun disconnect(promise: Promise) {
        try {
            mqttClient.disconnect()
            promise.resolve("Disconnected")
        } catch (e: MqttException) {
            promise.reject("Disconnection error", e)
        }
    }

    @ReactMethod
    fun reconnect(promise: Promise) {
        if (!::mqttClient.isInitialized) {
            promise.reject("Client not initialized", "MQTT client is not initialized")
            return
        }

        try {
            mqttClient.connect(null, object : IMqttActionListener {
                override fun onSuccess(asyncActionToken: IMqttToken) {
                    promise.resolve("Reconnected")
                }

                override fun onFailure(asyncActionToken: IMqttToken, exception: Throwable) {
                    promise.reject("Reconnection failed", exception)
                }
            })
        } catch (e: MqttException) {
            promise.reject("Reconnection error", e)
        }
    }

    @ReactMethod
    fun subscribe(topic: String, promise: Promise) {
        try {
            mqttClient.subscribe(topic, 0)
            promise.resolve("Subscribed to $topic")
        } catch (e: MqttException) {
            promise.reject("Subscription error", e)
        }
    }

    @ReactMethod
    fun unsubscribe(topic: String, promise: Promise) {
        try {
            mqttClient.unsubscribe(topic)
            promise.resolve("Unsubscribed from $topic")
        } catch (e: MqttException) {
            promise.reject("Unsubscription error", e)
        }
    }

    @ReactMethod
    fun publish(topic: String, message: String, promise: Promise) {
        try {
            val mqttMessage = MqttMessage()
            mqttMessage.payload = message.toByteArray()
            mqttClient.publish(topic, mqttMessage)
            promise.resolve("Message published to $topic")
        } catch (e: MqttException) {
            promise.reject("Publish error", e)
        }
    }

    @ReactMethod
    fun clientId(promise: Promise) {
        if (::mqttClient.isInitialized) {
            val clientId = mqttClient.clientId
            promise.resolve(clientId)
        } else {
            promise.reject("Client not initialized", "MQTT client is not initialized")
        }
    }

    // MqttCallback methods
    override fun connectionLost(cause: Throwable?) {
        val params = Arguments.createMap()
        params.putString("message", cause?.message)
        sendEvent("connectionLost", params)
    }

    override fun messageArrived(topic: String, message: MqttMessage) {
        val params = Arguments.createMap()
        params.putString("topic", topic)
        params.putString("message", String(message.payload))
        sendEvent("messageArrived", params)
    }

    override fun deliveryComplete(token: IMqttDeliveryToken) {
        val params = Arguments.createMap()
        params.putString("messageId", token.messageId.toString())
        sendEvent("deliveryComplete", params)
    }

    private fun sendEvent(eventName: String, params: Any?) {
        reactApplicationContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit(eventName, params)
    }

    @ReactMethod
    fun addListener(eventName: String?) {
        // Keep: Required for RN built in Event Emitter Calls.
    }

    @ReactMethod
    fun removeListeners(count: Int?) {
        // Keep: Required for RN built in Event Emitter Calls.
    }
}