import 'package:drift/drift.dart';

enum SpotPriceRange { low, medium, high, unknown }

@DataClassName('Spot')
class Spots extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get aliases => text().nullable()();
  TextColumn get genre => text().nullable()();
  TextColumn get area => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get mapUrl => text().named('map_url').nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get placeId => text().named('place_id').nullable()();
  TextColumn get geocodeSource => text().named('geocode_source').nullable()();
  TextColumn get mapLabel => text().named('map_label').nullable()();
  BoolColumn get isMapVisible =>
      boolean().named('is_map_visible').withDefault(const Constant(true))();
  TextColumn get mapPinColor => text().named('map_pin_color').nullable()();
  TextColumn get websiteUrl => text().named('website_url').nullable()();
  TextColumn get snsUrls => text().named('sns_urls').nullable()();
  TextColumn get businessHoursNote =>
      text().named('business_hours_note').nullable()();
  TextColumn get summary => text().nullable()();
  TextColumn get atmosphere => text().nullable()();
  TextColumn get strengths => text().nullable()();
  TextColumn get weaknesses => text().nullable()();
  TextColumn get recommendedFor => text().named('recommended_for').nullable()();
  TextColumn get avoidFor => text().named('avoid_for').nullable()();
  IntColumn get soloFriendly => integer().named('solo_friendly').nullable()();
  IntColumn get friendFriendly =>
      integer().named('friend_friendly').nullable()();
  IntColumn get dateFriendly => integer().named('date_friendly').nullable()();
  IntColumn get workFriendly => integer().named('work_friendly').nullable()();
  IntColumn get conversationFriendly =>
      integer().named('conversation_friendly').nullable()();
  TextColumn get stayDurationNote =>
      text().named('stay_duration_note').nullable()();
  IntColumn get quietnessLevel =>
      integer().named('quietness_level').nullable()();
  IntColumn get crowdednessLevel =>
      integer().named('crowdedness_level').nullable()();
  IntColumn get priceRange =>
      intEnum<SpotPriceRange>().named('price_range').nullable()();
  TextColumn get paymentNote => text().named('payment_note').nullable()();
  BoolColumn get hasWifi => boolean().named('has_wifi').nullable()();
  BoolColumn get hasPower => boolean().named('has_power').nullable()();
  TextColumn get smokingPolicy => text().named('smoking_policy').nullable()();
  TextColumn get seatComfortNote =>
      text().named('seat_comfort_note').nullable()();
  TextColumn get accessNote => text().named('access_note').nullable()();
  DateTimeColumn get firstVisitedAt =>
      dateTime().named('first_visited_at').nullable()();
  DateTimeColumn get lastVisitedAt =>
      dateTime().named('last_visited_at').nullable()();
  IntColumn get favoriteScore =>
      integer().named('favorite_score').withDefault(const Constant(50))();
  IntColumn get revisitScore =>
      integer().named('revisit_score').withDefault(const Constant(50))();
  TextColumn get tags => text().nullable()();
  TextColumn get photoPath => text().named('photo_path').nullable()();
  TextColumn get aiSummary => text().named('ai_summary').nullable()();
  TextColumn get aiRecommendationNote =>
      text().named('ai_recommendation_note').nullable()();
  TextColumn get aiUseCaseNote => text().named('ai_use_case_note').nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
