import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import 'organized_events_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
enum PriceOption { unique, range }

class EventEditPage extends StatefulWidget {
  final Event event;

  EventEditPage({required this.event});

  @override
  _EventEditPageState createState() => _EventEditPageState();
}

class _EventEditPageState extends State<EventEditPage> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService('http://10.0.2.2:3000');
  final String _googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;

  // Contrôleurs pour les champs
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late TextEditingController _addressController;
  late TextEditingController _postalCodeController;
  late TextEditingController _cityController;
  late TextEditingController _capacityController;
  late TextEditingController _videoUrlController;
  late TextEditingController _websiteController;
  late TextEditingController _ticketLinkController;
  // Contrôleurs pour les réseaux sociaux
  Map<String, TextEditingController> _socialMediaControllers = {};
  Map<String, bool> _selectedSocialMedia = {};

  bool _isFree = true;
  final TextEditingController _uniquePriceController = TextEditingController();
  final TextEditingController _priceMinController = TextEditingController();
  final TextEditingController _priceMaxController = TextEditingController();

  // Variables pour les sélecteurs
  String? _selectedCategory;
  String? _selectedAudience;
  List<String> _selectedTags = [];
  final TextEditingController _tagController = TextEditingController();

  // Image sélectionnée
  File? _selectedImage;

  // Variables pour la localisation
  double? _latitude;
  double? _longitude;

  // Enumération pour les options de prix
  PriceOption? _selectedPriceOption;

  // Listes des catégories et audiences (exemple)
  final List<String> _categories = ['Musique', 'Sport', 'Art', 'Technologie', 'Autre'];
  final List<String> _audiences = ['Tout public', 'Famille', 'Adultes', 'Enfants', 'Professionnels'];

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

  // Listes des réseaux sociaux
  final List<String> _socialMediaOptions = ['Facebook', 'Instagram', 'Twitter', 'YouTube', 'TikTok'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _selectedCategory = widget.event.category;
    _selectedAudience = widget.event.audience;
    _selectedTags = widget.event.tags ?? [];
    _latitude = widget.event.location?['latitude'];
    _longitude = widget.event.location?['longitude'];
    _selectedAccessibilityOptions = widget.event.accessibilityOptions ?? [];
    _selectedPaymentMethods = widget.event.acceptedPayments ?? [];

    // Initialiser les contrôleurs pour les réseaux sociaux
    Map<String, dynamic> socialMedia = widget.event.socialMedia ?? {};

    for (String media in _socialMediaOptions) {
      String lowercaseMedia = media.toLowerCase();
      _socialMediaControllers[media] = TextEditingController(text: socialMedia[lowercaseMedia]);
      _selectedSocialMedia[media] = socialMedia.containsKey(lowercaseMedia);
    }
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.event.name);
    _descriptionController = TextEditingController(text: widget.event.description);
    _startDateController = TextEditingController(text: _formatDate(widget.event.startDate));
    _endDateController = TextEditingController(text: _formatDate(widget.event.endDate));
    _startTimeController = TextEditingController(text: widget.event.startTime);
    _endTimeController = TextEditingController(text: widget.event.endTime);
    _addressController = TextEditingController(text: widget.event.location?['address']);
    _postalCodeController = TextEditingController(text: widget.event.location?['postalCode']);
    _cityController = TextEditingController(text: widget.event.location?['city']);
    _capacityController = TextEditingController(text: widget.event.capacity?.toString());
    _videoUrlController = TextEditingController(text: widget.event.videoUrl);
    _websiteController = TextEditingController(text: widget.event.website);
    _ticketLinkController = TextEditingController(text: widget.event.ticketLink);

    // Initialisation des contrôleurs de prix
    _isFree = widget.event.priceOptions?['isFree'] ?? true;
    if (!_isFree) {
      _uniquePriceController.text = widget.event.priceOptions?['uniquePrice']?.toString() ?? '';
      _priceMinController.text = widget.event.priceOptions?['priceRange']?['min']?.toString() ?? '';
      _priceMaxController.text = widget.event.priceOptions?['priceRange']?['max']?.toString() ?? '';

      // Définir l'option de prix en fonction des données récupérées
      if (widget.event.priceOptions?['uniquePrice'] != null) {
        _selectedPriceOption = PriceOption.unique;
      } else if (widget.event.priceOptions?['priceRange'] != null) {
        _selectedPriceOption = PriceOption.range;
      }
    }
  }

  // Méthode pour sélectionner une image
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    DateTime date = DateTime.parse(dateStr);
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Méthodes pour sélectionner les dates et heures
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime initialDate = DateTime.now();
    if (controller.text.isNotEmpty) {
      initialDate = DateFormat('dd/MM/yyyy').parse(controller.text);
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    TimeOfDay initialTime = TimeOfDay.now();
    if (controller.text.isNotEmpty) {
      final parsedTime = DateFormat('HH:mm').parse(controller.text);
      initialTime = TimeOfDay(hour: parsedTime.hour, minute: parsedTime.minute);
    }

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

  void _updateEvent() async {
    if (_formKey.currentState!.validate()) {
      try {
        DateFormat dateFormat = DateFormat('dd/MM/yyyy');
        DateTime startDate = dateFormat.parse(_startDateController.text);
        DateTime endDate = dateFormat.parse(_endDateController.text);

        Map<String, dynamic> updatedData = {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'startTime': _startTimeController.text,
          'endTime': _endTimeController.text,
          'location': {
            'address': _addressController.text,
            'postalCode': _postalCodeController.text,
            'city': _cityController.text,
            'latitude': _latitude,
            'longitude': _longitude,
          },
          'priceOptions': {
            'uniquePrice': double.tryParse(_uniquePriceController.text),
            'priceRange': {
              'min': double.tryParse(_priceMinController.text),
              'max': double.tryParse(_priceMaxController.text),
            },
          },
          'capacity': int.tryParse(_capacityController.text),
          'category': _selectedCategory,
          'audience': _selectedAudience,
          'tags': _selectedTags,
          'videoUrl': _videoUrlController.text,
          'website': _websiteController.text,
          'ticketLink': _ticketLinkController.text,
          'socialMedia': {},
          'accessibilityOptions': _selectedAccessibilityOptions,
          'acceptedPayments': _selectedPaymentMethods,
        };

        // Ajouter les réseaux sociaux sélectionnés
        updatedData['socialMedia'] = {};
        _selectedSocialMedia.forEach((media, isSelected) {
          if (isSelected) {
            String link = _socialMediaControllers[media]?.text ?? '';
            if (link.isNotEmpty) {
              updatedData['socialMedia'][media.toLowerCase()] = link;
            }
          }
        });

        // Ajouter les options de prix
        if (!_isFree) {
          updatedData['priceOptions'] = {
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
          updatedData['priceOptions'] = {
            'isFree': true, // Ce champ doit être cohérent avec le type booléen
          };
        }

        if (_selectedImage != null) {
          String photoUrl = await _eventService.uploadImageToCloudinary(_selectedImage!);
          updatedData['photoUrl'] = photoUrl;
        }

        await _eventService.updateEvent(widget.event.id, updatedData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Événement mis à jour avec succès.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OrganizedEventsPage()),
        );
      } catch (e) {
        _showError('Erreur lors de la mise à jour de l\'événement.');
      }
    }
  }

  // Méthode pour afficher une erreur
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                radius: 2.5,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bouton retour stylisé
                      GestureDetector(
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
                      SizedBox(height: 30),
                      // Titre de la section
                      Text(
                        'Modifier l\'événement',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 10, bottom: 20),
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
                      SizedBox(height: 20),
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
                      SizedBox(height: 20),
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
                        title: Text('Événement gratuit', style: TextStyle(color: Colors.white)),
                        value: _isFree,
                        onChanged: (bool value) {
                          setState(() {
                            _isFree = value;
                            _selectedPriceOption = null;
                            _uniquePriceController.clear();
                            _priceMinController.clear();
                            _priceMaxController.clear();
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
                      SizedBox(height: 20),

                      _buildSectionTitle('Tags (max 3)'),
                      Wrap(
                        spacing: 8.0,
                        children: _selectedTags.map((tag) {
                          return Chip(
                            label: Text(tag, style: TextStyle(color: Colors.white)),
                            backgroundColor: Color(0xFF205893),
                            deleteIconColor: Colors.white,
                            onDeleted: () => _removeTag(tag),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(10),
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
                            _tagController.clear();
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
                      _buildSectionTitle('Visuels'),
                      GestureDetector(
                        onTap: _pickImage,
                        child: _selectedImage != null
                            ? Image.file(_selectedImage!, height: 200)
                            : widget.event.photoUrl != null && widget.event.photoUrl!.isNotEmpty
                                ? Image.network(widget.event.photoUrl!, height: 200)
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
                      Center(
                        child: ElevatedButton(
                          onPressed: _updateEvent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                          child: Text(
                            'Enregistrer les modifications',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontSize: 18,
                            ),
                          ),
                        ),
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

  Widget _buildTextFormField(
    TextEditingController controller,
    String label, {
    bool readOnly = false,
    void Function()? onTap,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
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
                    urlTemplate:
                        "https://api.mapbox.com/styles/v1/hervemake/clu1zgvkj00p601qsgono9buy/tiles/{z}/{x}/{y}?access_token={accessToken}",
                    additionalOptions: {
                      'accessToken':
                          'sk.eyJ1IjoiaGVydmVtYWtlIiwiYSI6ImNtMTUzeHBudjA1c3YydnM4NWozYmk3a2YifQ.8DsYqi5sX_-G7__icEAmjA',
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
            setState(() {
              if (selected!) {
                selectedOptions.add(option);
              } else {
                selectedOptions.remove(option);
              }
              onChanged(selectedOptions);
            });
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
