import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../services/news_service.dart';

class NewsScreen extends StatefulWidget {
  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsService _newsService = NewsService();
  // Removed AlternativeNewsService as per user request
  List<NewsArticle> _articles = [];
  bool _isLoading = false;
  String _error = '';
  String _currentSource = 'Mock Data';

  @override
  void initState() {
    super.initState();
    // Load news when the screen first appears
    _loadNews();
  }

  // This method demonstrates async/await in a Flutter widget
  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      List<NewsArticle> articles;

      // Only use NewsService for headlines and fallback to mock data
      try {
        articles = await _newsService.fetchTopHeadlines();
        _currentSource = 'NewsAPI';
        print('Successfully fetched ${articles.length} articles from NewsAPI');
      } catch (apiError) {
        print('NewsAPI failed: $apiError');
        print('Falling back to mock data...');
        articles = await _newsService.fetchMockNews();
        _currentSource = 'Mock Data';
      }

      // Update the UI with the fetched articles
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    } catch (e) {
      // Handle errors and update UI accordingly
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('Error loading news: $e');
    }
  }

  // Method to refresh the news (pull-to-refresh)
  Future<void> _refreshNews() async {
    await _loadNews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('News App'),
            Text(
              'Source: $_currentSource',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: _loadNews)],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      // Show loading indicator
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading news...'),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      // Show error message with retry option
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                _error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: _loadNews, child: Text('Retry')),
                  OutlinedButton(
                    onPressed: () async {
                      // Load mock data as fallback
                      setState(() {
                        _isLoading = true;
                        _error = '';
                      });
                      try {
                        final articles = await _newsService.fetchMockNews();
                        setState(() {
                          _articles = articles;
                          _isLoading = false;
                        });
                      } catch (e) {
                        setState(() {
                          _error = e.toString();
                          _isLoading = false;
                        });
                      }
                    },
                    child: Text('Load Sample'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_articles.isEmpty) {
      // Show message when no articles are available
      return Center(child: Text('No news available'));
    }

    // Show the list of articles
    return RefreshIndicator(
      onRefresh: _refreshNews,
      child: ListView.builder(
        itemCount: _articles.length,
        itemBuilder: (context, index) {
          final article = _articles[index];
          return NewsCard(article: article);
        },
      ),
    );
  }
}

class NewsCard extends StatelessWidget {
  final NewsArticle article;

  const NewsCard({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Article image
          if (article.imageUrl.isNotEmpty)
            Image.network(
              article.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: Icon(Icons.image_not_supported),
                );
              },
            ),

          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Article title
                Text(
                  article.title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),

                // Article description
                Text(
                  article.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),

                // Published date
                Text(
                  'Published: ${_formatDate(article.publishedAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateString;
    }
  }
}
