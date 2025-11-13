export 'excel_exporter_stub.dart'
    if (dart.library.html) 'excel_exporter_web.dart'
    if (dart.library.io) 'excel_exporter_io.dart';
