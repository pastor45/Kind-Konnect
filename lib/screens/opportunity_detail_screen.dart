// ignore_for_file: use_build_context_synchronously

import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../models/volunteer_opportunity.dart';
import '../service/firestore_service.dart';
import 'chat_screen.dart';

class OpportunityDetailScreen extends StatelessWidget {
  final VolunteerOpportunity opportunity;

  const OpportunityDetailScreen({super.key, required this.opportunity});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    final locationParts = opportunity.location.split(',');
    final latitude = double.parse(locationParts[0]);
    final longitude = double.parse(locationParts[1]);
    bool isUserParticipating =
        user != null && opportunity.volunteers.contains(user.email);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, user, firestoreService),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  _buildMapSection(latitude, longitude),
                  const SizedBox(height: 24),
                  _buildStatusSection(
                      context, opportunity, user, firestoreService),
                  const SizedBox(height: 24),
                  _buildActionButtons(context, opportunity, user,
                      firestoreService, isUserParticipating),
                  const SizedBox(height: 24),
                  if (isUserParticipating)
                    _buildRatingSection(context, opportunity, user,
                        firestoreService),

                  const SizedBox(height: 24),
                  _buildVolunteersList(
                      context, opportunity, user, firestoreService),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(
      BuildContext context, User? user, FirestoreService firestoreService) {
    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          opportunity.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black, blurRadius: 2)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            opportunity.imageUrls.isNotEmpty
                ? Image.network(
                    opportunity.imageUrls[0],
                    fit: BoxFit.cover,
                  )
                : Container(color: Colors.grey),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (opportunity.creator == user?.email)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteDialog(context, firestoreService),
          ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
                Icons.business, 'Organization', opportunity.organization),
            const Divider(height: 24),
            _buildInfoRow(
                Icons.description, 'Description', opportunity.description),
            const Divider(height: 24),
            _buildInfoRow(
                Icons.date_range, 'Creation Date', opportunity.date.toString()),
            const Divider(height: 24),
            _buildInfoRow(Icons.category, 'Category', opportunity.category),
            const Divider(height: 24),
            _buildInfoRow(Icons.people, 'Limit of Volunteers',
                opportunity.limit.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(
      BuildContext context,
      VolunteerOpportunity opportunity,
      User? user,
      FirestoreService firestoreService) {
    double? userRating = opportunity.ratings[user!.uid];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rate this Opportunity',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
        const SizedBox(height: 8),
        RatingBar.builder(
          initialRating: userRating ?? 0.0,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
          itemBuilder: (context, _) =>
              const Icon(Icons.star, color: Colors.amber),
          onRatingUpdate: (rating) async {
            await firestoreService.addRating(opportunity.id, user.uid, rating);
            await firestoreService.updateUserPoints(user.email!, 20);
            await firestoreService.checkAndAwardBadges(user.uid);

            ElegantNotification.success(
              title: const Text('Rating Submitted'),
              description: const Text('You have earned 20 points.'),
            ).show(context);
          },
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),
              const SizedBox(height: 4),
              if (content == 'in_progress')
                const Text('In Progress', style: TextStyle(fontSize: 16)),
              if (content != 'in_progress')
                Text(content, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection(double latitude, double longitude) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(latitude, longitude),
            zoom: 14.0,
          ),
          markers: {
            Marker(
              markerId: MarkerId(opportunity.id),
              position: LatLng(latitude, longitude),
            ),
          },
        ),
      ),
    );
  }

  Widget _buildStatusSection(
      BuildContext context,
      VolunteerOpportunity opportunity,
      User? user,
      FirestoreService firestoreService) {
    if (opportunity.creator == user?.email) {
      return _buildStatusDropdown(context, opportunity, user, firestoreService);
    } else {
      return _buildInfoRow(Icons.work_history, 'Status', opportunity.status);
    }
  }

  Widget _buildStatusDropdown(
      BuildContext context,
      VolunteerOpportunity opportunity,
      User? user,
      FirestoreService firestoreService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: Colors.blue.withOpacity(0.1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: opportunity.status,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
          isExpanded: true,
          items: _buildStatusDropdownItems(),
          onChanged: (String? newValue) async {
            if (newValue != null && opportunity.creator == user?.email) {
              await firestoreService.updateOpportunityStatus(
                  opportunity.id, newValue);
              _showStatusUpdatedNotification(context);
            }
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context,
      VolunteerOpportunity opportunity,
      User? user,
      FirestoreService firestoreService,
      bool isUserParticipating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!isUserParticipating)
          Expanded(
              child: _buildParticipateButton(
                  context, opportunity, user, firestoreService)),
        if (isUserParticipating && !(opportunity.creator == user?.email))
          Expanded(
              child: _buildUnsubscribeButton(
                  context, opportunity, user, firestoreService)),
      ],
    );
  }

  void _showStatusUpdatedNotification(BuildContext context) {
    ElegantNotification.success(
      title: const Text('Status Updated'),
      description: const Text('The status has been updated successfully.'),
    ).show(context);
  }

  List<DropdownMenuItem<String>> _buildStatusDropdownItems() {
    return [
      _buildDropdownItem('pending', Icons.pending, 'Pending', Colors.orange),
      _buildDropdownItem('in_progress', Icons.work, 'In Progress', Colors.blue),
      _buildDropdownItem(
          'completed', Icons.check_circle, 'Completed', Colors.green),
    ];
  }

  DropdownMenuItem<String> _buildDropdownItem(
      String value, IconData icon, String text, Color color) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildUnsubscribeButton(
      BuildContext context,
      VolunteerOpportunity opportunity,
      User? user,
      FirestoreService firestoreService) {
    return ElevatedButton(
      onPressed: () async {
        try {
          await firestoreService.leaveOpportunity(opportunity, user!.email!);
          ElegantNotification.success(
            title: const Text('You have unsubscribed!'),
            description: const Text('10 points have been deducted.'),
          ).show(context);
          Navigator.of(context).pop();
        } catch (e) {
          ElegantNotification.error(description: Text(e.toString()))
              .show(context);
        }
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: const Text('Unsubscribe',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildParticipateButton(
      BuildContext context,
      VolunteerOpportunity opportunity,
      User? user,
      FirestoreService firestoreService) {
    return ElevatedButton(
      onPressed: opportunity.volunteers.length < opportunity.limit
          ? () async {
              try {
                await firestoreService.joinOpportunity(
                    opportunity, user!.email!);
                ElegantNotification.success(
                  title: const Text('¡You have joined!'),
                  description: const Text('You have earned 10 points.'),
                ).show(context);
                Navigator.of(context).pop();
              } catch (e) {
                ElegantNotification.error(description: Text(e.toString()))
                    .show(context);
              }
            }
          : null,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: const Text('Participate',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildVolunteersList(
      BuildContext context,
      VolunteerOpportunity opportunity,
      User? user,
      FirestoreService firestoreService) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Volunteers:',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: opportunity.volunteers.length,
              itemBuilder: (context, index) {
                final volunteerEmail = opportunity.volunteers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(volunteerEmail[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(volunteerEmail),
                  trailing: IconButton(
                    icon: const Icon(Icons.message, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            receiverId: volunteerEmail,
                            receiverName:
                                volunteerEmail,
                            receiverPhotoUrl:
                                null, 
                            isGroup: false,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, FirestoreService firestoreService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Opportunity'),
          content:
              const Text('Are you sure you want to delete this opportunity?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                await firestoreService.deleteOpportunity(opportunity.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
