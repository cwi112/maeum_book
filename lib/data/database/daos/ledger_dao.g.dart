// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_dao.dart';

// ignore_for_file: type=lint
mixin _$LedgerDaoMixin on DatabaseAccessor<AppDatabase> {
  $EventTypesTable get eventTypes => attachedDatabase.eventTypes;
  $EventsTable get events => attachedDatabase.events;
  $LedgerEntriesTable get ledgerEntries => attachedDatabase.ledgerEntries;
  LedgerDaoManager get managers => LedgerDaoManager(this);
}

class LedgerDaoManager {
  final _$LedgerDaoMixin _db;
  LedgerDaoManager(this._db);
  $$EventTypesTableTableManager get eventTypes => $$EventTypesTableTableManager(_db.attachedDatabase, _db.eventTypes);
  $$EventsTableTableManager get events => $$EventsTableTableManager(_db.attachedDatabase, _db.events);
  $$LedgerEntriesTableTableManager get ledgerEntries =>
      $$LedgerEntriesTableTableManager(_db.attachedDatabase, _db.ledgerEntries);
}
