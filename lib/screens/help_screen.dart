import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final List<Map<String, dynamic>> _faqItems = [
    {
      'question': 'Nasıl varlık ekleyebilirim?',
      'answer':
          'Ana ekranda sağ altta bulunan + butonuna tıklayın. Varlık türünü seçin (Hisse, Fon, Altın, Döviz, Nakit), gerekli bilgileri doldurun ve "Ekle" butonuna basın. Varlığınız portföyünüze eklenecektir.',
      'icon': Icons.add_circle_outline,
    },
    {
      'question': 'Varlıklarımı nasıl düzenleyebilirim?',
      'answer':
          'Portföy ekranında düzenlemek istediğiniz varlığa uzun basın veya düzenle ikonuna tıklayın. Açılan ekranda bilgileri güncelleyip kaydedebilirsiniz.',
      'icon': Icons.edit,
    },
    {
      'question': 'Nakit nasıl yönetilir?',
      'answer':
          'Varlık eklerken, sisteminizde bulunan nakit miktarı gösterilir. Yeni varlık eklediğinizde, mevcut nakitinizden otomatik olarak düşüş yapılır. Nakit tükendiğinde nakit varlığı portföyden kaldırılır.',
      'icon': Icons.account_balance_wallet,
    },
    {
      'question': 'Gösterge paneli ne işe yarar?',
      'answer':
          'Gösterge panelinde portföyünüzün genel durumunu, toplam değerini, varlık dağılımını ve performans grafiklerini görüntüleyebilirsiniz. Widget ekleyerek paneli özelleştirebilirsiniz.',
      'icon': Icons.dashboard,
    },
    {
      'question': 'İşlem geçmişini nasıl görüntülerim?',
      'answer':
          'Hamburger menüsünden "İşlem Geçmişi" seçeneğine tıklayarak tüm alım-satım işlemlerinizi tarih sırasına göre görüntüleyebilirsiniz.',
      'icon': Icons.history,
    },
    {
      'question': 'Bildirimler nasıl çalışır?',
      'answer':
          'Bildirimler sayfasında son 2 hafta içindeki önemli olayları görüntüleyebilirsiniz. 2 haftadan eski bildirimler otomatik olarak silinir. Bildirimleri okumak için üzerine tıklayın, silmek için sola kaydırın.',
      'icon': Icons.notifications,
    },
    {
      'question': 'Veri güvenliğim nasıl sağlanıyor?',
      'answer':
          'Tüm verileriniz cihazınızda yerel olarak şifrelenmiş SQLite veritabanında saklanır. Şifreniz güvenli hash algoritması ile korunur ve asla düz metin olarak saklanmaz.',
      'icon': Icons.security,
    },
    {
      'question': 'Hesabımı nasıl silebilirim?',
      'answer':
          'Ayarlar > Hesap Yönetimi bölümünden hesabınızı silebilirsiniz. Bu işlem geri alınamaz ve tüm verileriniz kalıcı olarak silinir.',
      'icon': Icons.delete_forever,
    },
  ];

  final List<Map<String, dynamic>> _contactOptions = [
    {
      'title': 'E-posta',
      'subtitle': 'support@algorist.com',
      'icon': Icons.email,
      'color': Colors.blue,
    },
    {
      'title': 'WhatsApp',
      'subtitle': '+90 555 123 45 67',
      'icon': Icons.chat,
      'color': Colors.green,
    },
    {
      'title': 'Web Sitesi',
      'subtitle': 'www.algorist.com',
      'icon': Icons.language,
      'color': AppColors.primary,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textMainDark),
          onPressed: () => Navigator.pop(context, 'openDrawer'),
        ),
        title: Text(
          'Yardım',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textMainDark,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 24),
          _buildSectionTitle('Sık Sorulan Sorular'),
          const SizedBox(height: 12),
          ..._faqItems.map((item) => _buildFAQItem(item)),
          const SizedBox(height: 24),
          _buildSectionTitle('İletişim'),
          const SizedBox(height: 12),
          ..._contactOptions.map((option) => _buildContactOption(option)),
          const SizedBox(height: 24),
          _buildSupportCard(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.help_outline, size: 40, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            'Size Nasıl Yardımcı Olabiliriz?',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aşağıdaki sık sorulan sorulara göz atın veya bizimle iletişime geçin.',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textMainDark,
      ),
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderDark, width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item['icon'], color: AppColors.primary, size: 24),
          ),
          title: Text(
            item['question'],
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textMainDark,
            ),
          ),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textSecondaryDark,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                item['answer'],
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppColors.textSecondaryDark,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption(Map<String, dynamic> option) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark, width: 1),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: option['color'].withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(option['icon'], color: option['color'], size: 24),
        ),
        title: Text(
          option['title'],
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textMainDark,
          ),
        ),
        subtitle: Text(
          option['subtitle'],
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: AppColors.textSecondaryDark,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppColors.textSecondaryDark,
          size: 16,
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${option['subtitle']} kopyalandı',
                style: GoogleFonts.manrope(),
              ),
              backgroundColor: AppColors.primary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.support_agent, size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            'Daha Fazla Yardıma mı İhtiyacınız Var?',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textMainDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Destek ekibimiz size yardımcı olmak için hazır',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Destek talebi oluşturuldu',
                    style: GoogleFonts.manrope(),
                  ),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Destek Talebi Oluştur',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
