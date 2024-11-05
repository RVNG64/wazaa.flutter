// event_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/event_service.dart';
import 'package:http/http.dart' as http; // Ajouté pour les requêtes HTTP
import 'dart:convert'; // Pour le JSON
import 'package:flutter_map/flutter_map.dart'; // Pour la carte
import 'package:latlong2/latlong.dart'; // Pour les coordonnées
import 'package:geolocator/geolocator.dart'; // Pour la permission de localisation (optionnel)
import 'package:wazaa_app/pages/organized_events_page.dart';
enum PriceOption { unique, range }

class EventFormPage extends StatefulWidget {
  final bool isPublic;

  EventFormPage({required this.isPublic});

  @override
  _EventFormPageState createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs de texte
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  bool _isFree = true;
  final TextEditingController _uniquePriceController = TextEditingController();
  final TextEditingController _priceMinController = TextEditingController();
  final TextEditingController _priceMaxController = TextEditingController();

  // Variables pour les sélecteurs
  String? _selectedCategory;
  String? _selectedAudience;
  List<String> _selectedTags = [];

  // Ajout pour les coordonnées
  double? _latitude;
  double? _longitude;

  // Variables pour les options de paiement
  PriceOption? _selectedPriceOption;

  final String _googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;

  // Liste des catégories (exemple)
  final List<String> _categories = ['Musique', 'Sport', 'Art', 'Technologie', 'Autre'];

  // Liste des audiences possibles
  final List<String> _audiences = ['Tout public', 'Famille', 'Adultes', 'Enfants', 'Professionnels'];

