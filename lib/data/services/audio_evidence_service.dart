import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Audio attached to a report. When the microphone is allowed this is a real
/// recording of the countdown (live capture ported from the `new-branch` work
/// by BigzPh). Otherwise it is a generated placeholder tone, and the report
/// says which of the two it carries.
class AudioEvidenceService {
  static const int defaultSampleRate = 16000;
  static const int channels = 1;
  static const int bitsPerSample = 16;

  /// Recordings use the phone's own 48 kHz rate. On the simulator, speech
  /// recognition (the voice trigger) answered "corrupt" whenever the input
  /// ran at 16 kHz, and asking iOS for 16 kHz changes the shared audio
  /// session. The cost is size: about 96 KB per second of WAV.
  /// ponytail: one knob; drop to 16000 if uploads prove too slow and a real
  /// phone's voice trigger survives it.
  static const int recordingSampleRate = 48000;

  static AudioRecorder? _recorder;
  static String? _path;
  static bool _recording = false;
  static Timer? _cap;

  /// Whether recording is allowed. With [ask] false no dialog is shown, so
  /// it is safe to call while an alert is counting down.
  static Future<bool> hasPermission({bool ask = false}) async {
    try {
      return await (_recorder ??= AudioRecorder()).hasPermission(request: ask);
    } catch (_) {
      _recorder = null;
      return false;
    }
  }

  /// Starts recording to a temporary file. Returns false, and records
  /// nothing, when the microphone is not allowed or not available. The
  /// recording stops by itself after [max] so a forgotten alert cannot fill
  /// the phone.
  static Future<bool> start({
    Duration max = const Duration(seconds: 15),
  }) async {
    try {
      if (!await hasPermission()) return false;
      await cancel();
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/dinig_evidence_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _recorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: recordingSampleRate,
          numChannels: channels,
        ),
        path: path,
      );
      _path = path;
      _recording = true;
      _cap = Timer(max, () async {
        if (!_recording) return;
        _recording = false;
        try {
          await _recorder?.stop();
        } catch (_) {}
      });
      return true;
    } catch (e) {
      debugPrint('AudioEvidenceService: recording did not start: $e');
      _recording = false;
      return false;
    }
  }

  /// Ends the recording and returns its bytes, or null when nothing was
  /// recorded. The temporary file is deleted either way.
  static Future<Uint8List?> stop() async {
    _cap?.cancel();
    final path = _path;
    _path = null;
    try {
      if (_recording) await _recorder?.stop();
    } catch (_) {}
    _recording = false;
    if (path == null) return null;
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      await file.delete();
      // Under half a second of sound is not a recording worth sending.
      return wavDataBytes(bytes) >= recordingSampleRate ? bytes : null;
    } catch (_) {
      return null;
    }
  }

  /// How many bytes of sound a WAV file holds. iOS writes a 4,096-byte
  /// header, so a file can look sizeable and still contain nothing.
  static int wavDataBytes(Uint8List bytes) {
    const d = 0x64, a = 0x61, t = 0x74; // "data"
    for (var i = 12; i + 8 <= bytes.length && i < 8192; i++) {
      if (bytes[i] == d &&
          bytes[i + 1] == a &&
          bytes[i + 2] == t &&
          bytes[i + 3] == a) {
        return bytes.length - (i + 8);
      }
    }
    return 0;
  }

  /// Throws the recording away: the alert was cancelled, so nothing is kept.
  static Future<void> cancel() async {
    await stop();
  }

  /// Builds a valid 16kHz mono 16-bit PCM RIFF WAV (5 seconds by default) of
  /// synthesized tone and noise. It is not a recording of anything.
  static Uint8List generateEmergencyWavClip({
    int durationSeconds = 5,
    int sampleRate = defaultSampleRate,
  }) {
    final bytesPerSample = bitsPerSample ~/ 8;
    final bytesPerSecond = sampleRate * channels * bytesPerSample;
    final totalAudioBytes = bytesPerSecond * durationSeconds;
    final totalDataLen = totalAudioBytes + 36;

    final buffer = Uint8List(44 + totalAudioBytes);
    final byteData = ByteData.view(buffer.buffer);

    // 1. RIFF Chunk Descriptor
    buffer.setRange(0, 4, 'RIFF'.codeUnits);
    byteData.setUint32(4, totalDataLen, Endian.little);
    buffer.setRange(8, 12, 'WAVE'.codeUnits);

    // 2. fmt Sub-chunk
    buffer.setRange(12, 16, 'fmt '.codeUnits);
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    byteData.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
    byteData.setUint16(22, channels, Endian.little); // NumChannels (1 = Mono)
    byteData.setUint32(24, sampleRate, Endian.little); // SampleRate (16,000 Hz)
    byteData.setUint32(28, bytesPerSecond, Endian.little); // ByteRate (32,000 B/s)
    byteData.setUint16(32, channels * bytesPerSample, Endian.little); // BlockAlign (2)
    byteData.setUint16(34, bitsPerSample, Endian.little); // BitsPerSample (16)

    // 3. data Sub-chunk
    buffer.setRange(36, 40, 'data'.codeUnits);
    byteData.setUint32(40, totalAudioBytes, Endian.little);

    // 4. Synthesize the placeholder waveform (noise + harmonics)
    final numSamples = sampleRate * durationSeconds;
    final random = Random(42);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final noise = (random.nextDouble() - 0.5) * 400.0;
      final vocal = sin(2 * pi * 440 * t) * 650.0 * (1.0 + 0.4 * sin(2 * pi * 5 * t));
      final sampleVal = (noise + vocal).clamp(-32768.0, 32767.0).toInt();

      byteData.setInt16(44 + (i * 2), sampleVal, Endian.little);
    }

    return buffer;
  }
}
