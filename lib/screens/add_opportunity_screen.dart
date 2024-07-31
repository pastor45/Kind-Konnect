// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../constants.dart';
import '../models/activity.dart';
import '../models/volunteer_opportunity.dart';
import '../service/activity_service.dart';
import '../service/badge_service.dart';
import '../service/firestore_service.dart';
import 'dart:io';
import '../service/google_maps.dart';
import '../service/upload_images.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'home_screen.dart';

class AddOpportunityScreen extends StatefulWidget {
  const AddOpportunityScreen({super.key});

  @override
  _AddOpportunityScreenState createState() => _AddOpportunityScreenState();
}

class _AddOpportunityScreenState extends State<AddOpportunityScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _limitController = TextEditingController();

  String _category = '';
  final String _status = 'pending';
  final user = FirebaseAuth.instance.currentUser;
  final places = GoogleMapsPlaces(apiKey: googleMaps);

  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();

  LatLng? _currentPosition;
  GoogleMapController? _mapController;
  List<Prediction> _predictions = [];

  String? _city;

  void _onSearchChanged(String input) async {
    if (input.isNotEmpty) {
      PlacesAutocompleteResponse response = await places.autocomplete(
        input,
        types: ['address'],
        components: [Component(Component.country, 'US')],
      );

      if (response.isOkay) {
        setState(() {
          _predictions = response.predictions;
        });
      } else {
      }
    } else {
      setState(() {
        _predictions = [];
      });
    }
  }

  void _selectPlace(Prediction prediction) async {
    PlacesDetailsResponse detail =
        await places.getDetailsByPlaceId(prediction.placeId!);
    final lat = detail.result.geometry!.location.lat;
    final lng = detail.result.geometry!.location.lng;

    setState(() {
      _currentPosition = LatLng(lat, lng);
      _predictions = [];
    });

    _mapController?.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
    _getCityFromCoordinates(_currentPosition!);
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are denied.'),
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.'),
        ),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
    _getCityFromCoordinates(_currentPosition!);
  }

  void _getCityFromCoordinates(LatLng position) async {
    try {
      String? city =
          await getCityFromCoordinates(position.latitude, position.longitude);
      if (city != null) {
        setState(() {
          _city = city;
        });
      } else {}
    } catch (e) {
      ElegantNotification.error(description: const Text('Cannot get the city'))
          .show(context);
    }
  }

  final List<String> _categories = [
    'Animals',
    'Personal Aids',
    'Environment',
    'Education',
    'Health',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text("Saving data..."),
              ],
            ),
          );
        },
      );

      try {
        String opportunityId = const Uuid().v4();

        String chatGroupImageUrl = '';
        if (_images.isNotEmpty) {
          chatGroupImageUrl = await uploadImageToFirebase(_images[0]);
        }

        List<String> imageUrls = [];
        for (var i = 0; i < _images.length; i++) {
          String imageUrl = await uploadImageToFirebase(_images[i]);
          imageUrls.add(imageUrl);
        }

        final opportunity = VolunteerOpportunity(
          id: opportunityId,
          title: _titleController.text,
          description: _descriptionController.text,
          organization: _organizationController.text,
          date: DateTime.now(),
          location: _currentPosition != null
              ? '${_currentPosition!.latitude},${_currentPosition!.longitude}'
              : '',
          city: _city ?? '',
          imageUrls: imageUrls,
          creator: user!.email.toString(),
          category: _category,
          limit: int.parse(_limitController.text),
          status: _status,
          volunteers: [user!.email.toString()],
        );

        await Provider.of<FirestoreService>(context, listen: false)
            .addOpportunity(opportunity);

        await _createChatGroup(opportunity, chatGroupImageUrl, opportunityId);

        final activity = Activity(
          id: 'create_opportunity',
          name: 'Create Volunteer Opportunity',
          points: 50, 
        );

        final activityService =
            Provider.of<ActivityService>(context, listen: false);
        await activityService.completeActivity(user!.uid, activity);

        final badgeService = Provider.of<BadgeService>(context, listen: false);
        await badgeService.checkAndAwardBadges(user!.uid);
        ElegantNotification.success(
                description: const Text('Opportunity created'))
            .show(context);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
        );
      }
    }
  }

  Future<void> _createChatGroup(VolunteerOpportunity opportunity,
      String imageUrl, String opportunityId) async {
    final chatGroup = {
      'id': opportunityId,
      'name': opportunity.title,
      'groupPhotoUrl': imageUrl,
      'lastMessage': opportunity.title,
      'isGroup': true,
      'members': [user!.email],
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(opportunityId)
        .set(chatGroup);
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  final Color primaryColor = Colors.teal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Opportunity ',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor.withOpacity(0.1), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: <Widget>[
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) =>
                      value!.isEmpty ? 'Required field' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) =>
                      value!.isEmpty ? 'Required field' : null,
                ),
                TextFormField(
                  controller: _organizationController,
                  decoration: const InputDecoration(labelText: 'Organization'),
                  validator: (value) =>
                      value!.isEmpty ? 'Required field' : null,
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Category'),
                  value: _category.isNotEmpty ? _category : null,
                  items: _categories
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _category = value!;
                    });
                  },
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required field' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _limitController,
                  decoration:
                      const InputDecoration(labelText: 'Limit of Volunteer'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? 'Required field' : null,
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search for a location',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
                if (_predictions.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: _predictions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_predictions[index].description!),
                          onTap: () {
                            _selectPlace(_predictions[index]);
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 10),
                if (_currentPosition != null)
                  SizedBox(
                    height: 300,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _currentPosition!,
                        zoom: 14.0,
                      ),
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      markers: {
                        Marker(
                          markerId: const MarkerId('currentLocation'),
                          position: _currentPosition!,
                        ),
                      },
                      onTap: (position) {
                        setState(() {
                          _currentPosition = position;
                          _getCityFromCoordinates(position);
                        });
                      },
                    ),
                  )
                else
                  const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _images.map((image) {
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: FileImage(image),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Select Image',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
