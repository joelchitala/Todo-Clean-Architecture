import '../../../nosqlUtility.dart';
import '../../document.dart';
import 'baseQueryBuilder.dart';

class QueryCollection extends BaseQueryBuilder<QueryCollection> {
  NoSQLUtility _noSQLUtility = NoSQLUtility();

  Future<Document?> getDocument({required String reference}) async {
    return await _noSQLUtility.getDocument(
      reference: reference,
      query: this,
    );
  }

  Future<List<Document>> getDocuments({required String reference}) async {
    return await _noSQLUtility.getDocuments(
      reference: reference,
      query: this,
    );
  }

  Future<bool> updateDocument({
    required String reference,
    required Map<String, dynamic> data,
    List<String>? ignoreKeys,
  }) async {
    return await _noSQLUtility.updateDocument(
      reference: reference,
      query: this,
      data: data,
      ignoreKeys: ignoreKeys,
    );
  }

  Future<bool> updateDocuments({
    required String reference,
    required Map<String, dynamic> data,
    List<String>? ignoreKeys,
  }) async {
    return await _noSQLUtility.updateDocuments(
      reference: reference,
      query: this,
      data: data,
      ignoreKeys: ignoreKeys,
    );
  }

  Future<bool> removeDocument({
    required String reference,
  }) async {
    return await _noSQLUtility.removeDocument(
      reference: reference,
      query: this,
    );
  }

  Future<bool> removeDocuments({
    required String reference,
  }) async {
    return await _noSQLUtility.removeDocuments(
      reference: reference,
      query: this,
    );
  }
}
