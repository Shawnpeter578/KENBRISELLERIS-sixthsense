import 'package:appwrite/appwrite.dart';

class AppwriteService {
  static const String endpoint = "https://fra.cloud.appwrite.io/v1";
  static const String projectId = "6a6db29f001b2e978128"; // removed stray leading quote

  static const String databaseId = "6a6db39600359f38d75a";
  static const String userTableId = "users";

  static final Client client = Client()
    ..setEndpoint(endpoint)
    ..setProject(projectId);

  static final Account account = Account(client);
  static final TablesDB tablesDB = TablesDB(client);
}
