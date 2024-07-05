import React, { useEffect, useState } from 'react';
import {
  // eslint-disable-next-line react-native/split-platform-components
  ToastAndroid,
  NativeModules,
  NativeEventEmitter,
  Text,
  View,
} from 'react-native';
import FormInput from './components/FormInput';
import TextButton from './components/TextButton';

const { MQTTModule } = NativeModules;
const mqttModuleEmitter = new NativeEventEmitter(MQTTModule);

function MqttScreen() {
  const [topic, setTopic] = useState('test/topic');
  const [message, setMessage] = useState('New Message');

  const [connected, setConnected] = useState(false);
  const [messages, setMessages] = useState([]);
  const [connectionStatus, setConnectionStatus] = useState('Not connected');

  useEffect(() => {
    connectMQTT();

    const onConnectionLost = (event) => {
      setConnected(false);
      setConnectionStatus(`Connection lost: ${event.message}`);
    };

    const onMessageArrived = (event) => {
      const message = {
        topic: event.topic,
        message: event.message,
      };
      setMessages((prevMessages) => [...prevMessages, message]);
    };

    const onDeliveryComplete = (event) => {
      console.log(`Message delivery complete: ${event.messageId}`);
    };

    // Adicionar listeners usando NativeEventEmitter
    const connectionLostSubscription = mqttModuleEmitter.addListener(
      'connectionLost',
      onConnectionLost,
    );
    const messageArrivedSubscription = mqttModuleEmitter.addListener(
      'messageArrived',
      onMessageArrived,
    );
    const deliveryCompleteSubscription = mqttModuleEmitter.addListener(
      'deliveryComplete',
      onDeliveryComplete,
    );

    return () => {
      // Remover listeners individualmente
      connectionLostSubscription.remove();
      messageArrivedSubscription.remove();
      deliveryCompleteSubscription.remove();

      // Clean up: Disconnect MQTT on component unmount
      MQTTModule.disconnect()
        .then((response) => console.log(response))
        .catch((error) => console.error(error));
    };
  }, []);

  const connectMQTT = async () => {
    try {
      await MQTTModule.connect('tcp://broker.hivemq.com:1883', 'ReactNative');
      setConnected(true);
      setConnectionStatus('Connected');

      ToastAndroid.show('MQTT Connected', ToastAndroid.SHORT);
      getClientId();
    } catch (error) {
      console.error('Failed to connect to MQTT broker', error);
    }
  };

  const subscribeToTopic = async () => {
    try {
      await MQTTModule.subscribe(topic);
      console.log(`Subscribed to ${topic}`);

      ToastAndroid.show('Subscribed', ToastAndroid.SHORT);
    } catch (error) {
      console.error('Failed to subscribe to topic', error);
    }
  };

  const unsubscribeFromTopic = async () => {
    try {
      await MQTTModule.unsubscribe(topic);
      console.log(`Unsubscribed from ${topic}`);

      ToastAndroid.show('Unsubscribed', ToastAndroid.SHORT);
    } catch (error) {
      console.error('Failed to unsubscribe from topic', error);
    }
  };

  const publishMessage = async () => {
    try {
      await MQTTModule.publish(topic, message);
    } catch (error) {
      console.error('Failed to publish message', error);
    }
  };

  // eslint-disable-next-line no-unused-vars
  const reconnectMQTT = async () => {
    try {
      await MQTTModule.reconnect();
      setConnected(true);
      setConnectionStatus('Reconnected');

      ToastAndroid.show('Reconnected', ToastAndroid.SHORT);
    } catch (error) {
      console.error('Failed to reconnect', error);
    }
  };

  const disconnectMQTT = async () => {
    try {
      await MQTTModule.disconnect();
      setConnected(false);
      setConnectionStatus('Disconnected');

      ToastAndroid.show('Disconnected', ToastAndroid.SHORT);
    } catch (error) {
      console.error('Failed to disconnect', error);
    }
  };

  const getClientId = async () => {
    try {
      const clientId = await MQTTModule.clientId();
      console.log('Client ID:', clientId);
      setConnectionStatus(`Connected: ${clientId}`);
    } catch (error) {
      console.error('Failed to fetch MQTT client ID:', error);
    }
  };

  return (
    <View style={{ paddingHorizontal: 10 }}>
      <Text>{connectionStatus}</Text>

      {/* Connect */}
      <TextButton
        label='Connect MQTT'
        onPress={connectMQTT}
        disabled={connected}
        labelStyle={{
          fontWeight: 'bold',
          color: !connected ? '#fff' : '#9e9e9e',
        }}
        contentContainerStyle={{
          height: 55,
          alignItems: 'center',
          marginTop: 5,
          borderRadius: 12,
          backgroundColor: !connected ? '#3f51b5' : '#e0e0e0',
        }}
      />

      {/* Topic */}
      <FormInput
        label='Topic'
        value={topic}
        onChange={(text) => setTopic(text)}
        containerStyle={{
          marginTop: 12,
        }}
        inputContainerStyle={{
          backgroundColor: '#fff',
        }}
      />

      <View
        style={{
          flex: 1,
          justifyContent: 'center',
          alignItems: 'center',
          marginTop: 10,
        }}
      >
        <View
          style={{
            flexDirection: 'row',
            width: '100%',
            justifyContent: 'space-between',
          }}
        >
          {/* Subscribe */}
          <View
            style={{
              flex: 1,
              marginHorizontal: 5,
            }}
          >
            <TextButton
              label='Subscribe'
              onPress={subscribeToTopic}
              disabled={!connected}
              labelStyle={{
                fontWeight: 'bold',
                color: connected ? '#fff' : '#9e9e9e',
              }}
              contentContainerStyle={{
                height: 55,
                alignItems: 'center',
                justifyContent: 'center',
                borderRadius: 12,
                backgroundColor: connected ? '#3f51b5' : '#e0e0e0',
              }}
            />
          </View>

          {/* Unsubscribe */}
          <View
            style={{
              flex: 1,
              marginHorizontal: 5,
            }}
          >
            <TextButton
              label='Unsubscribe'
              onPress={unsubscribeFromTopic}
              disabled={!connected}
              labelStyle={{
                fontWeight: 'bold',
                color: connected ? '#fff' : '#9e9e9e',
              }}
              contentContainerStyle={{
                height: 55,
                alignItems: 'center',
                justifyContent: 'center',
                borderRadius: 12,
                backgroundColor: connected ? '#3f51b5' : '#e0e0e0',
              }}
            />
          </View>
        </View>
      </View>

      {/* Message */}
      <FormInput
        label='Message'
        value={message}
        onChange={(text) => setMessage(text)}
        containerStyle={{
          marginTop: 12,
        }}
        inputContainerStyle={{
          backgroundColor: '#fff',
        }}
      />

      {/* Publish */}
      <TextButton
        label='Publish'
        onPress={publishMessage}
        disabled={!connected}
        labelStyle={{
          fontWeight: 'bold',
          color: connected ? '#fff' : '#9e9e9e',
        }}
        contentContainerStyle={{
          height: 55,
          alignItems: 'center',
          marginTop: 5,
          borderRadius: 12,
          backgroundColor: connected ? '#3f51b5' : '#e0e0e0',
        }}
      />

      {/* Disconnect */}
      <TextButton
        label='Disconnect'
        onPress={disconnectMQTT}
        disabled={!connected}
        labelStyle={{
          fontWeight: 'bold',
          color: connected ? '#fff' : '#9e9e9e',
        }}
        contentContainerStyle={{
          height: 55,
          alignItems: 'center',
          marginTop: 5,
          borderRadius: 12,
          backgroundColor: connected ? '#f44336' : '#e0e0e0',
        }}
      />

      <Text>Messages:</Text>
      {messages.map((msg, index) => (
        <Text key={index}>
          {msg.topic}: {msg.message}
        </Text>
      ))}
    </View>
  );
}

export default MqttScreen;
