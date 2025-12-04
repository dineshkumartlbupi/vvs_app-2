import 'package:cloud_firestore/cloud_firestore.dart';

/// User model for Varshney Samaj app
class UserModel {
  final String? uid;
  final String firstName;
  final String? middleName;
  final String? lastName;
  final String dob;
  final String fatherHusbandName;
  final String gender;
  final String maritalStatus;
  final String occupation;
  final String qualification;
  final String profession;
  final String email;
  final String mobile;
  
  // Enhanced address fields
  final String houseNumber;
  final String streetArea;
  final String village;
  final String city;
  final String district;
  final String state;
  final String pinCode;
  final String? landmark;
  
  final String bloodGroup;
  final String aadhaarNumber;
  final String role;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  
  // Optional additional fields
  final String? profileImageUrl;
  final bool? isVerified;
  final String? membershipId;

  UserModel({
    this.uid,
    required this.firstName,
    this.middleName,
    this.lastName,
    required this.dob,
    required this.fatherHusbandName,
    required this.gender,
    required this.maritalStatus,
    required this.occupation,
    required this.qualification,
    required this.profession,
    required this.email,
    required this.mobile,
    required this.houseNumber,
    required this.streetArea,
    required this.village,
    required this.city,
    required this.district,
    required this.state,
    required this.pinCode,
    this.landmark,
    required this.bloodGroup,
    required this.aadhaarNumber,
    this.role = 'user',
    this.createdAt,
    this.updatedAt,
    this.profileImageUrl,
    this.isVerified = false,
    this.membershipId,
  });

  // Get full name
  String get fullName {
    final parts = [firstName, middleName, lastName]
        .where((part) => part != null && part.isNotEmpty)
        .toList();
    return parts.join(' ');
  }

  // Get full address
  String get fullAddress {
    final parts = [
      houseNumber,
      streetArea,
      village,
      city,
      district,
      state,
      pinCode,
    ].where((part) => part.isNotEmpty).toList();
    
    if (landmark != null && landmark!.isNotEmpty) {
      parts.insert(2, 'Near $landmark');
    }
    
    return parts.join(', ');
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'name': fullName,
      'dob': dob,
      'fatherHusbandName': fatherHusbandName,
      'gender': gender,
      'maritalStatus': maritalStatus,
      'occupation': occupation,
      'qualification': qualification,
      'profession': profession,
      'email': email,
      'mobile': mobile,
      'houseNumber': houseNumber,
      'streetArea': streetArea,
      'village': village,
      'city': city,
      'district': district,
      'state': state,
      'pinCode': pinCode,
      'landmark': landmark,
      'address': fullAddress,
      'bloodGroup': bloodGroup,
      'aadhaarNumber': aadhaarNumber,
      'role': role,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'profileImageUrl': profileImageUrl,
      'isVerified': isVerified,
      'membershipId': membershipId,
    };
  }

  /// Create from Firestore snapshot
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      firstName: map['firstName'] ?? '',
      middleName: map['middleName'],
      lastName: map['lastName'],
      dob: map['dob'] ?? '',
      fatherHusbandName: map['fatherHusbandName'] ?? '',
      gender: map['gender'] ?? '',
      maritalStatus: map['maritalStatus'] ?? '',
      occupation: map['occupation'] ?? '',
      qualification: map['qualification'] ?? '',
      profession: map['profession'] ?? '',
      email: map['email'] ?? '',
      mobile: map['mobile'] ?? '',
      houseNumber: map['houseNumber'] ?? '',
      streetArea: map['streetArea'] ?? '',
      village: map['village'] ?? '',
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      state: map['state'] ?? '',
      pinCode: map['pinCode'] ?? '',
      landmark: map['landmark'],
      bloodGroup: map['bloodGroup'] ?? '',
      aadhaarNumber: map['aadhaarNumber'] ?? '',
      role: map['role'] ?? 'user',
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      profileImageUrl: map['profileImageUrl'],
      isVerified: map['isVerified'] ?? false,
      membershipId: map['membershipId'],
    );
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? firstName,
    String? middleName,
    String? lastName,
    String? dob,
    String? fatherHusbandName,
    String? gender,
    String? maritalStatus,
    String? occupation,
    String? qualification,
    String? profession,
    String? email,
    String? mobile,
    String? houseNumber,
    String? streetArea,
    String? village,
    String? city,
    String? district,
    String? state,
    String? pinCode,
    String? landmark,
    String? bloodGroup,
    String? aadhaarNumber,
    String? role,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? profileImageUrl,
    bool? isVerified,
    String? membershipId,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      dob: dob ?? this.dob,
      fatherHusbandName: fatherHusbandName ?? this.fatherHusbandName,
      gender: gender ?? this.gender,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      occupation: occupation ?? this.occupation,
      qualification: qualification ?? this.qualification,
      profession: profession ?? this.profession,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      houseNumber: houseNumber ?? this.houseNumber,
      streetArea: streetArea ?? this.streetArea,
      village: village ?? this.village,
      city: city ?? this.city,
      district: district ?? this.district,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      landmark: landmark ?? this.landmark,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isVerified: isVerified ?? this.isVerified,
      membershipId: membershipId ?? this.membershipId,
    );
  }
}
