import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';

class NewsService {
  // We're using a free news API - NewsAPI.org
  // You can get a free API key from https://newsapi.org/
  static const String _apiKey = 'dda597ae1bf54d709c51421501bc7fa7';
  static const String _baseUrl = 'https://newsapi.org/v2';

  // This method demonstrates async/await and exception handling
  Future<List<NewsArticle>> fetchTopHeadlines() async {
    try {
      // Create the URL with proper formatting
      final url = Uri.parse('$_baseUrl/top-headlines').replace(
        queryParameters: {
          'country': 'us',
          'apiKey': _apiKey,
          'pageSize': '20', // Limit results
        },
      );

      print('Making request to: $url'); // Debug print

      // The 'await' keyword pauses execution until the HTTP request completes
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': 'NewsApp/1.0',
            },
          )
          .timeout(
            Duration(seconds: 10), // Add timeout
            onTimeout: () {
              throw TimeoutException(
                'Request timed out',
                Duration(seconds: 10),
              );
            },
          );

      print('Response status: ${response.statusCode}'); // Debug print

      // Check if the request was successful (status code 200)
      if (response.statusCode == 200) {
        // Parse the JSON response
        final Map<String, dynamic> data = json.decode(response.body);

        // Check if the API returned an error
        if (data['status'] == 'error') {
          throw Exception('API Error: ${data['message']}');
        }

        final List<dynamic> articlesJson = data['articles'] ?? [];

        // Convert JSON articles to NewsArticle objects
        List<NewsArticle> articles = articlesJson
            .map((json) => NewsArticle.fromJson(json))
            .where(
              (article) => article.title.isNotEmpty,
            ) // Filter out empty titles
            .toList();

        return articles;
      } else {
        // Handle HTTP errors (4xx, 5xx status codes)
        throw Exception(
          'Failed to load news: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } on TimeoutException {
      // Handle timeout specifically
      throw Exception(
        'Request timed out. Please check your internet connection.',
      );
    } on SocketException {
      // Handle network connection errors
      throw Exception(
        'No internet connection. Please check your network settings.',
      );
    } on FormatException {
      // Handle JSON parsing errors
      throw Exception('Invalid data format received from server.');
    } on http.ClientException {
      // Handle HTTP client errors
      throw Exception(
        'Network error: Unable to connect to the news service. Please try again later.',
      );
    } catch (e) {
      // Handle any other unexpected errors
      print('Unexpected error: $e'); // Debug print
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Alternative method using mock data for testing without API key
  Future<List<NewsArticle>> fetchMockNews() async {
    // Simulate network delay
    await Future.delayed(Duration(seconds: 2));

    // Mock data for testing
    final List<Map<String, dynamic>> mockData = [
      {
        'title': 'Flutter 3.0 Released',
        'description': 'Google releases Flutter 3.0 with amazing new features',
        'url': 'https://example.com/flutter-3',
        'urlToImage': 'https://picsum.photos/300/200?random=1',
        'publishedAt': '2024-01-15T10:30:00Z',
      },
      {
        'title': 'AI Revolution Continues',
        'description': 'Latest developments in artificial intelligence',
        'url': 'https://example.com/ai-news',
        'urlToImage': 'https://picsum.photos/300/200?random=2',
        'publishedAt': '2024-01-15T09:15:00Z',
      },
      {
        'title': 'Climate Change Update',
        'description': 'New research on global climate patterns',
        'url': 'https://example.com/climate',
        'urlToImage': 'https://picsum.photos/300/200?random=3',
        'publishedAt': '2024-01-15T08:45:00Z',
      },
    ];

    return mockData.map((json) => NewsArticle.fromJson(json)).toList();
  }
}
