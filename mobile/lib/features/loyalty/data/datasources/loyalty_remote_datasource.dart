import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/loyalty_models.dart';

final loyaltyDatasourceProvider = Provider<LoyaltyRemoteDatasource>((ref) {
  return LoyaltyRemoteDatasource(ref.watch(dioProvider));
});

class LoyaltyRemoteDatasource {
  final Dio _dio;

  LoyaltyRemoteDatasource(this._dio);

  Future<LoyaltyOverviewModel> getMyLoyalty() async {
    final response = await _dio.get(ApiConstants.loyaltyMe);
    return LoyaltyOverviewModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<CampaignModel>> getActiveCampaigns({String? restaurantId}) async {
    final response = await _dio.get(
      ApiConstants.loyaltyCampaigns,
      queryParameters:
          restaurantId != null ? {'restaurantId': restaurantId} : null,
    );
    return (response.data as List<dynamic>)
        .map((e) => CampaignModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CampaignModel> createCampaign({
    required String restaurantId,
    required String title,
    String? description,
    required double pointsMultiplier,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _dio.post(
      ApiConstants.loyaltyCampaigns,
      data: {
        'restaurantId': restaurantId,
        'title': title,
        if (description != null) 'description': description,
        'pointsMultiplier': pointsMultiplier,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );
    return CampaignModel.fromJson(response.data as Map<String, dynamic>);
  }
}
