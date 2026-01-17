// Aylık ve bölgesel tarım önerileri
import 'package:flutter/material.dart';

class RecommendationsData {
  // Aylık genel tarım önerileri
  static List<Map<String, dynamic>> getMonthlyRecommendations(int month, String? cityName) {
    final recommendations = _monthlyRecommendations[month] ?? [];
    return recommendations;
  }

  static final Map<int, List<Map<String, dynamic>>> _monthlyRecommendations = {
    1: [ // Ocak
      {
        'icon': Icons.ac_unit,
        'title': 'Don Koruması',
        'description': 'Fidelerinizi dondan koruyun, örtü malzemesi kullanın',
        'color': Colors.blue,
      },
      {
        'icon': Icons.home_outlined,
        'title': 'Sera Bakımı',
        'description': 'Sera sıcaklığını kontrol edin, havalandırma yapın',
        'color': Colors.green,
      },
      {
        'icon': Icons.build_outlined,
        'title': 'Ekipman Bakımı',
        'description': 'Tarım aletlerinizi kontrol edin ve bakımını yapın',
        'color': Colors.orange,
      },
    ],
    2: [ // Şubat
      {
        'icon': Icons.grass,
        'title': 'Toprak Hazırlığı',
        'description': 'İlkbahar ekimi için toprağı hazırlamaya başlayın',
        'color': Colors.brown,
      },
      {
        'icon': Icons.water_drop,
        'title': 'Sulama Sistemi',
        'description': 'Sulama sistemlerini kontrol edin ve onarın',
        'color': Colors.blue,
      },
      {
        'icon': Icons.science_outlined,
        'title': 'Toprak Analizi',
        'description': 'Toprak analizi yaptırın, gübre ihtiyacını belirleyin',
        'color': Colors.purple,
      },
    ],
    3: [ // Mart
      {
        'icon': Icons.wb_sunny,
        'title': 'İlkbahar Ekimi',
        'description': 'Hava ısınmaya başladı, ilkbahar ekimlerine başlayın',
        'color': Colors.orange,
      },
      {
        'icon': Icons.pest_control,
        'title': 'Zararlı Kontrolü',
        'description': 'Zararlılara karşı önlem alın, organik yöntemler kullanın',
        'color': Colors.red,
      },
      {
        'icon': Icons.compost,
        'title': 'Gübreleme',
        'description': 'Organik gübre ile toprağı zenginleştirin',
        'color': Colors.green,
      },
    ],
    4: [ // Nisan
      {
        'icon': Icons.local_florist,
        'title': 'Fide Dikimi',
        'description': 'Sera fidelerini açık alana dikmeye başlayın',
        'color': Colors.pink,
      },
      {
        'icon': Icons.water_drop,
        'title': 'Düzenli Sulama',
        'description': 'Hava ısındı, sulama sıklığını artırın',
        'color': Colors.blue,
      },
      {
        'icon': Icons.bug_report,
        'title': 'Hastalık Takibi',
        'description': 'Bitki hastalıklarını erken tespit edin',
        'color': Colors.orange,
      },
    ],
    5: [ // Mayıs
      {
        'icon': Icons.wb_sunny,
        'title': 'Sıcak Hava',
        'description': 'Sıcak havalarda sabah erken sulama yapın',
        'color': Colors.orange,
      },
      {
        'icon': Icons.grass,
        'title': 'Yabani Ot',
        'description': 'Yabani otları düzenli olarak temizleyin',
        'color': Colors.green,
      },
      {
        'icon': Icons.support,
        'title': 'Destek Çubukları',
        'description': 'Domates, biber gibi bitkilere destek verin',
        'color': Colors.brown,
      },
    ],
    6: [ // Haziran
      {
        'icon': Icons.water_drop,
        'title': 'Bol Sulama',
        'description': 'Yaz sıcağında günde 2 kez sulama yapın',
        'color': Colors.blue,
      },
      {
        'icon': Icons.cut,
        'title': 'Budama',
        'description': 'Gereksiz sürgünleri budayın, meyve kalitesini artırın',
        'color': Colors.green,
      },
      {
        'icon': Icons.agriculture,
        'title': 'İlk Hasat',
        'description': 'Erken sebzelerin hasadına başlayın',
        'color': Colors.orange,
      },
    ],
    7: [ // Temmuz
      {
        'icon': Icons.wb_sunny,
        'title': 'Aşırı Sıcak',
        'description': 'Gölgeleme yapın, bitkileri aşırı güneşten koruyun',
        'color': Colors.red,
      },
      {
        'icon': Icons.water_drop,
        'title': 'Damla Sulama',
        'description': 'Su tasarrufu için damla sulama kullanın',
        'color': Colors.blue,
      },
      {
        'icon': Icons.shopping_basket,
        'title': 'Hasat Zamanı',
        'description': 'Yaz sebzelerini zamanında hasat edin',
        'color': Colors.green,
      },
    ],
    8: [ // Ağustos
      {
        'icon': Icons.agriculture,
        'title': 'Hasat Devam',
        'description': 'Yaz ürünlerinin hasadını tamamlayın',
        'color': Colors.orange,
      },
      {
        'icon': Icons.grass,
        'title': 'Sonbahar Hazırlığı',
        'description': 'Sonbahar ekimi için toprak hazırlığına başlayın',
        'color': Colors.brown,
      },
      {
        'icon': Icons.compost,
        'title': 'Kompost',
        'description': 'Hasat artıklarından kompost yapın',
        'color': Colors.green,
      },
    ],
    9: [ // Eylül
      {
        'icon': Icons.grass,
        'title': 'Sonbahar Ekimi',
        'description': 'Kışlık buğday, arpa ekimini yapın',
        'color': Colors.brown,
      },
      {
        'icon': Icons.thermostat,
        'title': 'Sıcaklık Takibi',
        'description': 'Hava serinliyor, don riskine dikkat edin',
        'color': Colors.blue,
      },
      {
        'icon': Icons.cleaning_services,
        'title': 'Sera Temizliği',
        'description': 'Seraları temizleyin ve dezenfekte edin',
        'color': Colors.purple,
      },
    ],
    10: [ // Ekim
      {
        'icon': Icons.ac_unit,
        'title': 'Don Hazırlığı',
        'description': 'İlk donlara karşı önlem alın',
        'color': Colors.blue,
      },
      {
        'icon': Icons.grass,
        'title': 'Kışlık Ekim',
        'description': 'Kışlık tahıl ve baklagil ekimini tamamlayın',
        'color': Colors.brown,
      },
      {
        'icon': Icons.build_outlined,
        'title': 'Ekipman Depolama',
        'description': 'Kullanılmayan ekipmanları temizleyip depolayın',
        'color': Colors.grey,
      },
    ],
    11: [ // Kasım
      {
        'icon': Icons.home_outlined,
        'title': 'Sera Kurulumu',
        'description': 'Kış için sera ve tünelleri hazırlayın',
        'color': Colors.green,
      },
      {
        'icon': Icons.compost,
        'title': 'Organik Gübre',
        'description': 'Toprağa organik gübre karıştırın',
        'color': Colors.brown,
      },
      {
        'icon': Icons.menu_book,
        'title': 'Planlama',
        'description': 'Gelecek sezon için ekim planı yapın',
        'color': Colors.blue,
      },
    ],
    12: [ // Aralık
      {
        'icon': Icons.ac_unit,
        'title': 'Kış Koruması',
        'description': 'Bitkileri kış soğuğundan koruyun',
        'color': Colors.blue,
      },
      {
        'icon': Icons.home_outlined,
        'title': 'Sera Isıtma',
        'description': 'Sera sıcaklığını kontrol altında tutun',
        'color': Colors.red,
      },
      {
        'icon': Icons.school_outlined,
        'title': 'Eğitim',
        'description': 'Kış aylarında tarım eğitimlerine katılın',
        'color': Colors.purple,
      },
    ],
  };
}
