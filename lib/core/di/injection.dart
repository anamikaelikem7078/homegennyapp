import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/data/datasources/auth_datasource.dart';
import '../../common/data/repositories/auth_repository_impl.dart';
import '../../common/domain/repositories/auth_repository.dart';
import '../../features/client/data/datasources/client_datasource.dart';
import '../../features/client/data/repositories/client_repository_impl.dart';
import '../../features/client/domain/repositories/client_repository.dart';
import '../../features/rm/data/datasources/rm_datasource.dart';
import '../../features/rm/data/repositories/rm_repository_impl.dart';
import '../../features/rm/domain/repositories/rm_repository.dart';
import '../../features/staff/data/datasources/staff_datasource.dart';
import '../../features/staff/data/repositories/staff_repository_impl.dart';
import '../../features/staff/domain/repositories/staff_repository.dart';
import '../auth/jwt_token_handler.dart';
import '../auth/token_refresh_service.dart';
import '../data/datasources/json_asset_loader.dart';
import '../data/repository_executor.dart';
import '../firebase/firebase_service.dart';
import '../maps/google_maps_service.dart';
import '../network/api_service.dart';
import '../network/auth_interceptor.dart';
import '../network/dio_client.dart';
import '../network/network_info.dart';
import '../analytics/analytics_service.dart';
import '../notifications/push_notification_service.dart';
import '../storage/hive_service.dart';
import '../storage/secure_storage_service.dart';

// ── Storage ──
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

final jsonAssetLoaderProvider = Provider<JsonAssetLoader>((ref) {
  return JsonAssetLoader();
});

// ── Auth / Tokens ──
final jwtTokenHandlerProvider = Provider<JwtTokenHandler>((ref) {
  return JwtTokenHandler(ref.watch(secureStorageProvider));
});

final tokenRefreshServiceProvider = Provider<TokenRefreshService>((ref) {
  return TokenRefreshService(
    tokenHandler: ref.watch(jwtTokenHandlerProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

// ── Network ──
final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  return AuthInterceptor(
    tokenHandler: ref.watch(jwtTokenHandlerProvider),
    refreshService: ref.watch(tokenRefreshServiceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(authInterceptor: ref.watch(authInterceptorProvider));
});

final multipartUploadServiceProvider = Provider<MultipartUploadService>((ref) {
  return MultipartUploadService(ref.watch(dioClientProvider));
});

final repositoryExecutorProvider = Provider<RepositoryExecutor>((ref) {
  return RepositoryExecutor(networkInfo: ref.watch(networkInfoProvider));
});

// ── Analytics ──
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return DebugAnalyticsService();
});

// ── Firebase & Push ──
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService(hiveService: ref.watch(hiveServiceProvider));
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(
    firebaseService: ref.watch(firebaseServiceProvider),
    hiveService: ref.watch(hiveServiceProvider),
  );
});

// ── Maps ──
final googleMapsServiceProvider = Provider<GoogleMapsService>((ref) {
  return GoogleMapsService(dioClient: ref.watch(dioClientProvider));
});

// ── Auth datasources ──
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioClientProvider));
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSource(ref.watch(hiveServiceProvider));
});

// ── Staff datasources ──
final staffRemoteDataSourceProvider = Provider<StaffRemoteDataSource>((ref) {
  return StaffRemoteDataSource(ref.watch(dioClientProvider));
});

final staffLocalDataSourceProvider = Provider<StaffLocalDataSource>((ref) {
  return StaffLocalDataSource(ref.watch(hiveServiceProvider));
});

final staffDummyDataSourceProvider = Provider<StaffDummyDataSource>((ref) {
  return StaffDummyDataSource(jsonLoader: ref.watch(jsonAssetLoaderProvider));
});

// ── RM datasources ──
final rmRemoteDataSourceProvider = Provider<RmRemoteDataSource>((ref) {
  return RmRemoteDataSource(ref.watch(dioClientProvider));
});

final rmLocalDataSourceProvider = Provider<RmLocalDataSource>((ref) {
  return RmLocalDataSource(ref.watch(hiveServiceProvider));
});

final rmDummyDataSourceProvider = Provider<RmDummyDataSource>((ref) {
  return RmDummyDataSource(jsonLoader: ref.watch(jsonAssetLoaderProvider));
});

// ── Client datasources ──
final clientRemoteDataSourceProvider = Provider<ClientRemoteDataSource>((ref) {
  return ClientRemoteDataSource(ref.watch(dioClientProvider));
});

final clientLocalDataSourceProvider = Provider<ClientLocalDataSource>((ref) {
  return ClientLocalDataSource(ref.watch(hiveServiceProvider));
});

final clientDummyDataSourceProvider = Provider<ClientDummyDataSource>((ref) {
  return ClientDummyDataSource(jsonLoader: ref.watch(jsonAssetLoaderProvider));
});

// ── Repositories ──
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    dioClient: ref.watch(dioClientProvider),
    tokenHandler: ref.watch(jwtTokenHandlerProvider),
    secureStorage: ref.watch(secureStorageProvider),
    hiveService: ref.watch(hiveServiceProvider),
    remote: ref.watch(authRemoteDataSourceProvider),
    local: ref.watch(authLocalDataSourceProvider),
  );
});

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepositoryImpl(
    executor: ref.watch(repositoryExecutorProvider),
    remote: ref.watch(staffRemoteDataSourceProvider),
    local: ref.watch(staffLocalDataSourceProvider),
    dummy: ref.watch(staffDummyDataSourceProvider),
  );
});

final rmRepositoryProvider = Provider<RmRepository>((ref) {
  return RmRepositoryImpl(
    executor: ref.watch(repositoryExecutorProvider),
    remote: ref.watch(rmRemoteDataSourceProvider),
    local: ref.watch(rmLocalDataSourceProvider),
    dummy: ref.watch(rmDummyDataSourceProvider),
  );
});

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepositoryImpl(
    executor: ref.watch(repositoryExecutorProvider),
    remote: ref.watch(clientRemoteDataSourceProvider),
    local: ref.watch(clientLocalDataSourceProvider),
    dummy: ref.watch(clientDummyDataSourceProvider),
  );
});
