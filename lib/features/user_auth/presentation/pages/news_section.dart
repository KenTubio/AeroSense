import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class NewsSection extends StatefulWidget {
  const NewsSection({super.key});

  @override
  _NewsSectionState createState() => _NewsSectionState();
}

class _NewsSectionState extends State<NewsSection> {
  List<dynamic> articles = [];
  bool isLoading = true;
  DateTime? lastPressedTime;
  TextEditingController _searchController =
      TextEditingController(); // Controller for the search field
  String _searchQuery = "health AND Philippines"; // Default search query

  @override
  void initState() {
    super.initState();
    fetchNews(_searchQuery);
  }

  Future<void> fetchNews(String query) async {
    setState(() {
      isLoading = true; // Start loading while fetching news
    });

    try {
      final response = await http.get(Uri.parse(
          'https://gnews.io/api/v4/search?q=$query&token=fa4644f7dad629855c77c431baea2196'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> fetchedArticles = data['articles'] ?? [];

        // Get the current year
        int currentYear = DateTime.now().year;

        // Filter articles based on the year of publication (2020 to current year)
        List<dynamic> filteredArticles = fetchedArticles.where((article) {
          String? publishedAt = article['publishedAt'];
          if (publishedAt != null) {
            int year = DateTime.parse(publishedAt).year;
            return year >= 2020 && year <= currentYear;
          }
          return false;
        }).toList();

        setState(() {
          articles = filteredArticles.take(20).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
    }
  }

  void _showArticleDetails(BuildContext context, dynamic article) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            article['title'] ?? 'No Title',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (article['image'] != null)
                  Image.network(
                    article['image'],
                    fit: BoxFit.cover,
                  ),
                const SizedBox(height: 10),
                Text(
                  article['description'] ?? 'No description available.',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  article['content'] ?? 'No content available.',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 10),
                Text(
                  'Published on: ${article['publishedAt'] ?? 'Unknown date'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    DateTime now = DateTime.now();

    // If the user clicks back within 2 seconds, show the logout message
    if (lastPressedTime == null ||
        now.difference(lastPressedTime!) > const Duration(seconds: 2)) {
      lastPressedTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Click again to logout'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    // Perform the sign-out action
    await FirebaseAuth.instance.signOut();

    // After sign out, navigate to the login screen
    Navigator.of(context).pushReplacementNamed('/login');

    return true; // Allow the back navigation after signing out
  }

  void _onSearch() {
    String query = _searchController.text;
    if (query.isNotEmpty) {
      setState(() {
        _searchQuery = query;
      });
      fetchNews(_searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(
            255, 18, 18, 19), // Black background for entire scaffold
        appBar: AppBar(
          title: const Text(
            'AeroSense Headlines',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
              fontFamily: 'handjet',
              letterSpacing: 2.0,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 18, 18, 19),
        ),
        body: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search News...',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color.fromARGB(255, 18, 18, 19),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _onSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Button color
                ),
                child: const Text(
                  'Search',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              isLoading
                  ? const CircularProgressIndicator()
                  : articles.isEmpty
                      ? const Text(
                          'No news available.',
                          style: TextStyle(color: Colors.white),
                        )
                      : Expanded(
                          child: ListView.builder(
                            itemCount: articles.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  _showArticleDetails(context, articles[index]);
                                },
                                child: Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  color: Colors
                                      .black, // Background of each article is black
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (articles[index]['image'] != null)
                                        Image.network(
                                          articles[index]['image'],
                                          width: double.infinity,
                                          height: 150,
                                          fit: BoxFit.cover,
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.all(15.0),
                                        child: Text(
                                          articles[index]['title'] ??
                                              'No Title',
                                          style: const TextStyle(
                                            color: Colors
                                                .white, // White text color
                                            fontSize: 23,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15.0),
                                        child: Text(
                                          'Source: ${articles[index]['source']['name'] ?? 'Unknown'}',
                                          style: const TextStyle(
                                            color: Colors
                                                .white54, // Light white for the source
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }
}
