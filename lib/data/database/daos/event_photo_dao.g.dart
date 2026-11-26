// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_photo_dao.dart';

// ignore_for_file: type=lint
mixin _$EventPhotoDaoMixin on DatabaseAccessor<AppDatabase> {
  $EventTypesTable get eventTypes => attachedDatabase.eventTypes;
  $EventsTable get events => attachedDatabase.events;
  $LedgerEntriesTable get ledgerEntries => attachedDatabase.ledgerEntries;
  $EventPhotosTable get eventPhotos => attachedDatabase.eventPhotos;
  EventPhotoDaoManager get managers => EventPhotoDaoManager(this);
}

class EventPhotoDaoManager {
  final _$EventPhotoDaoMixin _db;
  EventPhotoDaoManager(this._db);
  $$EventTypesTableTableManager get eventTypes => $$EventTypesTableTableManager(_db.attachedDatabase, _db.eventTypes);
  $$EventsTableTableManager get events => $$EventsTableTableManager(_db.attachedDatabase, _db.events);
  $$LedgerEntriesTableTableManager get ledgerEntries =>
      $$LedgerEntriesTableTableManager(_db.attachedDatabase, _db.ledgerEntries);
  $$EventPhotosTableTableManager get eventPhotos =>
      $$EventPhotosTableTableManager(_db.attachedDatabase, _db.eventPhotos);
}
