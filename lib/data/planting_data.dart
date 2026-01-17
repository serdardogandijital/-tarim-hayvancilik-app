// Türkiye Tarım ve Orman Bakanlığı ve Tarım İl Müdürlükleri verilerine dayalı
// Bölgesel ekim takvimi verileri

class PlantingData {
  // Türkiye'nin 7 coğrafi bölgesi
  static const Map<String, String> cityToRegion = {
    'İstanbul': 'Marmara',
    'Ankara': 'İç Anadolu',
    'İzmir': 'Ege',
    'Antalya': 'Akdeniz',
    'Adana': 'Akdeniz',
    'Bursa': 'Marmara',
    'Gaziantep': 'Güneydoğu Anadolu',
    'Konya': 'İç Anadolu',
    'Şanlıurfa': 'Güneydoğu Anadolu',
    'Mersin': 'Akdeniz',
    'Kayseri': 'İç Anadolu',
    'Eskişehir': 'İç Anadolu',
    'Diyarbakır': 'Güneydoğu Anadolu',
    'Samsun': 'Karadeniz',
    'Denizli': 'Ege',
    'Şahinbey': 'Güneydoğu Anadolu',
    'Adapazarı': 'Marmara',
    'Malatya': 'Doğu Anadolu',
    'Kahramanmaraş': 'Akdeniz',
    'Erzurum': 'Doğu Anadolu',
    'Van': 'Doğu Anadolu',
    'Batman': 'Güneydoğu Anadolu',
    'Elazığ': 'Doğu Anadolu',
    'İzmit': 'Marmara',
    'Manisa': 'Ege',
    'Sivas': 'İç Anadolu',
    'Gebze': 'Marmara',
    'Balıkesir': 'Marmara',
    'Tarsus': 'Akdeniz',
    'Kütahya': 'Ege',
    'Trabzon': 'Karadeniz',
    'Çorum': 'Karadeniz',
    'Çorlu': 'Marmara',
    'Adıyaman': 'Güneydoğu Anadolu',
    'Osmaniye': 'Akdeniz',
    'Kırıkkale': 'İç Anadolu',
    'Antakya': 'Akdeniz',
    'Aydın': 'Ege',
    'İskenderun': 'Akdeniz',
    'Uşak': 'Ege',
    'Aksaray': 'İç Anadolu',
    'Afyon': 'Ege',
    'Isparta': 'Akdeniz',
    'İnegöl': 'Marmara',
    'Tekirdağ': 'Marmara',
    'Edirne': 'Marmara',
    'Darıca': 'Marmara',
    'Ordu': 'Karadeniz',
    'Karaman': 'İç Anadolu',
    'Gölcük': 'Marmara',
    'Siirt': 'Güneydoğu Anadolu',
    'Körfez': 'Marmara',
    'Kızıltepe': 'Güneydoğu Anadolu',
    'Düzce': 'Karadeniz',
    'Tokat': 'Karadeniz',
    'Derince': 'Marmara',
    'Nazilli': 'Ege',
    'Zonguldak': 'Karadeniz',
    'Kırşehir': 'İç Anadolu',
    'Niğde': 'İç Anadolu',
    'Ceyhan': 'Akdeniz',
    'Karabük': 'Karadeniz',
    'Ereğli': 'İç Anadolu',
    'Akhisar': 'Ege',
    'Polatlı': 'İç Anadolu',
    'Çanakkale': 'Marmara',
    'Yalova': 'Marmara',
    'Giresun': 'Karadeniz',
    'Bolu': 'Karadeniz',
    'Amasya': 'Karadeniz',
    'Turhal': 'Karadeniz',
    'Bandırma': 'Marmara',
    'Nevşehir': 'İç Anadolu',
    'Kilis': 'Güneydoğu Anadolu',
    'Erzincan': 'Doğu Anadolu',
    'Burdur': 'Akdeniz',
    'Muğla': 'Ege',
    'Rize': 'Karadeniz',
  };

