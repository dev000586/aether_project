// lib/injection_container.dart
//
// Single registration point for all dependencies.
// get_it is used as the service locator — it provides lazy singleton
// semantics, meaning instances are only created when first accessed.
//
// This approach makes testing clean: tests replace registrations
// with fakes/mocks before building the widget tree, without modifying
// production code.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

import 'features/chat/data/datasources/chat_remote_datasource.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/domain/repositories/chat_repository.dart';
import 'features/chat/presentation/bloc/chat_cubit.dart';
import 'features/raid/data/datasources/raid_service.dart';
import 'features/raid/data/repositories/raid_repository_impl.dart';
import 'features/raid/domain/repositories/raid_repository.dart';
import 'features/raid/presentation/bloc/raid_bloc.dart';
import 'features/world_boss/presentation/bloc/world_boss_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // ── External ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  // ── Data Sources ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<RaidService>(
    () => RaidService(firestore: sl<FirebaseFirestore>()),
  );

  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSource(firestore: sl<FirebaseFirestore>()),
  );

  // ── Repositories ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<RaidRepository>(
    () => RaidRepositoryImpl(raidService: sl<RaidService>()),
  );

  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(dataSource: sl<ChatRemoteDataSource>()),
  );

  // ── BLoCs / Cubits ────────────────────────────────────────────────────────
  // BLoCs are registered as factories so each widget subtree gets a fresh
  // instance with its own lifecycle. Singletons would share state across
  // navigation, which is incorrect for stateful BLoCs.
  sl.registerFactory<WorldBossBloc>(WorldBossBloc.new);

  sl.registerFactory<RaidBloc>(
    () => RaidBloc(raidRepository: sl<RaidRepository>()),
  );

  sl.registerFactory<ChatCubit>(
    () => ChatCubit(chatRepository: sl<ChatRepository>()),
  );
}
