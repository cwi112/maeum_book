/// 데이터 계층(DB·모델·Repository) 모음. ViewModel에서는 이 파일 하나만 import 한다.
///
/// ```dart
/// import 'package:maeum_book/data/data.dart';
/// ```
library;

export 'database/app_database.dart'
    show AppDatabase, DefaultEventTypes, EventType, LedgerEntry, LedgerEvent, LedgerEntriesCompanion;
export 'models/models.dart';
export 'providers.dart';
export 'repositories/event_repository.dart';
export 'repositories/event_type_repository.dart';
export 'repositories/ledger_repository.dart';
export 'seed/sample_data.dart';
