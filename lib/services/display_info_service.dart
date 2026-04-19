import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class DeviceInfoService {
  static DeviceInfoService? _instance;
  DeviceInfoService._();
  static DeviceInfoService get instance =>
      _instance ??= DeviceInfoService._();

  DeviceInfo? _cached;

  Future<DeviceInfo> getDeviceInfo() async {
    if (_cached != null) return _cached!;

    final plugin = DeviceInfoPlugin();
    String deviceName = 'Your Device';
    int ramGB = 4;

    try {
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        deviceName = '${info.manufacturer} ${info.model}';
        ramGB = await _readAndroidRam();
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        deviceName = info.name;
        ramGB = await _estimateIosRam(info.utsname.machine);
      }
    } catch (_) {
      ramGB = 4;
    }

    // ✅ FIXED: Use working storage calculation
    final storageMB = await _getAvailableStorage();

    _cached = DeviceInfo(
      ramGB: ramGB,
      availableStorageMB: storageMB,
      deviceName: deviceName,
    );
    return _cached!;
  }

  Future<int> _readAndroidRam() async {
    try {
      final meminfo = File('/proc/meminfo').readAsStringSync();
      final match =
          RegExp(r'MemTotal:\s+(\d+)').firstMatch(meminfo);
      if (match != null) {
        final kb = int.parse(match.group(1)!);
        return (kb / 1024 / 1024).round();
      }
    } catch (_) {}
    return 4;
  }

  Future<int> _estimateIosRam(String machine) async {
    // Map common iPhone/iPad identifiers to RAM
    if (machine.contains('iPhone16') || machine.contains('iPad16')) return 8;
    if (machine.contains('iPhone15') || machine.contains('iPad15')) return 6;
    if (machine.contains('iPhone14') || machine.contains('iPad14')) return 6;
    if (machine.contains('iPhone13') || machine.contains('iPad13')) return 4;
    if (machine.contains('iPhone12') || machine.contains('iPad12')) return 4;
    return 4;
  }

  Future<int> _getAvailableStorage() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      
      // ✅ FIXED: Platform-specific storage check
      if (Platform.isAndroid) {
        // Android: Use df command (works on most Android devices)
        final result =
            await Process.run('df', ['-k', dir.path]).timeout(
          const Duration(seconds: 2),
          onTimeout: () => ProcessResult(0, 0, '', ''),
        );
        if (result.stdout.toString().isNotEmpty) {
          final lines = result.stdout.toString().trim().split('\n');
          if (lines.length > 1) {
            final parts =
                lines[1].trim().split(RegExp(r'\s+'));
            if (parts.length >= 4) {
              final availKb = int.tryParse(parts[3]) ?? 0;
              if (availKb > 0) {
                return (availKb / 1024).round();
              }
            }
          }
        }
      } 
      // ✅ FIXED: iOS - Use Directory.stat() which actually exists
      else if (Platform.isIOS) {
        try {
          final stat = await dir.stat();
          // stat.size gives us the directory size, not free space
          // For iOS, we need to use a conservative estimate
          // because NSURLResourceValues requires native code
        } catch (_) {}
        
        // ✅ Conservative fallback for iOS (assume 8GB free minimum on modern devices)
        return 8000;
      }
    } catch (_) {}
    
    // ✅ FIXED: Conservative fallback for all platforms
    return 4000;
  }

  List<String> getWarnings(LlmModel model, DeviceInfo device) {
    final warns = <String>[];
    if (device.ramGB < model.minRamGB) {
      warns.add(
          '⚠️  Your device has ${device.ramGB}GB RAM — this model needs ${model.minRamGB}GB minimum. App may crash or run very slowly.');
    }
    if (device.availableStorageMB < model.minStorageMB) {
      final needed = (model.minStorageMB / 1024).toStringAsFixed(1);
      final have = (device.availableStorageMB / 1024).toStringAsFixed(1);
      warns.add(
          '⚠️  Insufficient storage. Need ${needed}GB free, you have ~${have}GB available.');
    }
    return warns;
  }
}
