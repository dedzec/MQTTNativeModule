import CocoaMQTT
import Foundation

private struct MQTTBrokerConfiguration {
    let host: String
    let port: UInt16
    let displayURL: String

    init(rawBrokerURL: String) throws {
        let trimmedBrokerURL = rawBrokerURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedBrokerURL = trimmedBrokerURL.contains("://") ? trimmedBrokerURL : "tcp://\(trimmedBrokerURL)"

        guard let components = URLComponents(string: normalizedBrokerURL),
              let scheme = components.scheme?.lowercased(),
              ["tcp", "mqtt"].contains(scheme),
              let resolvedHost = components.host,
              !resolvedHost.isEmpty else {
            throw NSError(
                domain: "MQTTModule",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "Invalid broker URL"]
            )
        }

        let resolvedPort = UInt16(components.port ?? 1883)

        host = resolvedHost
        port = resolvedPort
        displayURL = "\(scheme)://\(resolvedHost):\(resolvedPort)"
    }
}

@objc(MQTTModule)
final class MQTTModule: RCTEventEmitter {
    private var mqttClient: CocoaMQTT?
    private var currentClientId = ""
    private var hasListeners = false
    private var pendingConnectResolve: RCTPromiseResolveBlock?
    private var pendingConnectReject: RCTPromiseRejectBlock?
    private var pendingConnectSuccessMessage = "Connected"
    private var pendingConnectErrorCode = "CONNECTION_FAILED"
    private var pendingDisconnectResolve: RCTPromiseResolveBlock?
    private var pendingDisconnectReject: RCTPromiseRejectBlock?

    override static func requiresMainQueueSetup() -> Bool {
        false
    }

    override func supportedEvents() -> [String]! {
        ["messageArrived", "connectionLost", "deliveryComplete"]
    }

    override func startObserving() {
        hasListeners = true
    }

    override func stopObserving() {
        hasListeners = false
    }

    @objc(connect:clientId:resolver:rejecter:)
    func connect(
        _ brokerUrl: String,
        clientId: String,
        resolver resolve: @escaping RCTPromiseResolveBlock,
        rejecter reject: @escaping RCTPromiseRejectBlock
    ) {
        do {
            let configuration = try MQTTBrokerConfiguration(rawBrokerURL: brokerUrl)
            let trimmedClientId = clientId.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !trimmedClientId.isEmpty else {
                reject("INVALID_CLIENT_ID", "Client ID is required", nil)
                return
            }

            mqttClient?.disconnect()

            let client = CocoaMQTT(clientID: trimmedClientId, host: configuration.host, port: configuration.port)
            client.keepAlive = 60
            client.autoReconnect = false
            bindCallbacks(for: client)

            mqttClient = client
            currentClientId = trimmedClientId
            pendingConnectResolve = resolve
            pendingConnectReject = reject
            pendingConnectSuccessMessage = "Connected to \(configuration.displayURL)"
            pendingConnectErrorCode = "CONNECTION_FAILED"

            if !client.connect() {
                clearPendingConnect()
                reject("CONNECTION_FAILED", "Socket connection could not be started", nil)
            }
        } catch {
            reject("CONNECTION_ERROR", error.localizedDescription, error)
        }
    }

    @objc(disconnect:rejecter:)
    func disconnect(
        _ resolve: @escaping RCTPromiseResolveBlock,
        rejecter reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let mqttClient else {
            reject("NOT_CONNECTED", "MQTT client is not initialized", nil)
            return
        }

        pendingDisconnectResolve = resolve
        pendingDisconnectReject = reject
        mqttClient.disconnect()
    }

    @objc(reconnect:rejecter:)
    func reconnect(
        _ resolve: @escaping RCTPromiseResolveBlock,
        rejecter reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let mqttClient else {
            reject("CLIENT_NOT_INITIALIZED", "MQTT client is not initialized", nil)
            return
        }

        pendingConnectResolve = resolve
        pendingConnectReject = reject
        pendingConnectSuccessMessage = "Reconnected"
        pendingConnectErrorCode = "RECONNECTION_FAILED"

        if !mqttClient.connect() {
            clearPendingConnect()
            reject("RECONNECTION_FAILED", "Socket reconnection could not be started", nil)
        }
    }

