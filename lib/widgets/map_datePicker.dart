import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CustomDateRangePicker extends StatefulWidget {
  @override
  _CustomDateRangePickerState createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<CustomDateRangePicker> {
  DateTime? startDate;
  DateTime? endDate;
  DateTime focusedDay = DateTime.now();
  CalendarFormat format = CalendarFormat.month;

  OverlayEntry? _overlayEntry; // Overlay for ephemeral message

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder( // Utilisation de LayoutBuilder pour mieux gérer la taille
      builder: (context, constraints) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            width: constraints.maxWidth * 0.95, // Assurez-vous que la largeur est de 95% de l'écran
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Date",
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Sélecteur de date avec TableCalendar
                TableCalendar(
                  locale: 'fr_FR', // Changer la langue du calendrier en français
                  focusedDay: focusedDay,
                  firstDay: DateTime(2021),
                  lastDay: DateTime(2025),
                  calendarFormat: format,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  rangeStartDay: startDate,
                  rangeEndDay: endDate,
                  rangeSelectionMode: RangeSelectionMode.toggledOn,
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      if (startDate == null || (endDate != null && selectedDay.isBefore(startDate!))) {
                        // Si aucune date de début ou si la date sélectionnée est avant la date de début, initialiser une nouvelle sélection
                        startDate = selectedDay;
                        endDate = null;
                      } else {
                        // Sinon, définir la date de fin
                        endDate = selectedDay;
                      }
                    });
                  },
                  onRangeSelected: (start, end, focusedDay) {
                    // Ne pas recentrer le calendrier, on garde `focusedDay` inchangé
                    if (start != null && end != null) {
                      final difference = end.difference(start).inDays;

                      if (difference > 7) {
                        // Afficher un message éphémère si la différence est supérieure à 7 jours
                        _showEphemeralMessage("La sélection ne peut pas dépasser 1 semaine.");

                        setState(() {
                          // Limiter la plage à 7 jours.
                          startDate = start;
                          endDate = start.add(const Duration(days: 7));
                        });
                      } else {
                        setState(() {
                          startDate = start;
                          endDate = end;
                        });
                      }
                    } else {
                      setState(() {
                        startDate = start;
                        endDate = end;
                      });
                    }
                  },
                  calendarStyle: CalendarStyle(
                    rangeHighlightColor: Colors.grey.shade600, // Trainée grise foncée entre les dates sélectionnées
                    rangeStartDecoration: BoxDecoration(
                      color: Colors.black, // Première date en noir
                      shape: BoxShape.circle,
                    ),
                    rangeEndDecoration: BoxDecoration(
                      color: Colors.black, // Dernière date en noir
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.grey.shade700, // Aujourd'hui en gris clair
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.black, // La sélection actuelle en noir
                      shape: BoxShape.circle,
                    ),
                    outsideDaysVisible: false,
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
                    weekendStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false, // Cache le bouton de format
                    titleCentered: true,
                    titleTextFormatter: (date, locale) {
                      String formattedDate = DateFormat.yMMMM(locale).format(date);
                      return formattedDate.replaceFirst(formattedDate[0], formattedDate[0].toUpperCase()); // Majuscule sur la première lettre du mois
                    },
                    titleTextStyle: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 16, // Taille du texte ajustée
                      fontWeight: FontWeight.w500, // Retirer le gras
                    ),
                  ),
                ),

                // Ligne de séparation avec ombre
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 15.0),
                  height: 1.0,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 3), // décalage vertical de l'ombre
                      ),
                    ],
                  ),
                ),

                // Affichage des dates sélectionnées
                if (startDate != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Du ${DateFormat('dd/MM/yyyy', 'fr').format(startDate!)}'
                      '${endDate != null ? ' au ${DateFormat('dd/MM/yyyy', 'fr').format(endDate!)}' : ''}',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // Boutons Annuler et Valider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          startDate = null;
                          endDate = null;
                        });
                      },
                      child: Text(
                        "Annuler",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          decoration: TextDecoration.underline, // Souligner le texte "Annuler"
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (startDate != null) {
                          Navigator.of(context).pop(DateTimeRange(start: startDate!, end: endDate ?? startDate!));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15), // Ajustement du padding
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        backgroundColor: Colors.black, // Couleur noire conforme au modèle
                        elevation: 5, // Ajout d'une légère ombre pour correspondre au modèle
                      ),
                      child: Text(
                        "Valider",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Méthode pour afficher un message éphémère au centre de l'écran
  void _showEphemeralMessage(String message) {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.4,
        left: MediaQuery.of(context).size.width * 0.1,
        right: MediaQuery.of(context).size.width * 0.1,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context)!.insert(_overlayEntry!);

    // Retirer le message après 2 secondes
    Future.delayed(Duration(seconds: 2), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }
}
