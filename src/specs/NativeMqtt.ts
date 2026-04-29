import type {TurboModule} from 'react-native';
import {TurboModuleRegistry} from 'react-native';

export interface Spec extends TurboModule {
  connect(brokerUrl: string, clientId: string): Promise<string>;
  disconnect(): Promise<string>;
  reconnect(): Promise<string>;
  subscribe(topic: string): Promise<string>;
  unsubscribe(topic: string): Promise<string>;
  publish(topic: string, message: string): Promise<string>;
  clientId(): Promise<string>;
  addListener(eventName: string): void;
  removeListeners(count: number): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('MQTTModule');
