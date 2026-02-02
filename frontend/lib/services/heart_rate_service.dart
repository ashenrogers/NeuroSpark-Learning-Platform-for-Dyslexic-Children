// lib/services/heart_rate_service.dart
import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../services/bpm_manager.dart';

class HeartRateService {
  // Singleton
  static final HeartRateService instance = HeartRateService._internal();
  HeartRateService._internal();

  final FlutterReactiveBle _ble = FlutterReactiveBle();

  // ⚠️ Make sure these UUIDs match your ESP32 firmware
  // If you changed them on ESP32, update them here too.
  static const String _serviceUuidStr =
      "12345678-1234-1234-1234-1234567890ab"; // SERVICE_UUID in ESP32
  static const String _charUuidStr =
      "abcd1234-5678-1234-5678-1234567890ab"; // CHARACTERISTIC_UUID in ESP32

  final Uuid _serviceUuid = Uuid.parse(_serviceUuidStr);
  final Uuid _charUuid = Uuid.parse(_charUuidStr);

  String? _deviceId;
  StreamSubscription<ConnectionStateUpdate>? _connectionSub;
  StreamSubscription<List<int>>? _notifySub;

  final StreamController<int> _bpmController =
      StreamController<int>.broadcast();

  // Public stream – NEVER null
  Stream<int> get bpmStream => _bpmController.stream;

  bool get isConnected =>
      _lastConnectionState == DeviceConnectionState.connected;

  DeviceConnectionState _lastConnectionState =
      DeviceConnectionState.disconnected;

  /// Ensure we are connected + subscribed to BPM notifications.
  /// Safe to call multiple times.
  Future<void> ensureConnected() async {
    if (isConnected && _notifySub != null) {
      print("🔌 [HR] Already connected to $_deviceId");
      return;
    }

    // If already had a deviceId, try reconnecting to it
    if (_deviceId != null) {
      print("🔌 [HR] Trying to reconnect to $_deviceId ...");
      await _connectToDevice(_deviceId!);
      return;
    }

    // Otherwise scan for the device advertising our HR service UUID
    print("🔍 [HR] Scanning for device with service $_serviceUuidStr ...");

    DiscoveredDevice device;
    try {
      device = await _ble
          .scanForDevices(withServices: [_serviceUuid])
          .timeout(const Duration(seconds: 10))
          .first;
    } on TimeoutException {
      throw Exception("No ESP32 HR device found (scan timeout).");
    } catch (e) {
      throw Exception("BLE scan failed: $e");
    }

    _deviceId = device.id;
    print("✅ [HR] Found device: id=${device.id}, name=${device.name}");

    await _connectToDevice(device.id);
  }

  Future<void> _connectToDevice(String deviceId) async {
    // Close old subscriptions if any
    await _connectionSub?.cancel();
    await _notifySub?.cancel();
    _connectionSub = null;
    _notifySub = null;

    print("🔗 [HR] Connecting to $deviceId ...");

    final connectionStream = _ble.connectToDevice(
      id: deviceId,
      connectionTimeout: const Duration(seconds: 10),
    );

    final completer = Completer<void>();

    _connectionSub = connectionStream.listen(
      (update) {
        _lastConnectionState = update.connectionState;
        print("🔗 [HR] Connection state: ${update.connectionState}");

        if (update.connectionState == DeviceConnectionState.connected &&
            !completer.isCompleted) {
          completer.complete();
        }

        if (update.connectionState == DeviceConnectionState.disconnected) {
          // Let the app decide if/when to reconnect
          _notifySub?.cancel();
          _notifySub = null;
        }
      },
      onError: (e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
    );

    await completer.future;

    // Subscribe to notifications
    final characteristic = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _charUuid,
      deviceId: deviceId,
    );

    print("📡 [HR] Subscribing to BPM characteristic...");

    _notifySub = _ble
        .subscribeToCharacteristic(characteristic)
        .listen(_onNotification, onError: (e) {
      print("⚠️ [HR] Notification error: $e");
    });
  }

  void _onNotification(List<int> data) {
    if (data.isEmpty) return;

    // Assume first byte is BPM (typical HR format or custom simple protocol).
    final int bpm = data[0];

    if (bpm <= 0 || bpm > 220) return; // basic sanity check

    _bpmController.add(bpm);
  }

  /// Called by UI to start background BPM streaming.
  /// This will:
  ///   1. Ensure BLE is connected
  ///   2. Attach BpmManager to the BPM stream
  Future<void> startBackgroundStreaming() async {
    await ensureConnected();
    BpmManager.instance.attachToStream(bpmStream);
  }

  Future<void> dispose() async {
    await _connectionSub?.cancel();
    await _notifySub?.cancel();
    await _bpmController.close();
  }
}
