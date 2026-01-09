import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your backend URL
  static String baseUrl = 'http://10.143.185.242:8000'; // Laptop IP
  // For Android emulator, use: 'http://10.0.2.2:8000'
  
  // Method to update base URL dynamically
  static void updateBaseUrl(String newBaseUrl) {
    baseUrl = newBaseUrl;
  }
  
  // Method to get current base URL
  static String getCurrentBaseUrl() {
    return baseUrl;
  }
  
  // Auto-detect and update base URL on initialization
  static Future<void> initializeAutoDetection() async {
    try {
      // Try common local IP addresses
      final commonIps = [
        'http://localhost:8000',
        'http://127.0.0.1:8000',
        'http://10.0.2.2:8000', // Android emulator
      ];
      
      for (final ip in commonIps) {
        try {
          final response = await http.get(Uri.parse('$ip/health'));
          if (response.statusCode == 200) {
            updateBaseUrl(ip);
            debugPrint('Auto-detected backend URL: $ip');
            break;
          }
        } catch (e) {
          continue; // Try next IP
        }
      }
    } catch (e) {
      debugPrint('Auto-detection failed, using default URL: $baseUrl');
    }
  }
  
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  // Reading Fluency Game
  Future<Map<String, dynamic>> checkFluency({
    required File audioFile,
    required String expectedText,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioFile.path,
          filename: 'audio.wav',
        ),
        'expected_text': expectedText,
      });

      final response = await _dio.post(
        '/api/fluency/check',
        data: formData,
      );

      return response.data;
    } catch (e) {
      throw Exception('Fluency check failed: $e');
    }
  }

  // Pronunciation Game
  Future<Map<String, dynamic>> checkPronunciation({
    required File audioFile,
    required String word,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioFile.path,
          filename: 'audio.wav',
        ),
        'word': word,
      });

      final response = await _dio.post(
        '/api/pronunciation/check',
        data: formData,
      );

      return response.data;
    } catch (e) {
      throw Exception('Pronunciation check failed: $e');
    }
  }

  // Vocabulary Game - Get Question
  Future<Map<String, dynamic>> getVocabularyQuestion({
    String difficulty = 'easy',
  }) async {
    try {
      final response = await _dio.get(
        '/api/vocabulary/question',
        queryParameters: {'difficulty': difficulty},
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to get vocabulary question: $e');
    }
  }

  // Vocabulary Game - Check Answer
  Future<Map<String, dynamic>> checkVocabularyAnswer({
    required String questionId,
    required String answer,
  }) async {
    try {
      final response = await _dio.post(
        '/api/vocabulary/check',
        data: {
          'question_id': questionId,
          'answer': answer,
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('Answer check failed: $e');
    }
  }

  // Health check
  Future<bool> checkConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
