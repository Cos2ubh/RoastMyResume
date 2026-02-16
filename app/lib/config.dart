// API Configuration for Roast My Resume
//
// This file contains environment-specific configuration.
// Update the baseUrl based on your deployment environment.

class AppConfig {
  // Backend API base URL
  // Development: http://localhost:8000
  // Production: Update to your deployed backend URL
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  // API Endpoints
  static const String roastEndpoint = '/roast';
  static const String healthEndpoint = '/health';

  // Helper method to get full endpoint URL
  static String getEndpoint(String endpoint) {
    return '$baseUrl$endpoint';
  }

  // Get the roast endpoint URL
  static String get roastUrl => getEndpoint(roastEndpoint);

  // Get the health check endpoint URL
  static String get healthUrl => getEndpoint(healthEndpoint);
}
