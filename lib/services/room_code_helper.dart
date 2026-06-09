class RoomCodeHelper {
  /// Encodes an IPv4 address string (e.g. "10.0.2.16") to an 8-character hex code (e.g. "0A000210").
  static String encodeIp(String ip) {
    if (ip == '127.0.0.1' || ip.toLowerCase().contains('localhost') || ip.toLowerCase().contains('local')) {
      return 'LOBBY127';
    }
    
    try {
      final parts = ip.split('.');
      if (parts.length != 4) return 'LOBBY127';
      
      final hexParts = parts.map((part) {
        final val = int.parse(part);
        return val.toRadixString(16).padLeft(2, '0').toUpperCase();
      });
      
      return hexParts.join('');
    } catch (e) {
      return 'LOBBY127';
    }
  }

  /// Decodes an 8-character hex code (e.g. "0A000210") back to an IPv4 address string.
  static String decodeIp(String code) {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode == 'LOBBY127' || cleanCode.length != 8) {
      return '127.0.0.1';
    }

    try {
      final List<String> parts = [];
      for (int i = 0; i < 8; i += 2) {
        final hex = cleanCode.substring(i, i + 2);
        final val = int.parse(hex, radix: 16);
        parts.add(val.toString());
      }
      return parts.join('.');
    } catch (e) {
      return '127.0.0.1';
    }
  }
}
