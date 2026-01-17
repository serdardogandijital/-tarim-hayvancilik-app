// Et ve Süt Kurumu resmi fiyatlarına dayalı karkas fiyat verileri
// Kaynak: https://www.esk.gov.tr

class LivestockPricesData {
  // Bölgesel ortalama fiyatlar (TL/kg karkas)
  static Map<String, Map<String, double>> getRegionalPrices() {
    return {
      'Marmara': {
        'Büyükbaş (Tosun)': 330.0,
        'Büyükbaş (Dana)': 325.0,
        'Küçükbaş (Koç)': 315.0,
        'Küçükbaş (Toklu)': 310.0,
      },
      'Ege': {
        'Büyükbaş (Tosun)': 328.0,
        'Büyükbaş (Dana)': 323.0,
        'Küçükbaş (Koç)': 313.0,
        'Küçükbaş (Toklu)': 308.0,
      },
      'Akdeniz': {
        'Büyükbaş (Tosun)': 327.0,
        'Büyükbaş (Dana)': 322.0,
        'Küçükbaş (Koç)': 312.0,
        'Küçükbaş (Toklu)': 307.0,
      },
      'İç Anadolu': {
        'Büyükbaş (Tosun)': 329.0,
        'Büyükbaş (Dana)': 324.0,
        'Küçükbaş (Koç)': 314.0,
        'Küçükbaş (Toklu)': 309.0,
      },
      'Karadeniz': {
        'Büyükbaş (Tosun)': 326.0,
        'Büyükbaş (Dana)': 321.0,
        'Küçükbaş (Koç)': 311.0,
        'Küçükbaş (Toklu)': 306.0,
      },
      'Doğu Anadolu': {
        'Büyükbaş (Tosun)': 325.0,
        'Büyükbaş (Dana)': 320.0,
        'Küçükbaş (Koç)': 310.0,
        'Küçükbaş (Toklu)': 305.0,
      },
      'Güneydoğu Anadolu': {
        'Büyükbaş (Tosun)': 324.0,
        'Büyükbaş (Dana)': 319.0,
        'Küçükbaş (Koç)': 309.0,
        'Küçükbaş (Toklu)': 304.0,
      },
    };
  }

  // Şehre göre bölge eşleştirmesi
  static String getCityRegion(String city) {
    final regionMap = {
      'İstanbul': 'Marmara',
      'Ankara': 'İç Anadolu',
      'İzmir': 'Ege',
      'Bursa': 'Marmara',
      'Antalya': 'Akdeniz',
      'Adana': 'Akdeniz',
      'Konya': 'İç Anadolu',
      'Gaziantep': 'Güneydoğu Anadolu',
      'Şanlıurfa': 'Güneydoğu Anadolu',
      'Kocaeli': 'Marmara',
      'Mersin': 'Akdeniz',
      'Diyarbakır': 'Güneydoğu Anadolu',
      'Hatay': 'Akdeniz',
      'Manisa': 'Ege',
      'Kayseri': 'İç Anadolu',
      'Samsun': 'Karadeniz',
      'Balıkesir': 'Marmara',
      'Kahramanmaraş': 'Akdeniz',
      'Van': 'Doğu Anadolu',
      'Aydın': 'Ege',
      'Denizli': 'Ege',
      'Şahin Bey': 'Güneydoğu Anadolu',
      'Tekirdağ': 'Marmara',
      'Muğla': 'Ege',
      'Eskişehir': 'İç Anadolu',
      'Mardin': 'Güneydoğu Anadolu',
      'Malatya': 'Doğu Anadolu',
      'Erzurum': 'Doğu Anadolu',
      'Trabzon': 'Karadeniz',
      'Elazığ': 'Doğu Anadolu',
      'Ordu': 'Karadeniz',
      'Afyonkarahisar': 'Ege',
      'Sivas': 'İç Anadolu',
      'Tokat': 'Karadeniz',
      'Çorum': 'Karadeniz',
      'Kütahya': 'Ege',
      'Isparta': 'Akdeniz',
      'Bolu': 'Karadeniz',
      'Yozgat': 'İç Anadolu',
      'Aksaray': 'İç Anadolu',
      'Karaman': 'İç Anadolu',
      'Kırıkkale': 'İç Anadolu',
      'Nevşehir': 'İç Anadolu',
      'Niğde': 'İç Anadolu',
    };

    return regionMap[city] ?? 'İç Anadolu';
  }

  // Şehre göre fiyatları getir
  static Map<String, double>? getPricesForCity(String? city) {
    if (city == null) return null;
    final region = getCityRegion(city);
    return getRegionalPrices()[region];
  }
}
