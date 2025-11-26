import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

/// Database Debug Ekranı
/// Güvenli storage'daki tüm kullanıcıları gösterir
class DatabaseDebugScreen extends StatefulWidget {
  const DatabaseDebugScreen({super.key});

  @override
  State<DatabaseDebugScreen> createState() => _DatabaseDebugScreenState();
}

class _DatabaseDebugScreenState extends State<DatabaseDebugScreen> {
  final _secureStorage = const FlutterSecureStorage();
  Map<String, String> _allData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _secureStorage.readAll();
      setState(() {
        _allData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF0A192F)
          : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(
          'Database Debug',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDarkMode ? const Color(0xFF162742) : Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Database Konumu Bilgisi
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Database Konumu',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Platform', 'Android'),
                        _buildInfoRow(
                          'Storage Tipi',
                          'Flutter Secure Storage (EncryptedSharedPreferences)',
                        ),
                        _buildInfoRow(
                          'Konumu',
                          'Android: /data/data/com.example.algorist/shared_prefs/',
                        ),
                        _buildInfoRow(
                          'Şifreleme',
                          'AES-256 (Android Keystore)',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '⚠️ Veriler şifrelenmiş olarak saklanır ve root olmadan erişilemez.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.orange,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Kullanıcı Sayısı
                  Text(
                    'Kayıtlı Kullanıcılar (${_allData.entries.where((e) => e.key.startsWith('user_')).length})',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Kullanıcı Listesi
                  if (_allData.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Henüz kayıtlı kullanıcı yok',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._allData.entries
                        .where((entry) => entry.key.startsWith('user_'))
                        .map(
                          (entry) => _buildUserCard(
                            entry.key,
                            entry.value,
                            isDarkMode,
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(String key, String value, bool isDarkMode) {
    // JSON parse et
    try {
      final email = key.replaceFirst('user_', '');

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF162742) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    email,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veri kopyalandı!')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black26 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
                maxLines: 10,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '🔒 Şifre SHA-256 hash + unique salt ile korunmaktadır',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.green,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}
