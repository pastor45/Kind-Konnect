// ignore_for_file: library_private_types_in_public_api

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/volunteer_opportunity.dart';
import '../service/firestore_service.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import 'add_opportunity_screen.dart';
import 'chatbot_screen.dart';
import 'home_screen.dart';
import 'opportunity_detail_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:page_transition/page_transition.dart';

import 'profile_screen.dart';

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  _OpportunitiesScreenState createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  int _currentIndex = 1; 
  bool _showSubscribedOnly = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    setState(() {});
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = const HomeScreen();
        break;
      case 1:
        nextScreen =
            const OpportunitiesScreen(); 
        break;
      case 2:
        nextScreen = const ProfileScreen(); 
        break;
      case 3:
        nextScreen = const ChatbotScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageTransition(
        type: PageTransitionType.fade,
        child: nextScreen,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  String _selectedCategory = 'All';
  double _selectedRating = 0;
  String _selectedStatus = 'All';
  final List<String> _categories = [
    'All',
    'Animals',
    'Personal Aids',
    'Environment',
    'Education',
    'Health',
    'Others',
  ];
  final List<String> _statuses = ['All', 'Pending', 'In Progress', 'Completed'];

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String email = user?.email ?? '';
    final firestoreService = Provider.of<FirestoreService>(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.teal,
        elevation: 0,
        title: const Text(
          'Volunteer Opportunities',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Tooltip(
            message: _showSubscribedOnly
                ? "Show all opportunities"
                : "Show only subscribed opportunities",
            child: IconButton(
              icon: Icon(
                _showSubscribedOnly
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _showSubscribedOnly = !_showSubscribedOnly;
                });
              },
            ),
          ),
          Tooltip(
            message: 'Create opportunities',
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _navigateToAddOpportunity(context),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal, Colors.teal.shade50],
          ),
        ),
        child: Column(
          children: [
            _buildFilters(),
            const SizedBox(
              height: 20,
            ),
            _buildOpportunitiesList(firestoreService, email),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildOpportunitiesList(
      FirestoreService firestoreService, String userEmail) {
    return StreamBuilder<List<VolunteerOpportunity>>(
      stream: _showSubscribedOnly
          ? firestoreService.getSubscribedOpportunities(userEmail)
          : firestoreService.getOpportunities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final opportunities = snapshot.data ?? [];

        return FutureBuilder<List<VolunteerOpportunity>>(
          future: _getFilteredOpportunities(opportunities, firestoreService),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final filteredOpportunities = snapshot.data ?? [];
            final double screenHeight = MediaQuery.of(context).size.height;

            return CarouselSlider.builder(
              itemCount: filteredOpportunities.length,
              itemBuilder: (context, index, realIndex) {
                return _buildOpportunityCard(
                  context,
                  filteredOpportunities[index],
                  firestoreService,
                );
              },
              options: CarouselOptions(
                height: screenHeight * 0.6,
                aspectRatio: 16 / 9,
                viewportFraction: 0.8,
                initialPage: 0,
                enableInfiniteScroll: true,
                reverse: false,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 3),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                autoPlayCurve: Curves.fastOutSlowIn,
                enlargeCenterPage: true,
                scrollDirection: Axis.horizontal,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.filter_list, size: 18),
                SizedBox(width: 8),
                Text('Filters',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                    child: _buildDropdown(
                  value: _selectedCategory,
                  items: _categories,
                  onChanged: (String? newValue) =>
                      setState(() => _selectedCategory = newValue!),
                  hint: 'Category',
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildDropdown(
                  value: _selectedStatus,
                  items: _statuses,
                  onChanged: (String? newValue) =>
                      setState(() => _selectedStatus = newValue!),
                  hint: 'Status',
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Min rating:', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                RatingBar.builder(
                  initialRating: _selectedRating,
                  minRating: 0,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 20,
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (rating) =>
                      setState(() => _selectedRating = rating),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          hint: Text(hint),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
        ),
      ),
    );
  }

  Widget _buildOpportunityCard(BuildContext context,
      VolunteerOpportunity opportunity, FirestoreService firestoreService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            opportunity.imageUrls.isNotEmpty
                ? Image.network(
                    opportunity.imageUrls.first,
                    height: 420,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildErrorImage(),
                  )
                : _buildErrorImage(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      opportunity.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      opportunity.organization,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _buildInfoIcon(Icons.category, opportunity.category),
                        _buildInfoIcon(Icons.calendar_today,
                            _formatDate(opportunity.date)),
                        _buildInfoIcon(Icons.location_on,
                            _formatLocation(opportunity.city)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRatingBar(firestoreService, opportunity.id),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      _navigateToOpportunityDetails(context, opportunity),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoIcon(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorImage() {
    return Container(
      height: 200,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image_not_supported, color: Colors.teal, size: 50),
      ),
    );
  }

  Future<List<VolunteerOpportunity>> _getFilteredOpportunities(
      List<VolunteerOpportunity> opportunities,
      FirestoreService firestoreService) async {
    var filtered = opportunities.where((opportunity) {
      final categoryMatch = _selectedCategory == 'All' ||
          opportunity.category == _selectedCategory;
      final statusMatch = _selectedStatus == 'All' ||
          opportunity.status == _selectedStatus.toLowerCase();
      return categoryMatch && statusMatch;
    }).toList();
    var ratings = await Future.wait(filtered.map((opportunity) =>
        firestoreService.getAverageRating(opportunity.id).first));

    return filtered.where((opportunity) {
      var index = filtered.indexOf(opportunity);
      return ratings[index] >= _selectedRating;
    }).toList();
  }

  Widget _buildRatingBar(
      FirestoreService firestoreService, String opportunityId) {
    return StreamBuilder<double>(
      stream: firestoreService.getAverageRating(opportunityId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final averageRating = snapshot.data ?? 0.0;
        return RatingBarIndicator(
          rating: averageRating,
          itemPadding: const EdgeInsets.only(left: 10),
          itemBuilder: (context, _) => _buildRatingIcon(),
          itemCount: 5,
          itemSize: 25.0,
          direction: Axis.horizontal,
        );
      },
    );
  }

  Widget _buildRatingIcon() {
    return Image.asset(
      'assets/heart.png',
      height: 30.0,
      width: 30.0,
      color: const Color.fromARGB(255, 255, 40, 7),
    );
  }

  void _navigateToAddOpportunity(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const AddOpportunityScreen(),
    ));
  }

  void _navigateToOpportunityDetails(
      BuildContext context, VolunteerOpportunity opportunity) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => OpportunityDetailScreen(opportunity: opportunity),
    ));
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  String _formatLocation(String location) {
    List<String> parts = location.split(',');
    if (parts.length >= 2) {
      return "${parts[0]}, ${parts[1]}";
    }
    return location;
  }
}
