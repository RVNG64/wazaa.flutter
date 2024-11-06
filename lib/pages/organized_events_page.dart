import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../services/event_service.dart';
import 'event_edit_page.dart';
import '../models/event.dart';
import './native_event_page.dart';
import './map_page.dart';
import './attendance_management_page.dart';

class OrganizedEventsPage extends StatefulWidget {
  @override
  _OrganizedEventsPageState createState() => _OrganizedEventsPageState();
}

class _OrganizedEventsPageState extends State<OrganizedEventsPage> {
  final EventService _eventService = EventService('http://10.0.2.2:3000');
  List<Event> _organizedEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrganizedEvents();
  }

  Future<void> _fetchOrganizedEvents() async {
    try {
      List<Event> events = await _eventService.fetchEventsOrganizedByUser();

      events.sort((a, b) {
        DateTime dateA = DateTime.tryParse(a.startDate ?? '') ?? DateTime(2100);
        DateTime dateB = DateTime.tryParse(b.startDate ?? '') ?? DateTime(2100);
        return dateA.compareTo(dateB);
      });

      setState(() {
        _organizedEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors de la récupération des événements organisés : $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _shareEvent(Event event) {
    String shareText = '${event.name}\n${event.description ?? ''}\nDate : ${event.startDate}\nLieu : ${event.location?['address'] ?? ''}';
    Share.share(shareText);
  }

  void _deleteEvent(BuildContext context, Event event) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer l\'événement'),
        content: Text('Êtes-vous sûr de vouloir supprimer cet événement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _eventService.deleteEvent(event.id);
        setState(() {
          _organizedEvents.remove(event);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Événement supprimé avec succès.')),
        );
      } catch (e) {
        print('Erreur lors de la suppression de l\'événement : $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression de l\'événement.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF205893), Color(0xFF16141E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapWithMarkersPage(),
                          ),
                        );
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
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Mes Événements',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Sora',
                      ),
                    ),
                  ),
                ),
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

                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _organizedEvents.isEmpty
                          ? Center(
                              child: Text(
                                'Vous n\'avez pas encore organisé d\'événement.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _organizedEvents.length,
                              itemBuilder: (context, index) {
                                Event event = _organizedEvents[index];
                                return EventCard(
                                  event: event,
                                  onDelete: () => _deleteEvent(context, event),
                                  onShare: () => _shareEvent(event),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  EventCard({required this.event, required this.onDelete, required this.onShare});

  @override
  Widget build(BuildContext context) {
    String formattedDate = event.startDate != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(event.startDate!))
        : 'Date non indiquée';

    String imageUrl = event.photoUrl ?? 'lib/assets/images/default_event_poster.png';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NativeEventPage(event: event),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              spreadRadius: 2,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'lib/assets/images/default_event_poster.png',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      'lib/assets/images/default_event_poster.png',
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      fontFamily: 'Sora',
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_city, size: 16, color: Colors.black87),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          event.location?['city'] ?? 'Ville inconnue',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.calendar_today, size: 16, color: Colors.black87),
                      SizedBox(width: 5),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  // Ajout de la ligne de séparation
                  Divider(
                    color: Colors.grey.shade400,
                    thickness: 1,
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(Icons.people, color: Colors.blueAccent),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AttendanceManagementPage(event: event),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.black87),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventEditPage(event: event),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.share, color: Colors.green),
                        onPressed: onShare,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
