/// 앱 공통 코어. 화면 파일에서는 이 파일 하나만 import 하면 된다.
///
/// ```dart
/// import 'package:maeum_book/core/core.dart';
/// ```
library;

export 'package:flutter_riverpod/flutter_riverpod.dart';
export 'package:flutter_slidable/flutter_slidable.dart' show SlidableAutoCloseBehavior;
export 'package:go_router/go_router.dart';
export 'package:material_ui/material_ui.dart';

export 'base/base.dart';
export 'define/define.dart';
export 'errors/network_exception.dart';
export 'extensions/extensions.dart';
export 'theme/theme.dart';
export 'utils/in_app_handoff.dart';
export 'utils/stream_utils.dart';
export 'widgets/widgets.dart';
