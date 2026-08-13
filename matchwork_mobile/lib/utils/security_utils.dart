import 'package:flutter/services.dart';

class SecurityUtils {
  // Filtro centralizado que bloquea caracteres típicos de inyección o scripts
  // Bloquea: < > { } [ ] \
  static final List<TextInputFormatter> secureInputFormatters = [
    FilteringTextInputFormatter.deny(RegExp(r'[<>{}\[\]\\]')),
  ];
}
