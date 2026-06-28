class CategoryDetail {
  final String label;
  final String icon;
  final Map<String, SubcategoryDetail> subcategories;

  const CategoryDetail({
    required this.label,
    required this.icon,
    required this.subcategories,
  });
}

class SubcategoryDetail {
  final String label;
  final String icon;

  const SubcategoryDetail({
    required this.label,
    required this.icon,
  });
}

const Map<String, CategoryDetail> categories = {
  'reparaciones_mantenimiento': CategoryDetail(
    label: 'Reparaciones y Mantenimiento',
    icon: 'handyman',
    subcategories: {
      'gasfiteria': SubcategoryDetail(label: 'Gasfitería', icon: 'plumbing'),
      'electricidad': SubcategoryDetail(label: 'Electricidad', icon: 'bolt'),
      'cerrajeria': SubcategoryDetail(label: 'Cerrajería', icon: 'vpn_key'),
      'carpinteria': SubcategoryDetail(label: 'Carpintería', icon: 'construction'),
      'climatizacion': SubcategoryDetail(label: 'Climatización', icon: 'ac_unit'),
    },
  ),
  'limpieza_hogar': CategoryDetail(
    label: 'Limpieza y Cuidado del Hogar',
    icon: 'cleaning_services',
    subcategories: {
      'limpieza_residencial': SubcategoryDetail(label: 'Limpieza Residencial', icon: 'home'),
      'lavanderia_planchado': SubcategoryDetail(label: 'Lavandería y Planchado', icon: 'local_laundry_service'),
      'limpieza_profunda': SubcategoryDetail(label: 'Limpieza Profunda', icon: 'dry_cleaning'),
      'control_plagas': SubcategoryDetail(label: 'Control de Plagas', icon: 'bug_report'),
    },
  ),
  'jardineria_exteriores': CategoryDetail(
    label: 'Jardinería y Exteriores',
    icon: 'yard',
    subcategories: {
      'jardineria': SubcategoryDetail(label: 'Jardinería', icon: 'yard'),
      'piscinas': SubcategoryDetail(label: 'Piscinas', icon: 'pool'),
      'techos_canaletas': SubcategoryDetail(label: 'Techos y Canaletas', icon: 'home_work'),
    },
  ),
  'tecnologia_linea_blanca': CategoryDetail(
    label: 'Tecnología y Línea Blanca',
    icon: 'computer',
    subcategories: {
      'reparacion_electrodomesticos': SubcategoryDetail(label: 'Reparación de Electrodomésticos', icon: 'kitchen'),
      'soporte_tecnico': SubcategoryDetail(label: 'Soporte Técnico', icon: 'computer'),
    },
  ),
  'salud_belleza_bienestar': CategoryDetail(
    label: 'Salud, Belleza y Bienestar',
    icon: 'spa',
    subcategories: {
      'belleza_salon': SubcategoryDetail(label: 'Belleza y Salón', icon: 'content_cut'),
      'salud_fitness': SubcategoryDetail(label: 'Salud y Fitness', icon: 'fitness_center'),
      'cuidados': SubcategoryDetail(label: 'Cuidados', icon: 'volunteer_activism'),
    },
  ),
  'mudanzas_logistica': CategoryDetail(
    label: 'Mudanzas y Logística',
    icon: 'local_shipping',
    subcategories: {
      'fletes_mudanzas': SubcategoryDetail(label: 'Fletes y Mudanzas', icon: 'local_shipping'),
      'armado_muebles': SubcategoryDetail(label: 'Armado de Muebles', icon: 'weekend'),
      'pago_cuentas': SubcategoryDetail(label: 'Trámites y Acompañamiento', icon: 'receipt_long'),
      'revision_tecnica': SubcategoryDetail(label: 'Gestión de Revisión Técnica', icon: 'directions_car'),
      'gestion_compras': SubcategoryDetail(label: 'Gestión de Compras', icon: 'shopping_cart'),
    },
  ),
  'cuidado_mascotas': CategoryDetail(
    label: 'Cuidado de Mascotas',
    icon: 'pets',
    subcategories: {
      'peluqueria_canina': SubcategoryDetail(label: 'Peluquería Canina', icon: 'pets'),
      'paseo_perros': SubcategoryDetail(label: 'Paseo de Perros', icon: 'directions_walk'),
      'guarderia_mascotas': SubcategoryDetail(label: 'Guardería de Mascotas', icon: 'home_max'),
    },
  ),
  'servicios_profesionales': CategoryDetail(
    label: 'Servicios Profesionales',
    icon: 'school',
    subcategories: {
      'tutorias_clases': SubcategoryDetail(label: 'Tutorías / Clases', icon: 'school'),
      'clases_conducir': SubcategoryDetail(label: 'Clases de Conducir', icon: 'drive_eta'),
    },
  ),
};

String getSubcategoryIcon(String subcat) {
  for (var cat in categories.values) {
    if (cat.subcategories.containsKey(subcat)) {
      return cat.subcategories[subcat]!.icon;
    }
  }
  return 'plumbing';
}

String getProfessionLabel(String subcat) {
  for (var cat in categories.values) {
    if (cat.subcategories.containsKey(subcat)) {
      return 'Especialista en ${cat.subcategories[subcat]!.label}';
    }
  }
  return 'Trabajador General';
}