    @objc(subscribe:resolver:rejecter:)
    func subscribe(
        _ topic: String,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
    ) {
        do {
            let topic = try validatedTopic(topic)
            let mqttClient = try validatedClient()

            mqttClient.subscribe(topic, qos: .qos1)
            resolve("Subscribed to \(topic)")
        } catch {
            reject("SUBSCRIPTION_ERROR", error.localizedDescription, error)
        }
    }

    @objc(unsubscribe:resolver:rejecter:)
    func unsubscribe(
        _ topic: String,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
    ) {
        do {
            let topic = try validatedTopic(topic)
            let mqttClient = try validatedClient()

            mqttClient.unsubscribe(topic)
            resolve("Unsubscribed from \(topic)")
        } catch {
            reject("UNSUBSCRIPTION_ERROR", error.localizedDescription, error)
        }
    }

    @objc(publish:message:resolver:rejecter:)
    func publish(
        _ topic: String,
        message: String,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
    ) {
        do {
            let topic = try validatedTopic(topic)
            let mqttClient = try validatedClient()

            _ = mqttClient.publish(topic, withString: message, qos: .qos1, retained: false)
            resolve("Message published to \(topic)")
        } catch {
            reject("PUBLISH_ERROR", error.localizedDescription, error)
        }
    }

    @objc(clientId:rejecter:)
    func clientId(
        _ resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
    ) {
        guard mqttClient != nil else {
            reject("CLIENT_NOT_INITIALIZED", "MQTT client is not initialized", nil)
            return
        }

        resolve(currentClientId)
    }

    private func bindCallbacks(for client: CocoaMQTT) {
        client.didConnectAck = { [weak self] _, ack in
            guard let self else { return }

            if ack == .accept {
                self.pendingConnectResolve?(self.pendingConnectSuccessMessage)
                self.clearPendingConnect()
            } else {
                let message = "Connection rejected: \(ack.description)"
                self.pendingConnectReject?(self.pendingConnectErrorCode, message, nil)
                self.clearPendingConnect()
            }
        }

        client.didReceiveMessage = { [weak self] _, message, _ in
            guard let self else { return }

            let payload = message.string ?? String(data: Data(message.payload), encoding: .utf8) ?? ""
            self.emitEvent(name: "messageArrived", body: [
                "topic": message.topic,
                "message": payload,
            ])
        }

        client.didPublishAck = { [weak self] _, messageId in
            self?.emitEvent(name: "deliveryComplete", body: [
                "messageId": String(messageId),
            ])
        }

        client.didDisconnect = { [weak self] _, error in
            guard let self else { return }

            let message = error?.localizedDescription ?? "Disconnected"
            self.emitEvent(name: "connectionLost", body: ["message": message])

            if let error {
                self.pendingDisconnectReject?("DISCONNECTION_ERROR", error.localizedDescription, error)
            } else {
                self.pendingDisconnectResolve?("Disconnected")
            }

            self.pendingDisconnectResolve = nil
            self.pendingDisconnectReject = nil
        }
    }

    private func validatedClient() throws -> CocoaMQTT {
        guard let mqttClient else {
            throw NSError(
                domain: "MQTTModule",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "MQTT client is not initialized"]
            )
        }

        return mqttClient
    }

    private func validatedTopic(_ topic: String) throws -> String {
        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTopic.isEmpty else {
            throw NSError(
                domain: "MQTTModule",
                code: 1003,
                userInfo: [NSLocalizedDescriptionKey: "Topic is required"]
            )
        }

        return trimmedTopic
    }

    private func emitEvent(name: String, body: [String: String]) {
        guard hasListeners else {
            return
        }

        sendEvent(withName: name, body: body)
    }

    private func clearPendingConnect() {
        pendingConnectResolve = nil
        pendingConnectReject = nil
        pendingConnectSuccessMessage = "Connected"
        pendingConnectErrorCode = "CONNECTION_FAILED"
    }
}