import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteerOpportunity {
  final String id;
  final String creator;
  final String title;
  final String description;
  final String organization;
  final DateTime date;
  final String location;
  final String city;

  final List<String> imageUrls; 
  final List<String> volunteers;
  final Map<String, double> ratings;
  final String category;
  final int limit;
  String status; 

  VolunteerOpportunity({
    required this.id,
    required this.title,
    required this.creator,
    required this.city,
    required this.description,
    required this.organization,
    required this.date,
    required this.location,
    required this.imageUrls, 
    this.volunteers = const [],
    this.ratings = const {},
    required this.category,
    required this.limit,
    this.status = 'pending', 
  });

  factory VolunteerOpportunity.fromFirestore(Map<String, dynamic> data) {
    return VolunteerOpportunity(
      id: data['id'],
      title: data['title'],
      city: data['city'],
      creator: data['creator'],
      description: data['description'],
      organization: data['organization'],
      date: (data['date'] as Timestamp).toDate(),
      location: data['location'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      volunteers: List<String>.from(data['volunteers'] ?? []),
      ratings: Map<String, double>.from(data['ratings'] ?? {}),
      category: data['category'],
      limit: data['limit'],
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'city': city,
      'description': description,
      'organization': organization,
      'date': date,
      'creator': creator,
      'location': location,
      'imageUrls': imageUrls, 
      'volunteers': volunteers,
      'ratings': ratings,
      'category': category,
      'limit': limit,
      'status': status, 
    };
  }
}
