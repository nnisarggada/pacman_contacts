import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:pacman_contacts/contact.dart';
import 'package:pacman_contacts/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: const MyHomePage(title: 'Contacts'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return Center(
          child: Text('Permission denied',
              style: TextStyle(color: Colors.red, fontSize: 18)));
    }
    if (_contacts == null) {
      return Center(child: CircularProgressIndicator());
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
                        fontWeight: FontWeight.w200),
                  ),
                  SizedBox(height: 10),
                  _buildSearchBar(),
                ],
              ),
            ),
            Expanded(
              child: _contacts!.isEmpty
                  ? Center(
                      child: Text('No contacts available.',
                          style: TextStyle(fontSize: 18, color: Colors.grey)))
                  : ListView.builder(
                      itemCount: searchController.text.isEmpty
                          ? _contacts!.length
                          : _filteredContacts!.length,
                      itemBuilder: (context, i) {
                        final contact = searchController.text.isEmpty
                            ? _contacts![i]
                            : _filteredContacts![i];
                        return _buildContactTile(contact);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the custom search bar
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
                },
              )
            : null,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // Builds the ListTile for each contact
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
          try {
            final fullContact = await FlutterContacts.getContact(contact.id);
            if (fullContact != null) {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ContactPage(fullContact)),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to load contact details')));
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))
              : null,
        ),
        trailing: Icon(Icons.chevron_right),
      ),
    );
  }

  // Fetch contacts from FlutterContacts package
  Future _fetchContacts() async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      setState(() => _permissionDenied = true);
    } else {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
        withThumbnail: true,
        withGroups: true,
        withAccounts: true,
      );
      setState(() => _contacts = contacts);
    }
  }

  // Filters contacts based on search query
  void _filterContacts() {
    List<Contact> contacts = [];
    contacts.addAll(_contacts!);
    if (searchController.text.isNotEmpty) {
      contacts.retainWhere((contact) {
        String searchTerm = searchController.text.toLowerCase();
        String displayName = contact.displayName.toLowerCase();
        bool nameMatches = displayName.contains(searchTerm);

        if (nameMatches) {
          return true;
        }

        var phone = contact.phones.firstWhere(
          (phone) => flattenPhoneNumber(phone.number)
              .contains(flattenPhoneNumber(searchTerm)),
          orElse: () => Phone(''), // Provide a default empty object
        );

        var email = contact.emails.firstWhere(
          (email) =>
              flattenEmail(email.address).contains(flattenEmail(searchTerm)),
          orElse: () => Email(''), // Provide a default empty object
        );

        return (phone.number.isNotEmpty || email.address.isNotEmpty);
      });
    }

    setState(() {
      _filteredContacts = contacts;
    });
  }

  String flattenEmail(String email) {
    return email.replaceAll(RegExp(r'\s+\b|\b\s'), '');
  }

  String flattenPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'^(\+)|\D'), '');
  }
}