  // Méthodes pour sélectionner les dates et heures
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime(2020);
    DateTime lastDate = DateTime(2100);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('fr', 'FR'), // Pour afficher le datePicker en français
    );

    if (picked != null) {
      setState(() {
        String formattedDate = DateFormat('dd/MM/yyyy').format(picked);
        controller.text = formattedDate;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    TimeOfDay initialTime = TimeOfDay.now();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        controller.text = picked.format(context);
      });
    }
  }

  // Méthode pour ajouter un tag
  void _addTag(String tag) {
    if (_selectedTags.length < 3 && !_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
      });
    } else if (_selectedTags.contains(tag)) {
      _showError('Ce tag a déjà été ajouté.');
    } else {
      _showError('Vous ne pouvez ajouter que 3 tags au maximum.');
    }
  }

  // Méthode pour supprimer un tag
  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  // Méthode pour géocoder l'adresse
  Future<void> _geocodeAddress() async {
    String fullAddress = '${_addressController.text}, ${_postalCodeController.text}, ${_cityController.text}';
    String encodedAddress = Uri.encodeComponent(fullAddress);
    String url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$_googleMapsApiKey';

    print('Requête vers l\'URL : $url'); // Ajoutez ce log

    final response = await http.get(Uri.parse(url));

    print('Statut de la réponse : ${response.statusCode}'); // Ajoutez ce log
    print('Corps de la réponse : ${response.body}'); // Ajoutez ce log

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'] != null && data['results'].length > 0) {
        final location = data['results'][0]['geometry']['location'];
        setState(() {
          _latitude = location['lat'];
          _longitude = location['lng'];
        });
      } else {
        _showError('Adresse introuvable.');
      }
    } else {
      _showError('Erreur lors du géocodage de l\'adresse.');
    }
  }

  // Méthode pour afficher une erreur
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Méthode pour enregistrer l'événement (brouillon ou continuer)
  void _saveEvent({bool continueCreation = false}) async {
    if (_formKey.currentState!.validate()) {
      DateFormat dateFormat = DateFormat('dd/MM/yyyy');
      DateTime? startDate;
      DateTime? endDate;

      try {
        startDate = dateFormat.parse(_startDateController.text);
        endDate = dateFormat.parse(_endDateController.text);
      } catch (e) {
        _showError('Veuillez entrer des dates valides.');
        return;
      }

      if (_latitude == null || _longitude == null) {
        await _geocodeAddress();
        if (_latitude == null || _longitude == null) {
          _showError('Veuillez vérifier votre adresse.');
          return;
        }
      }

      // Récupérer les données du formulaire
      Map<String, dynamic> eventData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'startDate': _startDateController.text,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'endTime': _endTimeController.text,
        'location': {
          'address': _addressController.text,
          'postalCode': _postalCodeController.text,
          'city': _cityController.text,
          'latitude': _latitude,
          'longitude': _longitude,
        },
        'priceOptions': {
          'isFree': _isFree,
          'uniquePrice': null,
          'priceRange': null,
        },
        'capacity': int.tryParse(_capacityController.text),
        'category': _selectedCategory,
        'audience': _selectedAudience,
        'tags': _selectedTags,
        'type': widget.isPublic ? 'public' : 'private',
      };

      if (!_isFree) {
        eventData['priceOptions'] = {
          'uniquePrice': _selectedPriceOption == PriceOption.unique
              ? double.tryParse(_uniquePriceController.text)
              : null,
          'priceRange': _selectedPriceOption == PriceOption.range
              ? {
                  'min': double.tryParse(_priceMinController.text),
                  'max': double.tryParse(_priceMaxController.text),
                }
              : null,
        };
      } else {
        eventData['priceOptions'] = {
          'isFree': true, // Ce champ doit être cohérent avec le type booléen
        };
      }

      if (continueCreation) {
        // Continuer la création (passer à la partie 2)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventFormPart2(eventData: eventData),
          ),
        );
      } else {
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Événement sauvegardé en tant que brouillon.')),
        );

        // Rediriger vers la page des événements organisés
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrganizedEventsPage(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fond en dégradé radial
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 2.4,
                colors: [
                  Color(0xFF205893),
                  Color(0xFF16141E),
                ],
                stops: [0.1, 0.9],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 40, bottom: 32),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bouton retour stylisé
                      Align(
                        alignment: Alignment.topLeft,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      // Titre de la section
                      Text(
                        'Événement ${widget.isPublic ? 'public' : 'privé'}',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: 100,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      // Informations Générales
                      _buildSectionTitle('Informations Générales'),
                      _buildTextFormField(_nameController, 'Nom de l\'événement *', validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom d\'événement';
                        }
                        return null;
                      }),
                      _buildTextFormField(_descriptionController, 'Description', maxLines: 3),
                      SizedBox(height: 20),
                      // Date et Heure
                      _buildSectionTitle('Date et Heure'),
                      _buildDateAndTimeFields(),
                      // Localisation
                      _buildSectionTitle('Localisation'),
                      _buildTextFormField(_addressController, 'Adresse'),
                      _buildTextFormField(_postalCodeController, 'Code postal'),
                      _buildTextFormField(_cityController, 'Ville'),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _geocodeAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Valider l\'adresse',
                          style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildMapPreview(),
                      const SizedBox(height: 20),

                      _buildSectionTitle('Audience et Catégorie'),
                      _buildDropdownField('Catégorie', _categories, _selectedCategory, (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }),
                      _buildDropdownField('Audience', _audiences, _selectedAudience, (value) {
                        setState(() {
                          _selectedAudience = value;
                        });
                      }),
                      SizedBox(height: 20),

                      _buildSectionTitle('Tarifs'),
                      SwitchListTile(
                        title: Text(
                          'Événement gratuit',
                          style: TextStyle(color: Colors.white),
                        ),
                        value: _isFree,
                        onChanged: (bool value) {
                          setState(() {
                            _isFree = value;
                            _selectedPriceOption = null;
                          });
                        },
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.blueAccent,
                      ),

                      if (!_isFree) ...[
                        Text(
                          'Choisissez une option de prix',
                          style: TextStyle(color: Colors.white),
                        ),
                        ListTile(
                          title: Text('Prix unique', style: TextStyle(color: Colors.white)),
                          leading: Radio<PriceOption>(
                            value: PriceOption.unique,
                            groupValue: _selectedPriceOption,
                            onChanged: (PriceOption? value) {
                              setState(() {
                                _selectedPriceOption = value;
                              });
                            },
                          ),
                        ),
                        ListTile(
                          title: Text('Prix variable', style: TextStyle(color: Colors.white)),
                          leading: Radio<PriceOption>(
                            value: PriceOption.range,
                            groupValue: _selectedPriceOption,
                            onChanged: (PriceOption? value) {
                              setState(() {
                                _selectedPriceOption = value;
                              });
                            },
                          ),
                        ),
                        if (_selectedPriceOption == PriceOption.unique)
                          _buildTextFormField(
                            _uniquePriceController,
                            'Prix unique',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_selectedPriceOption == PriceOption.unique && (value == null || value.isEmpty)) {
                                return 'Veuillez entrer un prix unique';
                              } else if (value != null && double.tryParse(value) == null) {
                                return 'Veuillez entrer un nombre valide';
                              }
                              return null;
                            },
                          ),
                        if (_selectedPriceOption == PriceOption.range)
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextFormField(
                                  _priceMinController,
                                  'Prix minimum',
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (_selectedPriceOption == PriceOption.range && (value == null || value.isEmpty)) {
                                      return 'Veuillez entrer un prix minimum';
                                    } else if (value != null && double.tryParse(value) == null) {
                                      return 'Veuillez entrer un nombre valide';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildTextFormField(
                                  _priceMaxController,
                                  'Prix maximum',
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (_selectedPriceOption == PriceOption.range && (value == null || value.isEmpty)) {
                                      return 'Veuillez entrer un prix maximum';
                                    } else if (value != null && double.tryParse(value) == null) {
                                      return 'Veuillez entrer un nombre valide';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                      ],

                      _buildSectionTitle('Tags (max 3)'),
                      Wrap(
                        spacing: 8.0,
                        children: _selectedTags.map((tag) {
                          return Chip(
                            label: Text(
                              tag,
                              style: TextStyle(
                                color: Colors.white, // Couleur du texte
                                fontWeight: FontWeight.bold, // Optionnel pour rendre le texte plus visible
                              ),
                            ),
                            backgroundColor: Color(0xFF205893), // Couleur de fond du tag
                            deleteIconColor: Colors.white, // Couleur de la croix de suppression
                            onDeleted: () => _removeTag(tag),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.white, width: 1), // Bordure blanche
                              borderRadius: BorderRadius.circular(10), // Arrondi des bords
                            ),
                          );
                        }).toList(),
                      ),
                      TextFormField(
                        controller: _tagController,
                        decoration: InputDecoration(
                          labelText: 'Ajouter un tag',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.black54,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        onFieldSubmitted: (value) {
                          if (value.isNotEmpty) {
                            _addTag(value.trim());
                            _tagController.clear(); // Efface le champ après l'ajout
                          }
                        },
                      ),
                      SizedBox(height: 20),
                      _buildSectionTitle('Capacité'),
                      _buildTextFormField(
                        _capacityController,
                        'Capacité (nombre de participants)',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer la capacité';
                          } else if (int.tryParse(value) == null) {
                            return 'Veuillez entrer un nombre valide';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => _saveEvent(continueCreation: false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            ),
                            child: Text('Enregistrer et quitter', style: TextStyle(color: Colors.black, fontFamily: 'Poppins')),
                          ),
                          ElevatedButton(
                            onPressed: () => _saveEvent(continueCreation: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            ),
                            child: Text('Continuer', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour afficher un champ de texte avec style personnalisé
  Widget _buildTextFormField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text, // Ajoutez ceci
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType, // Ajoutez ceci pour l'utiliser
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.black54,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
        style: TextStyle(color: Colors.white),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String? selectedValue, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.black54,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
        dropdownColor: Colors.black54,
        value: selectedValue,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: TextStyle(color: Colors.white)),
          );
        }).toList(),
        onChanged: onChanged,
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  // Méthode pour afficher la carte si les coordonnées sont disponibles
  Widget _buildMapPreview() {
    return _latitude != null && _longitude != null
        ? Container(
            height: 200,
            margin: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(_latitude!, _longitude!),
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://api.mapbox.com/styles/v1/hervemake/clu1zgvkj00p601qsgono9buy/tiles/{z}/{x}/{y}?access_token={accessToken}",
                    additionalOptions: {
                      'accessToken': 'sk.eyJ1IjoiaGVydmVtYWtlIiwiYSI6ImNtMTUzeHBudjA1c3YydnM4NWozYmk3a2YifQ.8DsYqi5sX_-G7__icEAmjA',
                    },
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_latitude!, _longitude!),
                        child: Icon(Icons.location_pin, color: Colors.red, size: 40),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        : Container();
  }

  // Méthode pour afficher les titres des sections
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Sora',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // Méthode pour afficher les champs de date et heure
  Widget _buildDateAndTimeFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectDate(context, _startDateController),
                child: AbsorbPointer(
                  child: _buildTextFormField(_startDateController, 'Date de début *', validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner une date de début';
                    }
                    return null;
                  }),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => _selectDate(context, _endDateController),
                child: AbsorbPointer(
                  child: _buildTextFormField(_endDateController, 'Date de fin *', validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner une date de fin';
                    }
                    return null;
                  }),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectTime(context, _startTimeController),
                child: AbsorbPointer(
                  child: _buildTextFormField(_startTimeController, 'Heure de début'),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => _selectTime(context, _endTimeController),
                child: AbsorbPointer(
                  child: _buildTextFormField(_endTimeController, 'Heure de fin'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Classe pour la Partie 2 du formulaire (inchangée)
class EventFormPart2 extends StatefulWidget {
  final Map<String, dynamic> eventData;

  EventFormPart2({required this.eventData});

  @override
  _EventFormPart2State createState() => _EventFormPart2State();
}

class _EventFormPart2State extends State<EventFormPart2> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService('https://wazaapp-backend-e95231584d01.herokuapp.com');
  List<String> _selectedPaymentMethods = [];

  // Contrôleurs pour les champs de la Partie 2
  File? _selectedImage;
  final TextEditingController _videoUrlController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _ticketLinkController = TextEditingController();

  // Listes des réseaux sociaux
  final List<String> _socialMediaOptions = ['Facebook', 'Instagram', 'Twitter', 'YouTube', 'TikTok', 'LinkedIn'];
  Map<String, TextEditingController> _socialMediaControllers = {};
  Map<String, bool> _selectedSocialMedia = {};

  @override
  void initState() {
    super.initState();
    for (String media in _socialMediaOptions) {
      _socialMediaControllers[media] = TextEditingController();
      _selectedSocialMedia[media] = false;
    }
  }

  @override
  void dispose() {
    _videoUrlController.dispose();
    _websiteController.dispose();
    _ticketLinkController.dispose();
    _socialMediaControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  // Méthode pour sélectionner une image
  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // Méthode pour soumettre le formulaire
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Ajouter les données de la Partie 2 à eventData
      widget.eventData['videoUrl'] = _videoUrlController.text;
      widget.eventData['website'] = _websiteController.text;
      widget.eventData['ticketLink'] = _ticketLinkController.text;
      widget.eventData['acceptedPayments'] = _selectedPaymentMethods;

      // Récupérer les réseaux sociaux sélectionnés avec leurs liens
      Map<String, String> socialMediaLinks = {};
      _selectedSocialMedia.forEach((media, isSelected) {
        if (isSelected) {
          String link = _socialMediaControllers[media]?.text ?? '';
          if (link.isNotEmpty) {
            socialMediaLinks[media.toLowerCase()] = link;
          }
        }
      });
      widget.eventData['socialMedia'] = socialMediaLinks;

      // Gérer l'upload de l'image si elle est sélectionnée
      if (_selectedImage != null) {
        String photoUrl = await _eventService.uploadImageToCloudinary(_selectedImage!);
        widget.eventData['photoUrl'] = photoUrl;
      }

      // Envoyer les données complètes au backend
      await _eventService.createEvent(widget.eventData);

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Événement créé avec succès !')),
      );

      // Naviguer vers la page des événements organisés
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrganizedEventsPage(),
        ),
      );
    }
  }

  // Méthode pour afficher les titres des sections
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Méthode pour afficher un champ de texte avec style personnalisé
  Widget _buildTextFormField(TextEditingController controller, String label,
      {int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.black54,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
        style: TextStyle(color: Colors.white),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fond en dégradé radial
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 2.0,
                colors: [
                  Color(0xFF205893),
                  Color(0xFF16141E),
                ],
                stops: [0.3, 0.6],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 40, bottom: 32),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bouton retour stylisé
                      Align(
                        alignment: Alignment.topLeft,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      // Titre de la section
                      Text(
                        'Événement - Partie 2',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: 100,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildSectionTitle('Visuels'),
                      GestureDetector(
                        onTap: _pickImage,
                        child: _selectedImage != null
                            ? Image.file(_selectedImage!, height: 200)
                            : Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                                child: Center(
                                  child: Icon(Icons.add_a_photo, size: 50, color: Colors.white70),
                                ),
                              ),
                      ),
                      SizedBox(height: 20),
                      _buildTextFormField(_videoUrlController, 'Lien vidéo'),
                      _buildSectionTitle('Site Web et Billetterie'),
                      _buildTextFormField(_websiteController, 'Site web'),
                      _buildTextFormField(_ticketLinkController, 'Lien billetterie'),
                      /*_buildSectionTitle('Réseaux Sociaux'),
                      Column(
                        children: _socialMediaOptions.map((media) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CheckboxListTile(
                                title: Text(
                                  media,
                                  style: TextStyle(color: Colors.white),
                                ),
                                value: _selectedSocialMedia[media],
                                activeColor: Colors.green,
                                checkColor: Colors.white,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _selectedSocialMedia[media] = value ?? false;
                                  });
                                },
                              ),
                              if (_selectedSocialMedia[media] == true)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: _buildTextFormField(
                                    _socialMediaControllers[media]!,
                                    'Lien $media',
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer le lien $media';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 20), */
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EventFormPart3(eventData: widget.eventData),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                            ),
                            child: Text(
                              'Continuer',
                              style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w900, fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EventFormPart3 extends StatefulWidget {
  final Map<String, dynamic> eventData;

  EventFormPart3({required this.eventData});

  @override
  _EventFormPart3State createState() => _EventFormPart3State();
}

class _EventFormPart3State extends State<EventFormPart3> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService('https://wazaapp-backend-e95231584d01.herokuapp.com');
  final List<String> _socialMediaOptions = ['Facebook', 'Instagram', 'Twitter', 'YouTube', 'TikTok'];
  Map<String, TextEditingController> _socialMediaControllers = {};
  Map<String, bool> _selectedSocialMedia = {};

  // Listes pour les options d'accessibilité et moyens de paiement
  final List<String> _accessibilityOptions = [
    'Accès personnes à mobilité réduite',
    'Parking disponible',
    'Transports en commun à proximité',
    'Toilettes',
    'Assistance auditive',
    'Ascenseur',
  ];
  final List<String> _paymentMethods = [
    'Espèces',
    'Chèque',
    'Carte de crédit',
    'PayPal',
    'Apple Pay',
    'Google Pay',
    'Tickets restaurant',
    'Virement bancaire',
    'Cryptomonnaies',
  ];

  // Variables pour stocker les options sélectionnées
  List<String> _selectedAccessibilityOptions = [];
  List<String> _selectedPaymentMethods = [];

  // Méthode pour soumettre le formulaire
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Ajouter les options sélectionnées à eventData
      widget.eventData['accessibilityOptions'] = _selectedAccessibilityOptions;
      widget.eventData['acceptedPayments'] = _selectedPaymentMethods;
      Map<String, String> socialMediaLinks = {};
      _selectedSocialMedia.forEach((media, isSelected) {
        if (isSelected) {
          String link = _socialMediaControllers[media]?.text ?? '';
          if (link.isNotEmpty) {
            socialMediaLinks[media.toLowerCase()] = link;
          }
        }
      });
      widget.eventData['socialMedia'] = socialMediaLinks;

      // Envoyer les données complètes au backend
      await _eventService.createEvent(widget.eventData);

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Événement créé avec succès !')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrganizedEventsPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fond en dégradé radial
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 2.0,
                colors: [
                  Color(0xFF205893),
                  Color(0xFF16141E),
                ],
                stops: [0.3, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 40, bottom: 32),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bouton retour stylisé
                      Align(
                        alignment: Alignment.topLeft,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      // Titre de la section
                      Text(
                        'Événement - Partie 3',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: 100,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildSectionTitle('Options d\'Accessibilité'),
                      _buildCheckboxList(
                        options: _accessibilityOptions,
                        selectedOptions: _selectedAccessibilityOptions,
                        onChanged: (selected) {
                          setState(() {
                            _selectedAccessibilityOptions = selected;
                          });
                        },
                      ),
                      _buildSectionTitle('Moyens de Paiement Acceptés'),
                      _buildCheckboxList(
                        options: _paymentMethods,
                        selectedOptions: _selectedPaymentMethods,
                        onChanged: (selected) {
                          setState(() {
                            _selectedPaymentMethods = selected;
                          });
                        },
                      ),
                      SizedBox(height: 20),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 20), // Pour ajouter un espace par rapport au contenu supérieur
                          Container(
                            margin: EdgeInsets.only(bottom: 40), // Espace en bas
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blueAccent, Colors.purpleAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: Colors.white, width: 2), // Bordure blanche
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: Offset(0, 10), // Effet de surélévation
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                // Logique pour créer l'événement
                                _submitForm();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent, 
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              child: Text(
                                'Créer l\'événement',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour afficher les titres des sections
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Sora',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // Méthode pour construire une liste de cases à cocher
  Widget _buildCheckboxList({
    required List<String> options,
    required List<String> selectedOptions,
    required Function(List<String>) onChanged,
  }) {
    return Column(
      children: options.map((option) {
        return CheckboxListTile(
          title: Text(
            option,
            style: TextStyle(color: Colors.white),
          ),
          value: selectedOptions.contains(option),
          activeColor: Colors.green,
          checkColor: Colors.white,
          onChanged: (selected) {
            List<String> newSelected = List.from(selectedOptions);
            if (selected!) {
              newSelected.add(option);
            } else {
              newSelected.remove(option);
            }
            onChanged(newSelected);
          },
          controlAffinity: ListTileControlAffinity.leading,
          tileColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 10),
          selectedTileColor: Colors.black54,
        );
      }).toList(),
    );
  }
}
