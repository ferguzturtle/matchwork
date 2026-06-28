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
  'construccion': CategoryDetail(
    label: 'Construcción y Reformas',
    icon: 'construction',
    subcategories: {
      'albanileria': SubcategoryDetail(label: 'Albañilería', icon: 'construction'),
      'pintura': SubcategoryDetail(label: 'Pintura', icon: 'format_paint'),
      'carpinteria': SubcategoryDetail(label: 'Carpintería', icon: 'handyman'),
      'gasfiteria': SubcategoryDetail(label: 'Gasfitería', icon: 'plumbing'),
    },
  ),
  'salud': CategoryDetail(
    label: 'Servicios de Salud y Cuidado',
    icon: 'medical_services',
    subcategories: {
      'enfermeria': SubcategoryDetail(label: 'Enfermería', icon: 'medical_services'),
      'kinesiologia': SubcategoryDetail(label: 'Kinesiología', icon: 'physical_therapy'),
      'adulto_mayor': SubcategoryDetail(label: 'Cuidado de Adulto Mayor', icon: 'elderly'),
      'ninos': SubcategoryDetail(label: 'Cuidado de Niños', icon: 'child_care'),
    },
  ),
  'instalaciones': CategoryDetail(
    label: 'Instalaciones y Electricidad',
    icon: 'engineering',
    subcategories: {
      'electricidad': SubcategoryDetail(label: 'Electricidad Residencial', icon: 'bolt'),
      'climatizacion': SubcategoryDetail(label: 'Climatización', icon: 'ac_unit'),
      'redes': SubcategoryDetail(label: 'Redes y Telecomunicaciones', icon: 'router'),
    },
  ),
  'mantenimiento': CategoryDetail(
    label: 'Mantenimiento y Limpieza',
    icon: 'cleaning_services',
    subcategories: {
      'limpieza_hogar': SubcategoryDetail(label: 'Limpieza de Hogar', icon: 'cleaning_services'),
      'fumigacion': SubcategoryDetail(label: 'Fumigación', icon: 'pest_control'),
      'jardineria': SubcategoryDetail(label: 'Jardinería', icon: 'yard'),
      'piscinas': SubcategoryDetail(label: 'Limpieza de Piscinas', icon: 'pool'),
    },
  ),
  'profesionales': CategoryDetail(
    label: 'Servicios Profesionales',
    icon: 'support_agent',
    subcategories: {
      'tutorias': SubcategoryDetail(label: 'Tutorías / Clases', icon: 'school'),
      'asistencia_tec': SubcategoryDetail(label: 'Asistencia Tecnológica', icon: 'computer'),
      'mudanzas': SubcategoryDetail(label: 'Mudanzas y Desembalaje', icon: 'local_shipping'),
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
