/// View models: what widgets render. Cubits map domain models into these
/// before emitting, so formatting is unit-tested here and never lives in a
/// widget.
library;

export 'src/catalog/catalog_template_x.dart';
export 'src/catalog/service_type_view_model.dart';
export 'src/client/client_detail_view_model.dart';
export 'src/client/client_equipment_view_model.dart';
export 'src/client/client_list_item_view_model.dart';
export 'src/client/client_validation_error_x.dart';
export 'src/client/client_visit_view_model.dart';
export 'src/client/last_visit_error.dart';
export 'src/due/due_list_item_view_model.dart';
export 'src/due/due_status_view_model.dart';
export 'src/exceptions/localized_exception.dart';
export 'src/formatters/date_formatter.dart';
export 'src/formatters/money_formatter.dart';
export 'src/formatters/phone_formatter.dart';
