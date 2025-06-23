// lib/services/telegram_service.dart

import 'package:http/http.dart' as http;
import '../models/entry_data.dart';
import 'local_db.dart';
import 'text_export_service.dart';

class TelegramService {
  static const _token = '7743223370:AAEvTi7V4_-FmL2Avb5TMNX0HTCpPn4xGqo';
  static const _chatId = '6870993533';

  /// Отправляет запись в телеграм и помечает её в локальной БД как синхронизированную.
  static Future<bool> sendEntry(EntryData e) async {
    // Always construct the message from current entry data. Using the raw text
    // led to truncated messages when resending saved entries.
    final msg = TextExportService.buildEntryText(e);
    try {
      final res = await http.post(
        Uri.parse('https://api.telegram.org/bot$_token/sendMessage'),
        body: {'chat_id': _chatId, 'text': msg},
      );
      if (res.statusCode == 200) {
        if (e.localId != null) {
          await LocalDb.markSynced(e.localId!);
          e.needsSync = false;
        }
        return true;
      }
    } catch (_) {}
    return false;
  }
}
