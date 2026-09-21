import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/network/api_client.dart';
import '../models/invoice_model.dart';

class InvoiceRepository {
  final ApiClient _apiClient;

  InvoiceRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<InvoiceModel> getInvoice(String bookingId) async {
    final response = await _apiClient.get(
      ApiEndpoints.getInvoice,
      queryParameters: {'bookingId': bookingId},
    );

    if (response is Map<String, dynamic> && response['invoice'] != null) {
      return InvoiceModel.fromJson(response['invoice'] as Map<String, dynamic>);
    }
    throw const ServerException('Failed to load invoice information.');
  }

  Future<File> downloadInvoicePdf(String bookingId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/KRUIZLY_Invoice_$bookingId.pdf';

      final response = await _apiClient.dio.get<List<int>>(
        ApiEndpoints.pdfInvoice,
        queryParameters: {'bookingId': bookingId},
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
        ),
      );

      final file = File(savePath);
      if (response.data != null) {
        await file.writeAsBytes(response.data!);
      }
      return file;
    } catch (e) {
      throw AppException('Failed to download invoice PDF: ${e.toString()}');
    }
  }
}
