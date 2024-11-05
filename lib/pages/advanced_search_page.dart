import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wazaa_app/models/poi.dart';
import 'package:wazaa_app/services/event_notifier.dart';
import 'event_page.dart'; // Assurez-vous d'importer la page EventPage ici

class AdvancedSearchPage extends StatefulWidget {
  @override
  _AdvancedSearchPageState createState() => _AdvancedSearchPageState();
}

class _AdvancedSearchPageState extends State<AdvancedSearchPage> {
  TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  List<POI> _filteredEvents = [];
  bool _hasSearched = false;
  bool _isSearchButtonDisabled = true;
  String _sortOrder = 'chronological'; // Chronological by default
  bool _isGridView = true; // To toggle between list and grid view
  bool _isSearchSectionVisible = true; // To toggle search section visibility
  ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Méthode pour vérifier si le bouton "Rechercher" doit être activé
  void _updateSearchButtonState() {
    setState(() {
      _isSearchButtonDisabled = _searchController.text.isEmpty || _selectedDateRange == null;
    });
  }

  // Méthode pour filtrer les événements en fonction des critères
  void _filterEvents() {
    final eventNotifier = Provider.of<EventNotifier>(context, listen: false);
    final allEvents = eventNotifier.events;

    setState(() {
      _filteredEvents = allEvents.where((event) {
        final query = _searchController.text.toLowerCase();

        // Filtrage par mot-clé (dans le nom ou la description)
        bool matchesSearch = event.name.toLowerCase().contains(query) ||
            (event.description?.toLowerCase() ?? '').contains(query);

        // Filtrage par dates (obligatoire)
        if (_selectedDateRange != null) {
          DateTime eventStartDate = DateTime.parse(event.startDate);
          DateTime eventEndDate = DateTime.parse(event.endDate);

          bool matchesDateRange = eventStartDate.isBefore(_selectedDateRange!.end) &&
              eventEndDate.isAfter(_selectedDateRange!.start);
          return matchesSearch && matchesDateRange;
        }

        return false;
      }).toList();

      // Tri par ordre alphabétique ou chronologique
      _sortEvents();

      // Indiquer que l'utilisateur a effectué une recherche
      _hasSearched = true;

      // Réinitialiser la position du ScrollController en haut de la liste
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0); // Scroll directement en haut des résultats
      }
    });
  }

  // Méthode pour trier les événements par ordre chronologique ou alphabétique
  void _sortEvents() {
    if (_sortOrder == 'chronological') {
      _filteredEvents.sort((a, b) => DateTime.parse(a.startDate).compareTo(DateTime.parse(b.startDate)));
    } else {
      _filteredEvents.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
  }

  // Méthode pour afficher le sélecteur de date
  void _selectDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange ?? DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now().add(Duration(days: 7)),
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _updateSearchButtonState();
    }
  }

  // Méthode pour afficher un message si le bouton est désactivé
  void _showDisabledSearchMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Recherche non disponible'),
          content: Text(
            _searchController.text.isEmpty
                ? 'Veuillez entrer un mot-clé pour lancer la recherche.'
                : 'Veuillez sélectionner une plage de dates.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Méthode pour construire une carte d'événement en vue liste (sans image)
  Widget _buildListEventCard(POI event) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                fontFamily: 'Sora',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Color(0xFF666666)),
                    const SizedBox(width: 4),
                    Text(
                      event.location?.city ?? "Ville non spécifiée",
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(DateTime.parse(event.startDate)),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Méthode pour construire une carte d'événement en vue grille
  Widget _buildGridEventCard(POI event) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Partie concernant l'image de l'événement
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: event.photoUrl != null && event.photoUrl!.isNotEmpty
                  ? Image.network(
                      event.photoUrl!,
                      width: 130, // Largeur définie
                      height: double.infinity, // Remplit la hauteur de la carte
                      fit: BoxFit.cover, // Adapte l'image à l'espace
                      errorBuilder: (context, error, stackTrace) {
                        // Gestion d'erreur: affiche une image locale si l'URL échoue
                        return Image.asset(
                          'lib/assets/images/default_event_poster.png', // Image par défaut locale
                          width: 130,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      'lib/assets/images/default_event_poster.png', // Image par défaut locale
                      width: 130,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            // Détails de l'événement
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF333333),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description ?? "Aucune description disponible",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF888888),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Color(0xFF666666)),
                        const SizedBox(width: 4),
                        // Utilisation de Flexible pour le nom de la ville
                        Flexible(
                          child: Text(
                            event.location?.city ?? "Ville non spécifiée",
                            style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis, // Tronquer si le texte dépasse
                          ),
                        ),
                        Spacer(), // Ajout d'un Spacer pour séparer la ville et la date
                        Text(
                          DateFormat('dd/MM').format(DateTime.parse(event.startDate)),
                          style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Bouton stylé pour réafficher/masquer la section de recherche
          if (!_isSearchSectionVisible)
            Align(
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isSearchSectionVisible = true;
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
              ),
            ),

          // Zone supérieure blanche avec ombre
          if (_isSearchSectionVisible)
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 50, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Croix pour fermer la page
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                      ),
                      Spacer(),

                      // Titre de la page
                      Text(
                        'Recherche',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Sora',
                        ),
                      ),

                      Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSearchSectionVisible = !_isSearchSectionVisible; // Toggle visibility
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_up,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Barre de recherche et sélecteur de dates sur la même ligne
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              _updateSearchButtonState();
                            },
                            decoration: InputDecoration(
                              hintText: 'événement, thème, mot-clé...',
                              hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 15, color: Colors.grey[500]),
                              prefixIcon: Icon(Icons.search, color: Colors.black),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Sélecteur de date (uniquement l'icône)
                      GestureDetector(
                        onTap: _selectDateRange,
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(Icons.calendar_month, color: Colors.black, size: 24),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Bouton "Rechercher"
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF83402F), // Couleur gauche
                          Color(0xFFEA603E), // Couleur droite
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: ElevatedButton(
                      onPressed: _isSearchButtonDisabled
                          ? _showDisabledSearchMessage
                          : _filterEvents,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: Text(
                        'Rechercher',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tri et vue boutons
                  if (_hasSearched)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tri par Chronologique / A-Z
                        DropdownButton<String>(
                          value: _sortOrder,
                          items: [
                            DropdownMenuItem(
                              value: 'chronological',
                              child: Text('Chronologique'),
                            ),
                            DropdownMenuItem(
                              value: 'alphabetical',
                              child: Text('A-Z'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _sortOrder = value!;
                              _sortEvents();
                            });
                          },
                        ),

                        // Bouton Vue liste / grille
                        IconButton(
                          icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                          onPressed: () {
                            setState(() {
                              _isGridView = !_isGridView;
                            });
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),

          // Zone inférieure grise (à partir du nombre de résultats)
          Expanded(
            child: Container(
              color: Colors.grey[200], // Fond gris clair
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // Affichage du nombre de résultats
                  if (_hasSearched)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${_filteredEvents.length} résultat(s) trouvé(s)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Affichage des résultats
                  Expanded(
                    child: _hasSearched
                        ? _filteredEvents.isEmpty
                            ? Center(
                                child: Text(
                                  'Aucun événement trouvé',
                                  style: TextStyle(fontSize: 18, color: Colors.grey, fontFamily: 'Poppins'),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController, // Ajout du ScrollController ici
                                itemCount: _filteredEvents.length,
                                itemBuilder: (context, index) {
                                  final event = _filteredEvents[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EventPage(event: event),
                                        ),
                                      );
                                    },
                                    child: _isGridView
                                        ? _buildGridEventCard(event) // Vue cartes
                                        : _buildListEventCard(event), // Vue liste
                                  );
                                },
                              )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search, size: 80, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  'Recherchez des événements',
                                  style: TextStyle(fontSize: 22, color: Colors.black54, fontFamily: 'Sora'),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tapez un mot-clé et sélectionnez une plage de dates pour lancer votre recherche',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 15, color: Colors.grey[500], fontFamily: 'Poppins'),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}