import React, { useEffect, useState } from 'react';
import {
  SafeAreaView,
  ScrollView,
  StatusBar,
  useColorScheme,
  // eslint-disable-next-line react-native/split-platform-components
  ToastAndroid,
  NativeModules,
  NativeEventEmitter,
  Button,
  Text,
  View,
} from 'react-native';
import { Colors } from 'react-native/Libraries/NewAppScreen';

const { MQTTModule } = NativeModules;
const mqttModuleEmitter = new NativeEventEmitter(MQTTModule);

function App() {
  const [connected, setConnected] = useState(false);
  const [messages, setMessages] = useState([]);
  const [connectionStatus, setConnectionStatus] = useState('Not connected');

  const isDarkMode = useColorScheme() === 'dark';

  const backgroundStyle = {
    backgroundColor: isDarkMode ? Colors.darker : Colors.lighter,
  };

  useEffect(() => {
    connectMQTT();

    const onConnectionLost = (event) => {
      setConnected(false);
      setConnectionStatus(`Connection lost: ${event.message}`);
    };

    const onMessageArrived = (event) => {
      // console.log(event);
      if (event.message != 'on') {
        const message = {
          topic: event.topic,
          message: event.message,
        };
        setMessages((prevMessages) => [...prevMessages, message]);
      }
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
      await MQTTModule.subscribe('test/topic');
    } catch (error) {
      console.error('Failed to subscribe to topic', error);
    }
  };

  const unsubscribeFromTopic = async () => {
    try {
      await MQTTModule.unsubscribe('test/topic');
      console.log('Unsubscribed from test/topic');
    } catch (error) {
      console.error('Failed to unsubscribe from topic', error);
    }
  };

  const publishMessage = async () => {
    try {
      await MQTTModule.publish('test/topic', 'New Message');
    } catch (error) {
      console.error('Failed to publish message', error);
    }
  };

  const disconnectMQTT = async () => {
    try {
      await MQTTModule.disconnect();
      setConnected(false);
      setConnectionStatus('Disconnected');
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
    <SafeAreaView style={backgroundStyle}>
      <StatusBar
        barStyle={isDarkMode ? 'light-content' : 'dark-content'}
        backgroundColor={backgroundStyle.backgroundColor}
      />
      <ScrollView
        contentInsetAdjustmentBehavior='automatic'
        style={backgroundStyle}
      >
        <View>
          <Text>{connectionStatus}</Text>
          <Button
            title='Connect MQTT'
            disabled={connected}
            onPress={connectMQTT}
          />
          <Button
            title='Subscribe to Topic'
            disabled={!connected}
            onPress={subscribeToTopic}
          />
          <Button
            title='Unsubscribe from Topic'
            disabled={!connected}
            onPress={unsubscribeFromTopic}
          />
          <Button
            title='Publish Message'
            disabled={!connected}
            onPress={publishMessage}
          />
          <Button
            title='Disconnect'
            disabled={!connected}
            onPress={disconnectMQTT}
          />
          <Text>Messages:</Text>
          {messages.map((msg, index) => (
            <Text key={index}>
              {msg.topic}: {msg.message}
            </Text>
          ))}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

export default App;