  // Bölgelere göre aylık ekim takvimi
  static Map<String, List<Map<String, String>>> getMonthlyPlanting(
      String region, int month) {
    final regionalData = _regionalPlantingCalendar[region] ?? _regionalPlantingCalendar['İç Anadolu']!;
    return {
      'crops': regionalData[month] ?? [],
    };
  }

  // Bölgesel ekim takvimi - Tarım Bakanlığı verilerine dayalı
  static final Map<String, Map<int, List<Map<String, String>>>> _regionalPlantingCalendar = {
    'Marmara': {
      1: [
        {'name': 'Soğan (Fide)', 'icon': '🧅', 'note': 'Sera veya sıcak yastıkta', 'type': 'Sebze'},
        {'name': 'Sarımsak', 'icon': '🧄', 'note': 'Kış sarımsağı', 'type': 'Sebze'},
      ],
      2: [
        {'name': 'Bezelye', 'icon': '🫛', 'note': 'Erken çeşitler', 'type': 'Baklagil'},
        {'name': 'Ispanak', 'icon': '🥬', 'note': 'İlkbahar ekimi', 'type': 'Sebze'},
        {'name': 'Marul', 'icon': '🥬', 'note': 'Sera veya tünel', 'type': 'Sebze'},
      ],
      3: [
        {'name': 'Havuç', 'icon': '🥕', 'note': 'İlkbahar ekimi', 'type': 'Sebze'},
        {'name': 'Turp', 'icon': '🌱', 'note': 'Hızlı hasat', 'type': 'Sebze'},
        {'name': 'Roka', 'icon': '🌿', 'note': 'Taze tüketim', 'type': 'Sebze'},
        {'name': 'Patates', 'icon': '🥔', 'note': 'Erken patates', 'type': 'Sebze'},
      ],
      4: [
        {'name': 'Domates (Fide)', 'icon': '🍅', 'note': 'Açıkta yetiştirme', 'type': 'Sebze'},
        {'name': 'Biber (Fide)', 'icon': '🌶️', 'note': 'Sıcak dönem', 'type': 'Sebze'},
        {'name': 'Patlıcan (Fide)', 'icon': '🍆', 'note': 'Fide dikimi', 'type': 'Sebze'},
        {'name': 'Kabak', 'icon': '🥒', 'note': 'Yazlık kabak', 'type': 'Sebze'},
      ],
      5: [
        {'name': 'Fasulye', 'icon': '🫘', 'note': 'Taze fasulye', 'type': 'Baklagil'},
        {'name': 'Mısır', 'icon': '🌽', 'note': 'Tatlı mısır', 'type': 'Tahıl'},
        {'name': 'Salatalık', 'icon': '🥒', 'note': 'Açık alan', 'type': 'Sebze'},
        {'name': 'Karpuz', 'icon': '🍉', 'note': 'Yaz meyvesi', 'type': 'Meyve'},
      ],
      6: [
        {'name': 'Lahana (Fide)', 'icon': '🥬', 'note': 'Sonbahar hasadı', 'type': 'Sebze'},
        {'name': 'Brokoli (Fide)', 'icon': '🥦', 'note': 'Fide dikimi', 'type': 'Sebze'},
        {'name': 'Karnabahar (Fide)', 'icon': '🥦', 'note': 'Sonbahar çeşitleri', 'type': 'Sebze'},
      ],
      7: [
        {'name': 'Pırasa', 'icon': '🌱', 'note': 'Kış hasadı için', 'type': 'Sebze'},
        {'name': 'Kereviz', 'icon': '🌿', 'note': 'Sonbahar ekimi', 'type': 'Sebze'},
      ],
      8: [
        {'name': 'Ispanak', 'icon': '🥬', 'note': 'Sonbahar ekimi', 'type': 'Sebze'},
        {'name': 'Marul', 'icon': '🥬', 'note': 'Kış marul', 'type': 'Sebze'},
        {'name': 'Turp', 'icon': '🌱', 'note': 'Sonbahar turpu', 'type': 'Sebze'},
      ],
      9: [
        {'name': 'Soğan (Kış)', 'icon': '🧅', 'note': 'Kış soğanı', 'type': 'Sebze'},
        {'name': 'Sarımsak', 'icon': '🧄', 'note': 'Sonbahar ekimi', 'type': 'Sebze'},
        {'name': 'Buğday', 'icon': '🌾', 'note': 'Kışlık buğday', 'type': 'Tahıl'},
      ],
      10: [
        {'name': 'Arpa', 'icon': '🌾', 'note': 'Kışlık arpa', 'type': 'Tahıl'},
        {'name': 'Çavdar', 'icon': '🌾', 'note': 'Kışlık tahıl', 'type': 'Tahıl'},
        {'name': 'Bakla', 'icon': '🫘', 'note': 'Kış baklagili', 'type': 'Baklagil'},
      ],
      11: [
        {'name': 'Bezelye (Kış)', 'icon': '🫛', 'note': 'Kış bezelyesi', 'type': 'Baklagil'},
        {'name': 'Nohut', 'icon': '🫘', 'note': 'Kışlık ekim', 'type': 'Baklagil'},
      ],
      12: [
        {'name': 'Mercimek', 'icon': '🫘', 'note': 'Kışlık ekim', 'type': 'Baklagil'},
        {'name': 'Yonca', 'icon': '🍀', 'note': 'Yem bitkisi', 'type': 'Yem'},
      ],
    },
    'Ege': {
      1: [
        {'name': 'Soğan (Fide)', 'icon': '🧅', 'note': 'Sera ekimi', 'type': 'Sebze'},
        {'name': 'Domates (Fide)', 'icon': '🍅', 'note': 'Sera ekimi', 'type': 'Sebze'},
      ],
      2: [
        {'name': 'Biber (Fide)', 'icon': '🌶️', 'note': 'Sera ekimi', 'type': 'Sebze'},
        {'name': 'Patlıcan (Fide)', 'icon': '🍆', 'note': 'Sera ekimi', 'type': 'Sebze'},
        {'name': 'Marul', 'icon': '🥬', 'note': 'Açık alan', 'type': 'Sebze'},
      ],
      3: [
        {'name': 'Kavun', 'icon': '🍈', 'note': 'Erken ekim', 'type': 'Meyve'},
        {'name': 'Karpuz', 'icon': '🍉', 'note': 'Erken ekim', 'type': 'Meyve'},
        {'name': 'Kabak', 'icon': '🥒', 'note': 'Yazlık kabak', 'type': 'Sebze'},
      ],
      4: [
        {'name': 'Domates (Fide)', 'icon': '🍅', 'note': 'Açık alan dikimi', 'type': 'Sebze'},
        {'name': 'Biber (Fide)', 'icon': '🌶️', 'note': 'Açık alan dikimi', 'type': 'Sebze'},
        {'name': 'Bamya', 'icon': '🌱', 'note': 'Sıcak mevsim', 'type': 'Sebze'},
        {'name': 'Fasulye', 'icon': '🫘', 'note': 'Taze fasulye', 'type': 'Baklagil'},
      ],
      5: [
        {'name': 'Mısır', 'icon': '🌽', 'note': 'Tatlı mısır', 'type': 'Tahıl'},
        {'name': 'Susam', 'icon': '🌱', 'note': 'Yağlık bitki', 'type': 'Endüstri'},
        {'name': 'Ayçiçeği', 'icon': '🌻', 'note': 'Yağlık bitki', 'type': 'Endüstri'},
      ],
      6: [
        {'name': 'Soya Fasulyesi', 'icon': '🫘', 'note': 'Yağlık bitki', 'type': 'Baklagil'},
        {'name': 'Pamuk', 'icon': '🌱', 'note': 'Endüstri bitkisi', 'type': 'Endüstri'},
      ],
      7: [
        {'name': 'Lahana (Fide)', 'icon': '🥬', 'note': 'Sonbahar hasadı', 'type': 'Sebze'},
        {'name': 'Karnabahar (Fide)', 'icon': '🥦', 'note': 'Sonbahar ekimi', 'type': 'Sebze'},
      ],
      8: [
        {'name': 'Ispanak', 'icon': '🥬', 'note': 'Sonbahar ekimi', 'type': 'Sebze'},
        {'name': 'Roka', 'icon': '🌿', 'note': 'Hızlı büyüyen', 'type': 'Sebze'},
      ],
      9: [
        {'name': 'Buğday', 'icon': '🌾', 'note': 'Kışlık buğday', 'type': 'Tahıl'},
        {'name': 'Arpa', 'icon': '🌾', 'note': 'Kışlık arpa', 'type': 'Tahıl'},
      ],
      10: [
        {'name': 'Nohut', 'icon': '🫘', 'note': 'Kışlık ekim', 'type': 'Baklagil'},
        {'name': 'Mercimek', 'icon': '🫘', 'note': 'Kışlık ekim', 'type': 'Baklagil'},
      ],
      11: [
        {'name': 'Bakla', 'icon': '🫘', 'note': 'Kış baklagili', 'type': 'Baklagil'},
        {'name': 'Bezelye', 'icon': '🫛', 'note': 'Kış bezelyesi', 'type': 'Baklagil'},
      ],
      12: [
        {'name': 'Yonca', 'icon': '🍀', 'note': 'Yem bitkisi', 'type': 'Yem'},
        {'name': 'Fiğ', 'icon': '🌱', 'note': 'Yem bitkisi', 'type': 'Yem'},
      ],
    },
    'Akdeniz': {
      1: [
        {'name': 'Domates (Fide)', 'icon': '🍅', 'note': 'Sera ekimi', 'type': 'Sebze'},
        {'name': 'Biber (Fide)', 'icon': '🌶️', 'note': 'Sera ekimi', 'type': 'Sebze'},
        {'name': 'Hıyar (Fide)', 'icon': '🥒', 'note': 'Sera ekimi', 'type': 'Sebze'},
      ],
      2: [
        {'name': 'Patlıcan (Fide)', 'icon': '🍆', 'note': 'Sera ekimi', 'type': 'Sebze'},
        {'name': 'Kabak', 'icon': '🥒', 'note': 'Erken ekim', 'type': 'Sebze'},
        {'name': 'Marul', 'icon': '🥬', 'note': 'Açık alan', 'type': 'Sebze'},
      ],
      3: [
        {'name': 'Kavun', 'icon': '🍈', 'note': 'Erken ekim', 'type': 'Meyve'},
        {'name': 'Karpuz', 'icon': '🍉', 'note': 'Erken ekim', 'type': 'Meyve'},
        {'name': 'Bamya', 'icon': '🌱', 'note': 'Sıcak mevsim', 'type': 'Sebze'},
      ],
      4: [
        {'name': 'Domates (Fide)', 'icon': '🍅', 'note': 'Açık alan dikimi', 'type': 'Sebze'},
        {'name': 'Biber (Fide)', 'icon': '🌶️', 'note': 'Açık alan dikimi', 'type': 'Sebze'},
        {'name': 'Fasulye', 'icon': '🫘', 'note': 'Taze fasulye', 'type': 'Baklagil'},
        {'name': 'Mısır', 'icon': '🌽', 'note': 'Tatlı mısır', 'type': 'Tahıl'},
      ],
      5: [
        {'name': 'Pamuk', 'icon': '🌱', 'note': 'Endüstri bitkisi', 'type': 'Endüstri'},
        {'name': 'Susam', 'icon': '🌱', 'note': 'Yağlık bitki', 'type': 'Endüstri'},
        {'name': 'Yer Fıstığı', 'icon': '🥜', 'note': 'Yağlık bitki', 'type': 'Endüstri'},
      ],
      6: [
        {'name': 'Soya Fasulyesi', 'icon': '🫘', 'note': 'İkinci ürün', 'type': 'Baklagil'},
        {'name': 'Mısır (İkinci)', 'icon': '🌽', 'note': 'İkinci ürün', 'type': 'Tahıl'},
      ],
      7: [
        {'name': 'Havuç', 'icon': '🥕', 'note': 'Sonbahar ekimi', 'type': 'Sebze'},
        {'name': 'Lahana (Fide)', 'icon': '🥬', 'note': 'Kış hasadı', 'type': 'Sebze'},
      ],
      8: [
        {'name': 'Ispanak', 'icon': '🥬', 'note': 'Sonbahar ekimi', 'type': 'Sebze'},
        {'name': 'Marul', 'icon': '🥬', 'note': 'Kış marul', 'type': 'Sebze'},
      ],
      9: [
        {'name': 'Buğday', 'icon': '🌾', 'note': 'Kışlık buğday', 'type': 'Tahıl'},
        {'name': 'Arpa', 'icon': '🌾', 'note': 'Kışlık arpa', 'type': 'Tahıl'},
      ],
      10: [
        {'name': 'Nohut', 'icon': '🫘', 'note': 'Kışlık ekim', 'type': 'Baklagil'},
        {'name': 'Mercimek', 'icon': '🫘', 'note': 'Kışlık ekim', 'type': 'Baklagil'},
      ],
      11: [
        {'name': 'Bakla', 'icon': '🫘', 'note': 'Kış baklagili', 'type': 'Baklagil'},
        {'name': 'Bezelye', 'icon': '🫛', 'note': 'Kış bezelyesi', 'type': 'Baklagil'},
      ],
      12: [
        {'name': 'Soğan (Fide)', 'icon': '🧅', 'note': 'Sera ekimi', 'type': 'Sebze'},
        {'name': 'Sarımsak', 'icon': '🧄', 'note': 'Kış sarımsağı', 'type': 'Sebze'},
      ],
    },
    'İç Anadolu': {
      1: [
        {'name': 'Soğan (Fide)', 'icon': '🧅', 'note': 'Sera ekimi', 'type': 'Sebze'},
      ],
      2: [
        {'name': 'Domates (Fide)', 'icon': '🍅', 'note': 'Sera ekimi', 'type': 'Sebze'},
        {'name': 'Biber (Fide)', 'icon': '🌶️', 'note': 'Sera ekimi', 'type': 'Sebze'},
      ],
      3: [
        {'name': 'Patates', 'icon': '🥔', 'note': 'Erken patates', 'type': 'Sebze'},
        {'name': 'Bezelye', 'icon': '🫛', 'note': 'İlkbahar ekimi', 'type': 'Baklagil'},
      ],
      4: [
        {'name': 'Şeker Pancarı', 'icon': '🌱', 'note': 'Endüstri bitkisi', 'type': 'Endüstri'},
        {'name': 'Havuç', 'icon': '🥕', 'note': 'İlkbahar ekimi', 'type': 'Sebze'},
        {'name': 'Marul', 'icon': '🥬', 'note': 'Taze tüketim', 'type': 'Sebze'},
      ],
      5: [
        {'name': 'Domates (Fide)', 'icon': '🍅', 'note': 'Açık alan dikimi', 'type': 'Sebze'},
        {'name': 'Biber (Fide)', 'icon': '🌶️', 'note': 'Açık alan dikimi', 'type': 'Sebze'},
        {'name': 'Fasulye', 'icon': '🫘', 'note': 'Kuru fasulye', 'type': 'Baklagil'},
      ],
      6: [
        {'name': 'Mısır', 'icon': '🌽', 'note': 'Silajlık mısır', 'type': 'Tahıl'},
        {'name': 'Ayçiçeği', 'icon': '🌻', 'note': 'Yağlık bitki', 'type': 'Endüstri'},
      ],
      7: [
        {'name': 'Lahana (Fide)', 'icon': '🥬', 'note': 'Sonbahar hasadı', 'type': 'Sebze'},
        {'name': 'Karnabahar (Fide)', 'icon': '🥦', 'note': 'Sonbahar ekimi', 'type': 'Sebze'},
      ],
      8: [
        {'name': 'Ispanak', 'icon': '🥬', 'note': 'Sonbahar ekimi', 'type': 'Sebze'},
        {'name': 'Roka', 'icon': '🌿', 'note': 'Hızlı büyüyen', 'type': 'Sebze'},
      ],
      9: [
        {'name': 'Buğday', 'icon': '🌾', 'note': 'Kışlık buğday', 'type': 'Tahıl'},
        {'name': 'Arpa', 'icon': '🌾', 'note': 'Kışlık arpa', 'type': 'Tahıl'},
        {'name': 'Çavdar', 'icon': '🌾', 'note': 'Kışlık tahıl', 'type': 'Tahıl'},
      ],
      10: [
        {'name': 'Nohut', 'icon': '🫘', 'note': 'Kışlık ekim', 'type': 'Baklagil'},
        {'name': 'Mercimek', 'icon': '🫘', 'note': 'Kışlık ekim', 'type': 'Baklagil'},
      ],
      11: [
        {'name': 'Bakla', 'icon': '🫘', 'note': 'Kış baklagili', 'type': 'Baklagil'},
        {'name': 'Bezelye (Kış)', 'icon': '🫛', 'note': 'Kış bezelyesi', 'type': 'Baklagil'},
      ],
      12: [
        {'name': 'Yonca', 'icon': '🍀', 'note': 'Yem bitkisi', 'type': 'Yem'},
        {'name': 'Korunga', 'icon': '🌱', 'note': 'Yem bitkisi', 'type': 'Yem'},
      ],
    },
    'Karadeniz': {
      1: [
        {'name': 'Soğan (Fide)', 'icon': '🧅', 'note': 'Sera ekimi', 'type': 'Sebze'},
      ],
      2: [
        {'name': 'Lahana (Fide)', 'icon': '🥬', 'note': 'Sera ekimi', 'type': 'Sebze'},
        {'name': 'Marul', 'icon': '🥬', 'note': 'Sera ekimi', 'type': 'Sebze'},
      ],
      3: [
        {'name': 'Patates', 'icon': '🥔', 'note': 'Erken patates', 'type': 'Sebze'},
        {'name': 'Bezelye', 'icon': '🫛', 'note': 'İlkbahar ekimi', 'type': 'Baklagil'},
        {'name': 'Ispanak', 'icon': '🥬', 'note': 'İlkbahar ekimi', 'type': 'Sebze'},
      ],
      4: [
        {'name': 'Fasulye', 'icon': '🫘', 'note': 'Taze fasulye', 'type': 'Baklagil'},
        {'name': 'Mısır', 'icon': '🌽', 'note': 'Silajlık mısır', 'type': 'Tahıl'},
        {'name': 'Havuç', 'icon': '🥕', 'note': 'İlkbahar ekimi', 'type': 'Sebze'},
      ],
      5: [
        {'name': 'Domates (Fide)', 'icon': '🍅', 'note': 'Açık alan dikimi', 'type': 'Sebze'},
        {'name': 'Biber (Fide)', 'icon': '🌶️', 'note': 'Açık alan dikimi', 'type': 'Sebze'},
        {'name': 'Kabak', 'icon': '🥒', 'note': 'Yazlık kabak', 'type': 'Sebze'},
      ],
      6: [
        {'name': 'Lahana', 'icon': '🥬', 'note': 'Yaz lahanası', 'type': 'Sebze'},
        {'name': 'Karnabahar', 'icon': '🥦', 'note': 'Yaz ekimi', 'type': 'Sebze'},
      ],
      7: [
        {'name': 'Brokoli (Fide)', 'icon': '🥦', 'note': 'Sonbahar hasadı', 'type': 'Sebze'},
        {'name': 'Pırasa', 'icon': '🌱', 'note': 'Kış hasadı', 'type': 'Sebze'},
      ],
      8: [
        {'name': 'Ispanak', 'icon': '🥬', 'note': 'Sonbahar ekimi', 'type': 'Sebze'},
        {'name': 'Marul', 'icon': '🥬', 'note': 'Sonbahar ekimi', 'type': 'Sebze'},
      ],
      9: [
        {'name': 'Soğan (Kış)', 'icon': '🧅', 'note': 'Kış soğanı', 'type': 'Sebze'},
        {'name': 'Sarımsak', 'icon': '🧄', 'note': 'Sonbahar ekimi', 'type': 'Sebze'},
      ],
      10: [
        {'name': 'Buğday', 'icon': '🌾', 'note': 'Kışlık buğday', 'type': 'Tahıl'},
        {'name': 'Çavdar', 'icon': '🌾', 'note': 'Kışlık tahıl', 'type': 'Tahıl'},
      ],
      11: [
        {'name': 'Bakla', 'icon': '🫘', 'note': 'Kış baklagili', 'type': 'Baklagil'},
        {'name': 'Bezelye (Kış)', 'icon': '🫛', 'note': 'Kış bezelyesi', 'type': 'Baklagil'},
      ],
      12: [
        {'name': 'Yonca', 'icon': '🍀', 'note': 'Yem bitkisi', 'type': 'Yem'},
        {'name': 'Fiğ', 'icon': '🌱', 'note': 'Yem bitkisi', 'type': 'Yem'},
      ],
    },
    'Doğu Anadolu': {
      1: [],
      2: [],
      3: [
        {'name': 'Patates', 'icon': '🥔', 'note': 'Erken patates (sera)', 'type': 'Sebze'},
      ],
      4: [
        {'name': 'Bezelye', 'icon': '🫛', 'note': 'İlkbahar ekimi', 'type': 'Baklagil'},
        {'name': 'Ispanak', 'icon': '🥬', 'note': 'İlkbahar ekimi', 'type': 'Sebze'},
      ],
      5: [
        {'name': 'Patates', 'icon': '🥔', 'note': 'Ana ürün', 'type': 'Sebze'},
        {'name': 'Şeker Pancarı', 'icon': '🌱', 'note': 'Endüstri bitkisi', 'type': 'Endüstri'},
        {'name': 'Havuç', 'icon': '🥕', 'note': 'İlkbahar ekimi', 'type': 'Sebze'},
      ],
      6: [
        {'name': 'Fasulye', 'icon': '🫘', 'note': 'Kuru fasulye', 'type': 'Baklagil'},
        {'name': 'Mısır', 'icon': '🌽', 'note': 'Silajlık mısır', 'type': 'Tahıl'},
      ],
      7: [
        {'name': 'Lahana (Fide)', 'icon': '🥬', 'note': 'Sonbahar hasadı', 'type': 'Sebze'},
      ],
      8: [
        {'name': 'Ispanak', 'icon': '🥬', 'note': 'Sonbahar ekimi', 'type': 'Sebze'},
      ],
      9: [
        {'name': 'Buğday', 'icon': '🌾', 'note': 'Kışlık buğday', 'type': 'Tahıl'},
        {'name': 'Arpa', 'icon': '🌾', 'note': 'Kışlık arpa', 'type': 'Tahıl'},
      ],
      10: [
        {'name': 'Nohut', 'icon': '🫘', 'note': 'Kışlık ekim', 'type': 'Baklagil'},
        {'name': 'Mercimek', 'icon': '🫘', 'note': 'Kışlık ekim', 'type': 'Baklagil'},
      ],
      11: [
        {'name': 'Bakla', 'icon': '🫘', 'note': 'Kış baklagili', 'type': 'Baklagil'},
      ],
      12: [
        {'name': 'Yonca', 'icon': '🍀', 'note': 'Yem bitkisi', 'type': 'Yem'},
      ],
    },
    'Güneydoğu Anadolu': {
      1: [
        {'name': 'Domates (Fide)', 'icon': '🍅', 'note': 'Sera ekimi', 'type': 'Sebze'},
        {'name': 'Biber (Fide)', 'icon': '🌶️', 'note': 'Sera ekimi', 'type': 'Sebze'},
      ],
      2: [
        {'name': 'Patlıcan (Fide)', 'icon': '🍆', 'note': 'Sera ekimi', 'type': 'Sebze'},
        {'name': 'Kavun', 'icon': '🍈', 'note': 'Erken ekim', 'type': 'Meyve'},
      ],
      3: [
        {'name': 'Karpuz', 'icon': '🍉', 'note': 'Erken ekim', 'type': 'Meyve'},
        {'name': 'Bamya', 'icon': '🌱', 'note': 'Sıcak mevsim', 'type': 'Sebze'},
        {'name': 'Kabak', 'icon': '🥒', 'note': 'Yazlık kabak', 'type': 'Sebze'},
      ],
      4: [
        {'name': 'Pamuk', 'icon': '🌱', 'note': 'Ana ürün', 'type': 'Endüstri'},
        {'name': 'Mısır', 'icon': '🌽', 'note': 'Tane mısır', 'type': 'Tahıl'},
        {'name': 'Fasulye', 'icon': '🫘', 'note': 'Kuru fasulye', 'type': 'Baklagil'},
      ],
      5: [
        {'name': 'Susam', 'icon': '🌱', 'note': 'Yağlık bitki', 'type': 'Endüstri'},
        {'name': 'Soya Fasulyesi', 'icon': '🫘', 'note': 'Yağlık bitki', 'type': 'Baklagil'},
        {'name': 'Yer Fıstığı', 'icon': '🥜', 'note': 'Yağlık bitki', 'type': 'Endüstri'},
      ],
      6: [
        {'name': 'Mısır (İkinci)', 'icon': '🌽', 'note': 'İkinci ürün', 'type': 'Tahıl'},
      ],
      7: [
        {'name': 'Havuç', 'icon': '🥕', 'note': 'Sonbahar ekimi', 'type': 'Sebze'},
      ],
      8: [
        {'name': 'Ispanak', 'icon': '🥬', 'note': 'Sonbahar ekimi', 'type': 'Sebze'},
        {'name': 'Marul', 'icon': '🥬', 'note': 'Kış marul', 'type': 'Sebze'},
      ],
      9: [
        {'name': 'Buğday', 'icon': '🌾', 'note': 'Kışlık buğday', 'type': 'Tahıl'},
        {'name': 'Arpa', 'icon': '🌾', 'note': 'Kışlık arpa', 'type': 'Tahıl'},
      ],
      10: [
        {'name': 'Nohut', 'icon': '🫘', 'note': 'Kışlık ekim', 'type': 'Baklagil'},
        {'name': 'Mercimek', 'icon': '🫘', 'note': 'Kırmızı mercimek', 'type': 'Baklagil'},
      ],
      11: [
        {'name': 'Bakla', 'icon': '🫘', 'note': 'Kış baklagili', 'type': 'Baklagil'},
        {'name': 'Bezelye', 'icon': '🫛', 'note': 'Kış bezelyesi', 'type': 'Baklagil'},
      ],
      12: [
        {'name': 'Soğan (Fide)', 'icon': '🧅', 'note': 'Sera ekimi', 'type': 'Sebze'},
        {'name': 'Sarımsak', 'icon': '🧄', 'note': 'Kış sarımsağı', 'type': 'Sebze'},
      ],
    },
  };

  static String getRegion(String? cityName) {
    if (cityName == null) return 'İç Anadolu';
    return cityToRegion[cityName] ?? 'İç Anadolu';
  }

  static List<Map<String, String>> getCropsForMonth(String? cityName, int month) {
    final region = getRegion(cityName);
    final regionalData = _regionalPlantingCalendar[region] ?? _regionalPlantingCalendar['İç Anadolu']!;
    return regionalData[month] ?? [];
  }

  static List<Map<String, String>> getTodayPlantableCrops(String? cityName) {
    final now = DateTime.now();
    return getCropsForMonth(cityName, now.month);
  }
}
