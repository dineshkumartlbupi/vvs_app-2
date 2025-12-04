/// Indian states and cities data for Varshney Samaj app
class IndianLocationsData {
  // All Indian States and Union Territories
  static const List<String> states = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    // Union Territories
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  // Major cities by state
  static const Map<String, List<String>> citiesByState = {
    'Andhra Pradesh': [
      'Visakhapatnam',
      'Vijayawada',
      'Guntur',
      'Nellore',
      'Kurnool',
      'Rajahmundry',
      'Kakinada',
      'Tirupati',
      'Anantapur',
      'Kadapa',
    ],
    'Arunachal Pradesh': [
      'Itanagar',
      'Naharlagun',
      'Pasighat',
      'Tawang',
      'Ziro',
    ],
    'Assam': [
      'Guwahati',
      'Silchar',
      'Dibrugarh',
      'Jorhat',
      'Nagaon',
      'Tezpur',
      'Tinsukia',
    ],
    'Bihar': [
      'Patna',
      'Gaya',
      'Bhagalpur',
      'Muzaffarpur',
      'Purnia',
      'Darbhanga',
      'Bihar Sharif',
      'Arrah',
      'Begusarai',
      'Katihar',
    ],
    'Chhattisgarh': [
      'Raipur',
      'Bhilai',
      'Bilaspur',
      'Korba',
      'Durg',
      'Rajnandgaon',
    ],
    'Goa': [
      'Panaji',
      'Margao',
      'Vasco da Gama',
      'Mapusa',
      'Ponda',
    ],
    'Gujarat': [
      'Ahmedabad',
      'Surat',
      'Vadodara',
      'Rajkot',
      'Bhavnagar',
      'Jamnagar',
      'Gandhinagar',
      'Junagadh',
      'Anand',
      'Nadiad',
    ],
    'Haryana': [
      'Faridabad',
      'Gurgaon',
      'Hisar',
      'Rohtak',
      'Panipat',
      'Karnal',
      'Sonipat',
      'Yamunanagar',
      'Panchkula',
      'Bhiwani',
      'Ambala',
    ],
    'Himachal Pradesh': [
      'Shimla',
      'Dharamshala',
      'Solan',
      'Mandi',
      'Kullu',
      'Hamirpur',
    ],
    'Jharkhand': [
      'Ranchi',
      'Jamshedpur',
      'Dhanbad',
      'Bokaro Steel City',
      'Deoghar',
      'Hazaribagh',
    ],
    'Karnataka': [
      'Bengaluru',
      'Mysuru',
      'Hubballi',
      'Mangaluru',
      'Belagavi',
      'Davanagere',
      'Ballari',
      'Vijayapura',
      'Shivamogga',
      'Tumakuru',
    ],
    'Kerala': [
      'Thiruvananthapuram',
      'Kochi',
      'Kozhikode',
      'Thrissur',
      'Kollam',
      'Palakkad',
      'Alappuzha',
      'Kannur',
      'Kottayam',
    ],
    'Madhya Pradesh': [
      'Indore',
      'Bhopal',
      'Jabalpur',
      'Gwalior',
      'Ujjain',
      'Sagar',
      'Dewas',
      'Satna',
      'Ratlam',
      'Rewa',
    ],
    'Maharashtra': [
      'Mumbai',
      'Pune',
      'Nagpur',
      'Thane',
      'Nashik',
      'Aurangabad',
      'Solapur',
      'Kolhapur',
      'Amravati',
      'Navi Mumbai',
      'Sangli',
      'Akola',
    ],
    'Manipur': [
      'Imphal',
      'Thoubal',
      'Bishnupur',
    ],
    'Meghalaya': [
      'Shillong',
      'Tura',
      'Nongstoin',
    ],
    'Mizoram': [
      'Aizawl',
      'Lunglei',
      'Champhai',
    ],
    'Nagaland': [
      'Kohima',
      'Dimapur',
      'Mokokchung',
    ],
    'Odisha': [
      'Bhubaneswar',
      'Cuttack',
      'Rourkela',
      'Brahmapur',
      'Sambalpur',
      'Puri',
      'Balasore',
    ],
    'Punjab': [
      'Ludhiana',
      'Amritsar',
      'Jalandhar',
      'Patiala',
      'Bathinda',
      'Mohali',
      'Pathankot',
      'Hoshiarpur',
    ],
    'Rajasthan': [
      'Jaipur',
      'Jodhpur',
      'Kota',
      'Udaipur',
      'Ajmer',
      'Bikaner',
      'Alwar',
      'Bharatpur',
      'Sikar',
      'Bhilwara',
    ],
    'Sikkim': [
      'Gangtok',
      'Namchi',
      'Gyalshing',
      'Mangan',
    ],
    'Tamil Nadu': [
      'Chennai',
      'Coimbatore',
      'Madurai',
      'Tiruchirappalli',
      'Salem',
      'Tirunelveli',
      'Tiruppur',
      'Vellore',
      'Erode',
      'Thoothukkudi',
    ],
    'Telangana': [
      'Hyderabad',
      'Warangal',
      'Nizamabad',
      'Khammam',
      'Karimnagar',
      'Ramagundam',
    ],
    'Tripura': [
      'Agartala',
      'Udaipur',
      'Dharmanagar',
    ],
    'Uttar Pradesh': [
      'Lucknow',
      'Kanpur',
      'Ghaziabad',
      'Agra',
      'Meerut',
      'Varanasi',
      'Allahabad (Prayagraj)',
      'Bareilly',
      'Aligarh',
      'Moradabad',
      'Saharanpur',
      'Gorakhpur',
      'Noida',
      'Firozabad',
      'Jhansi',
      'Muzaffarnagar',
      'Mathura',
      'Rampur',
      'Shahjahanpur',
      'Farrukhabad',
    ],
    'Uttarakhand': [
      'Dehradun',
      'Haridwar',
      'Roorkee',
      'Haldwani',
      'Rudrapur',
      'Kashipur',
    ],
    'West Bengal': [
      'Kolkata',
      'Asansol',
      'Siliguri',
      'Durgapur',
      'Bardhaman',
      'Malda',
      'Baharampur',
      'Habra',
      'Kharagpur',
    ],
    'Andaman and Nicobar Islands': [
      'Port Blair',
    ],
    'Chandigarh': [
      'Chandigarh',
    ],
    'Dadra and Nagar Haveli and Daman and Diu': [
      'Daman',
      'Diu',
      'Silvassa',
    ],
    'Delhi': [
      'New Delhi',
      'Delhi Cantonment',
    ],
    'Jammu and Kashmir': [
      'Srinagar',
      'Jammu',
      'Anantnag',
      'Baramulla',
    ],
    'Ladakh': [
      'Leh',
      'Kargil',
    ],
    'Lakshadweep': [
      'Kavaratti',
    ],
    'Puducherry': [
      'Puducherry',
      'Karaikal',
      'Mahe',
      'Yanam',
    ],
  };

  /// Get cities for a specific state
  static List<String> getCitiesForState(String state) {
    return citiesByState[state] ?? [];
  }

  /// Search cities by query
  static List<String> searchCities(String query, String? state) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    
    if (state != null && state.isNotEmpty) {
      final cities = getCitiesForState(state);
      return cities
          .where((city) => city.toLowerCase().contains(lowerQuery))
          .toList();
    }
    
    // Search in all cities
    final allCities = <String>[];
    for (final cities in citiesByState.values) {
      allCities.addAll(cities);
    }
    
    return allCities
        .where((city) => city.toLowerCase().contains(lowerQuery))
        .toSet()
        .toList()
      ..sort();
  }
}
