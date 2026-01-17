class City {
  final String name;
  final String plateCode;
  final String region;

  City({
    required this.name,
    required this.plateCode,
    required this.region,
  });

  static List<City> getAllCities() {
    return [
      City(name: 'Adana', plateCode: '01', region: 'Akdeniz'),
      City(name: 'Adıyaman', plateCode: '02', region: 'Güneydoğu Anadolu'),
      City(name: 'Afyonkarahisar', plateCode: '03', region: 'Ege'),
      City(name: 'Ağrı', plateCode: '04', region: 'Doğu Anadolu'),
      City(name: 'Amasya', plateCode: '05', region: 'Karadeniz'),
      City(name: 'Ankara', plateCode: '06', region: 'İç Anadolu'),
      City(name: 'Antalya', plateCode: '07', region: 'Akdeniz'),
      City(name: 'Artvin', plateCode: '08', region: 'Karadeniz'),
      City(name: 'Aydın', plateCode: '09', region: 'Ege'),
      City(name: 'Balıkesir', plateCode: '10', region: 'Marmara'),
      City(name: 'Bilecik', plateCode: '11', region: 'Marmara'),
      City(name: 'Bingöl', plateCode: '12', region: 'Doğu Anadolu'),
      City(name: 'Bitlis', plateCode: '13', region: 'Doğu Anadolu'),
      City(name: 'Bolu', plateCode: '14', region: 'Karadeniz'),
      City(name: 'Burdur', plateCode: '15', region: 'Akdeniz'),
      City(name: 'Bursa', plateCode: '16', region: 'Marmara'),
      City(name: 'Çanakkale', plateCode: '17', region: 'Marmara'),
      City(name: 'Çankırı', plateCode: '18', region: 'İç Anadolu'),
      City(name: 'Çorum', plateCode: '19', region: 'Karadeniz'),
      City(name: 'Denizli', plateCode: '20', region: 'Ege'),
      City(name: 'Diyarbakır', plateCode: '21', region: 'Güneydoğu Anadolu'),
      City(name: 'Edirne', plateCode: '22', region: 'Marmara'),
      City(name: 'Elazığ', plateCode: '23', region: 'Doğu Anadolu'),
      City(name: 'Erzincan', plateCode: '24', region: 'Doğu Anadolu'),
      City(name: 'Erzurum', plateCode: '25', region: 'Doğu Anadolu'),
      City(name: 'Eskişehir', plateCode: '26', region: 'İç Anadolu'),
      City(name: 'Gaziantep', plateCode: '27', region: 'Güneydoğu Anadolu'),
      City(name: 'Giresun', plateCode: '28', region: 'Karadeniz'),
      City(name: 'Gümüşhane', plateCode: '29', region: 'Karadeniz'),
      City(name: 'Hakkari', plateCode: '30', region: 'Doğu Anadolu'),
      City(name: 'Hatay', plateCode: '31', region: 'Akdeniz'),
      City(name: 'Isparta', plateCode: '32', region: 'Akdeniz'),
      City(name: 'Mersin', plateCode: '33', region: 'Akdeniz'),
      City(name: 'İstanbul', plateCode: '34', region: 'Marmara'),
      City(name: 'İzmir', plateCode: '35', region: 'Ege'),
      City(name: 'Kars', plateCode: '36', region: 'Doğu Anadolu'),
      City(name: 'Kastamonu', plateCode: '37', region: 'Karadeniz'),
      City(name: 'Kayseri', plateCode: '38', region: 'İç Anadolu'),
      City(name: 'Kırklareli', plateCode: '39', region: 'Marmara'),
      City(name: 'Kırşehir', plateCode: '40', region: 'İç Anadolu'),
      City(name: 'Kocaeli', plateCode: '41', region: 'Marmara'),
      City(name: 'Konya', plateCode: '42', region: 'İç Anadolu'),
      City(name: 'Kütahya', plateCode: '43', region: 'Ege'),
      City(name: 'Malatya', plateCode: '44', region: 'Doğu Anadolu'),
      City(name: 'Manisa', plateCode: '45', region: 'Ege'),
      City(name: 'Kahramanmaraş', plateCode: '46', region: 'Akdeniz'),
      City(name: 'Mardin', plateCode: '47', region: 'Güneydoğu Anadolu'),
      City(name: 'Muğla', plateCode: '48', region: 'Ege'),
      City(name: 'Muş', plateCode: '49', region: 'Doğu Anadolu'),
      City(name: 'Nevşehir', plateCode: '50', region: 'İç Anadolu'),
      City(name: 'Niğde', plateCode: '51', region: 'İç Anadolu'),
      City(name: 'Ordu', plateCode: '52', region: 'Karadeniz'),
      City(name: 'Rize', plateCode: '53', region: 'Karadeniz'),
      City(name: 'Sakarya', plateCode: '54', region: 'Marmara'),
      City(name: 'Samsun', plateCode: '55', region: 'Karadeniz'),
      City(name: 'Siirt', plateCode: '56', region: 'Güneydoğu Anadolu'),
      City(name: 'Sinop', plateCode: '57', region: 'Karadeniz'),
      City(name: 'Sivas', plateCode: '58', region: 'İç Anadolu'),
      City(name: 'Tekirdağ', plateCode: '59', region: 'Marmara'),
      City(name: 'Tokat', plateCode: '60', region: 'Karadeniz'),
      City(name: 'Trabzon', plateCode: '61', region: 'Karadeniz'),
      City(name: 'Tunceli', plateCode: '62', region: 'Doğu Anadolu'),
      City(name: 'Şanlıurfa', plateCode: '63', region: 'Güneydoğu Anadolu'),
      City(name: 'Uşak', plateCode: '64', region: 'Ege'),
      City(name: 'Van', plateCode: '65', region: 'Doğu Anadolu'),
      City(name: 'Yozgat', plateCode: '66', region: 'İç Anadolu'),
      City(name: 'Zonguldak', plateCode: '67', region: 'Karadeniz'),
      City(name: 'Aksaray', plateCode: '68', region: 'İç Anadolu'),
      City(name: 'Bayburt', plateCode: '69', region: 'Karadeniz'),
      City(name: 'Karaman', plateCode: '70', region: 'İç Anadolu'),
      City(name: 'Kırıkkale', plateCode: '71', region: 'İç Anadolu'),
      City(name: 'Batman', plateCode: '72', region: 'Güneydoğu Anadolu'),
      City(name: 'Şırnak', plateCode: '73', region: 'Güneydoğu Anadolu'),
      City(name: 'Bartın', plateCode: '74', region: 'Karadeniz'),
      City(name: 'Ardahan', plateCode: '75', region: 'Doğu Anadolu'),
      City(name: 'Iğdır', plateCode: '76', region: 'Doğu Anadolu'),
      City(name: 'Yalova', plateCode: '77', region: 'Marmara'),
      City(name: 'Karabük', plateCode: '78', region: 'Karadeniz'),
      City(name: 'Kilis', plateCode: '79', region: 'Güneydoğu Anadolu'),
      City(name: 'Osmaniye', plateCode: '80', region: 'Akdeniz'),
      City(name: 'Düzce', plateCode: '81', region: 'Karadeniz'),
    ];
  }

  static City? findByName(String name) {
    try {
      return getAllCities().firstWhere(
        (city) => city.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}
