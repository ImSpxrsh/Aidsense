import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/models/search_request_model.dart';

part 'help_search_state.freezed.dart';

@freezed
class HelpSearchState with _$HelpSearchState {
  const factory HelpSearchState.initial() = _Initial;
  
  const factory HelpSearchState.loading() = _Loading;
  
  const factory HelpSearchState.success(SearchResponseModel response) = _Success;
  
  const factory HelpSearchState.noResults({
    required String searchQuery,
    required String interpretedIntent,
  }) = _NoResults;
  
  const factory HelpSearchState.error(String message) = _Error;
}
