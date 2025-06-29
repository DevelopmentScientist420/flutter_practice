import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bank_app/models/post.dart';

class PostService {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';

  static Future<List<Post>> fetchPosts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching posts: $e');
    }
  }

  static Future<Post> fetchPostById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts/$id'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return Post.fromJson(jsonData);
      } else {
        throw Exception('Failed to load post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching post: $e');
    }
  }
}
