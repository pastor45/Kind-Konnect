import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Badge {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final int requiredPoints;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.requiredPoints,
  });

  factory Badge.fromDocument(DocumentSnapshot doc) {
    return Badge(
      id: doc.id,
      name: doc['name'],
      description: doc['description'],
      iconUrl: doc['iconUrl'],
      requiredPoints: doc['requiredPoints'],
    );
  }
}

final Map<String, Map<String, dynamic>> badgeInfo = {
  'newcomer': {
    'icon': Icons.emoji_events,
    'description': 'Newcomer: Awarded when you create your first opportunity'
  },
  'active_contributor': {
    'icon': Icons.star,
    'description':
        'Active Contributor: Awarded when you create 10 opportunities'
  },
  'veteran': {
    'icon': Icons.military_tech,
    'description': 'Veteran: Awarded when you create 50 opportunities'
  },
  'first_participation': {
    'icon': Icons.volunteer_activism,
    'description':
        'First Step: Awarded for participating in your first volunteer opportunity'
  },
  'social_butterfly': {
    'icon': Icons.people,
    'description':
        'Social Butterfly: Awarded for participating in 5 different types of volunteer activities'
  },
  'eco_warrior': {
    'icon': Icons.eco,
    'description':
        'Eco Warrior: Awarded for participating in 10 environmental volunteer activities'
  },
  'animal_lover': {
    'icon': Icons.pets,
    'description':
        'Animal Lover: Awarded for participating in 5 animal welfare volunteer activities'
  },
  'community_pillar': {
    'icon': Icons.location_city,
    'description':
        'Community Pillar: Awarded for participating in 15 community development activities'
  },
  'education_champion': {
    'icon': Icons.school,
    'description':
        'Education Champion: Awarded for participating in 10 educational volunteer activities'
  },
  'health_hero': {
    'icon': Icons.health_and_safety,
    'description':
        'Health Hero: Awarded for participating in 10 health-related volunteer activities'
  },
  'disaster_responder': {
    'icon': Icons.warning,
    'description':
        'Disaster Responder: Awarded for participating in a disaster relief effort'
  },
  'fundraising_star': {
    'icon': Icons.attach_money,
    'description':
        'Fundraising Star: Awarded for helping raise over 1000 for charitable causes'
  },
  'long_term_commitment': {
    'icon': Icons.access_time,
    'description':
        'Long-term Commitment: Awarded for volunteering with the same organization for over a year'
  },
  'leadership': {
    'icon': Icons.group_add,
    'description':
        'Leadership: Awarded for organizing and leading a volunteer group'
  },
  'global_citizen': {
    'icon': Icons.public,
    'description':
        'Global Citizen: Awarded for participating in an international volunteer opportunity'
  },
  'tech_for_good': {
    'icon': Icons.computer,
    'description':
        'Tech for Good: Awarded for using technology skills in volunteer work'
  },
  'art_and_culture': {
    'icon': Icons.palette,
    'description':
        'Art & Culture Enthusiast: Awarded for participating in 5 arts or cultural preservation activities'
  },
  'senior_support': {
    'icon': Icons.elderly,
    'description':
        'Senior Support: Awarded for dedicating 50 hours to helping elderly community members'
  },
  'youth_mentor': {
    'icon': Icons.child_care,
    'description':
        'Youth Mentor: Awarded for mentoring young people for over 100 hours'
  },
  'quitter': {
    'icon': Icons.exit_to_app,
    'description': 'quitter: Awarded for giving up an opportunity'
  },
};
