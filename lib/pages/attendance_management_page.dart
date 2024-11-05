import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../models/attendance.dart';
import '../services/event_service.dart';

class AttendanceManagementPage extends StatefulWidget {
  final Event event;

  AttendanceManagementPage({required this.event});

  @override
  _AttendanceManagementPageState createState() => _AttendanceManagementPageState();
}

class _AttendanceManagementPageState extends State<AttendanceManagementPage> {
  List<Attendance> _attendanceList = [];
  List<Attendance> _filteredAttendanceList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statusOptions = ['All', 'Participating', 'Maybe', 'Not Participating'];

  @override
  void initState() {
    super.initState();
    _fetchAttendanceList();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAttendanceList() async {
    try {
      final eventService = EventService('https://wazaapp-backend-e95231584d01.herokuapp.com'); // Fournir baseUrl
      List<Attendance> attendanceList = await eventService.getAttendanceList(widget.event.id);
      setState(() {
        _attendanceList = attendanceList;
        _filteredAttendanceList = attendanceList;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors de la récupération de la liste des présences: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la récupération de la liste des présences.')),
      );
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Attendance> tempList = _attendanceList.where((att) {
      final fullName = '${att.userFirstName} ${att.userLastName}'.toLowerCase();
      final query = _searchQuery.toLowerCase();
      final matchesSearch = fullName.contains(query);
      final matchesFilter = _filterStatus == 'All' || att.status == _filterStatus;
      return matchesSearch && matchesFilter;
    }).toList();

    setState(() {
      _filteredAttendanceList = tempList;
    });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher par nom',
          prefixIcon: Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey.shade200,
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: DropdownButtonFormField<String>(
        value: _filterStatus,
        items: _statusOptions.map((status) {
          return DropdownMenuItem<String>(
            value: status,
            child: Text(status),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _filterStatus = value!;
            _applyFilters();
          });
        },
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade200,
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(Attendance att) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.blueAccent,
          child: Text(
            '${att.userFirstName[0]}${att.userLastName[0]}',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          '${att.userFirstName} ${att.userLastName}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Row(
          children: [
            _buildStatusBadge(att.status),
            SizedBox(width: 8),
            Text(att.status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    IconData badgeIcon;

    switch (status) {
      case 'Participating':
        badgeColor = Colors.green;
        badgeIcon = Icons.check_circle;
        break;
      case 'Maybe':
        badgeColor = Colors.orange;
        badgeIcon = Icons.help_outline;
        break;
      case 'Not Participating':
        badgeColor = Colors.red;
        badgeIcon = Icons.cancel;
        break;
      default:
        badgeColor = Colors.grey;
        badgeIcon = Icons.info;
    }

    return Row(
      children: [
        Icon(
          badgeIcon,
          color: badgeColor,
          size: 16,
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_filteredAttendanceList.isEmpty) {
      return Center(
        child: Text(
          'Aucun participant trouvé.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAttendanceList,
      child: ListView.builder(
        itemCount: _filteredAttendanceList.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSearchBar();
          } else if (index == 1) {
            return _buildFilterOptions();
          } else {
            Attendance att = _filteredAttendanceList[index - 2];
            return _buildAttendanceCard(att);
          }
        },
      ),
    );
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
                        Navigator.of(context).pop();
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
                      'Gestion participants',
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
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
