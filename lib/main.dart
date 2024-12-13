import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:pacman_contacts/contact.dart';
import 'package:pacman_contacts/theme.dart';

void main() {
  runApp(const Contacts());
}

class Contacts extends StatelessWidget {
  const Contacts({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Contacts',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: MaterialTheme.lightScheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: MaterialTheme.darkScheme(),
      ),
      home: const HomePage(title: 'Contacts'),
    );
  }
}

class HomePage extends StatefulWidget {
  final String title;
  const HomePage({super.key, required this.title});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Contact>? _contacts;
  List<Contact>? _filteredContacts;
  bool _permissionDenied = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchContacts();
    searchController.addListener(() {
      _filterContacts();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return Scaffold(
        body: Center(
          child: Text(
            'Permission denied',
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      );
    }

    if (_contacts == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return SafeArea(
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_contacts?.length ?? 0} contacts',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildSearchBar(),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredContacts?.length ?? 0,
                itemBuilder: (context, index) {
                  final contact = _filteredContacts![index];
                  return _buildContactTile(contact);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hintText: 'Search Contacts',
        prefixIcon: Icon(Icons.search),
        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  searchController.clear();
                  _filterContacts(); // Clear the search results
                },
              )
            : null,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildContactTile(Contact contact) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Text(
          contact.displayName,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        onTap: () async {
          final fullContact = await FlutterContacts.getContact(contact.id);
          if (fullContact != null) {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ContactPage(fullContact)),
            );
          }
        },
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: contact.photo != null
              ? MemoryImage(contact.photo!)
              : contact.thumbnail != null
                  ? MemoryImage(contact.thumbnail!)
                  : null,
          child: contact.photo == null && contact.thumbnail == null
              ? Text(
                  contact.name.first.isEmpty
                      ? '?'
                      : contact.name.last.isEmpty
                          ? contact.name.first[0]
                          : contact.name.first[0] + contact.name.last[0],
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                )
              : null,
        ),
        trailing: Icon(Icons.chevron_right),
      ),
    );
  }

  Future<void> _fetchContacts() async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      setState(() {
        _permissionDenied = true;
      });
      return;
    }

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: true,
    );

    setState(() {
      _contacts = contacts;
      _filteredContacts = List.from(_contacts!); // Initialize filtered contacts
    });
  }

  void _filterContacts() {
    if (searchController.text.isEmpty) {
      setState(() {
        _filteredContacts = List.from(_contacts!);
      });
      return;
    }

    final query = searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _contacts!.where((contact) {
        final nameMatch = contact.displayName.toLowerCase().contains(query);
        final phoneMatch = contact.phones.any((phone) =>
            phone.number.replaceAll(RegExp(r'\D'), '').contains(query));
        final emailMatch = contact.emails
            .any((email) => email.address.toLowerCase().contains(query));
        return nameMatch || phoneMatch || emailMatch;
      }).toList();
    });
  }
}
