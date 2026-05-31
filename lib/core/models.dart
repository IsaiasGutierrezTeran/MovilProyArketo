// Lightweight models mirroring the Arketo backend contract.

class User {
  final int id;
  final String email, fullName, phone, role, subscriptionPlan;
  final String? avatar;
  User.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        email = j['email'] ?? '',
        fullName = j['full_name'] ?? '',
        phone = j['phone'] ?? '',
        role = j['role'] ?? 'cliente',
        subscriptionPlan = j['subscription_plan'] ?? 'free',
        avatar = j['avatar'];

  bool hasRole(List<String> roles) => role == 'superadmin' || roles.contains(role);
}

class Project {
  final int id;
  final String name, description, status, ownerEmail;
  Project.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        name = j['name'] ?? '',
        description = j['description'] ?? '',
        status = j['status'] ?? 'draft',
        ownerEmail = j['owner_email'] ?? '';
}

class DashboardSummary {
  final int total;
  final Map<String, dynamic> byStatus;
  final List<Project> recent;
  DashboardSummary.fromJson(Map<String, dynamic> j)
      : total = j['total'] ?? 0,
        byStatus = Map<String, dynamic>.from(j['by_status'] ?? {}),
        recent = ((j['recent'] ?? []) as List).map((e) => Project.fromJson(e)).toList();
}

class Plan {
  final int id;
  final String format, status;
  final String? fileUrl;
  Plan.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        format = j['original_format'] ?? '',
        status = j['status'] ?? '',
        fileUrl = j['file_url'];
}

class Model3D {
  final int id;
  final String? glbUrl;
  final int elementCount;
  final bool isCurrent;
  Model3D.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        glbUrl = j['glb_url'],
        elementCount = j['element_count'] ?? 0,
        isCurrent = j['is_current'] ?? false;
}

class Budget {
  final int id;
  final String status, total, materialsCost, laborCost, currency;
  final int laborPeople;
  Budget.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        status = j['status'] ?? '',
        total = '${j['total'] ?? '0'}',
        materialsCost = '${j['materials_cost'] ?? '0'}',
        laborCost = '${j['labor_cost'] ?? '0'}',
        currency = j['currency'] ?? '',
        laborPeople = j['labor_people'] ?? 0;
}

class RiskFinding {
  final String category, severity, description, suggestion;
  RiskFinding.fromJson(Map<String, dynamic> j)
      : category = j['category'] ?? '',
        severity = j['severity'] ?? 'low',
        description = j['description'] ?? '',
        suggestion = j['suggestion'] ?? '';
}

class RiskAnalysis {
  final int id;
  final String summary;
  final List<RiskFinding> findings;
  RiskAnalysis.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        summary = j['summary'] ?? '',
        findings = ((j['findings'] ?? []) as List).map((e) => RiskFinding.fromJson(e)).toList();
}

class DesignRequest {
  final int id;
  final String status, transcript;
  final Model3D? model;
  DesignRequest.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        status = j['status'] ?? '',
        transcript = j['transcript'] ?? '',
        model = j['model'] != null ? Model3D.fromJson(j['model']) : null;
}

/// HU-18 — boceto 2D generado por prompt (app móvil).
class Boceto2D {
  final int id;
  final int? proyecto;
  final String prompt, imagenUrl, proveedorIa, estado, createdAt;
  Boceto2D.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        proyecto = j['proyecto'],
        prompt = j['prompt'] ?? '',
        imagenUrl = j['imagen_url'] ?? '',
        proveedorIa = j['proveedor_ia'] ?? '',
        estado = j['estado'] ?? '',
        createdAt = j['created_at'] ?? '';
}

/// HU-12 — material del catálogo (calidad de bloque).
/// Nombre `MaterialItem` para no chocar con `Material` de Flutter.
class MaterialItem {
  final int id;
  final String name, unit, unitPrice, blockQuality, categoryName;
  MaterialItem.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        name = j['name'] ?? '',
        unit = j['unit'] ?? '',
        unitPrice = '${j['unit_price'] ?? '0'}',
        blockQuality = j['block_quality'] ?? 'standard',
        categoryName = j['category_name'] ?? '';
}

/// HU-14 — colaborador de un proyecto.
class Member {
  final int id;
  final String userEmail, role;
  Member.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        userEmail = j['user_email'] ?? '',
        role = j['role'] ?? '';
}

/// HU-14 — comentario de un proyecto.
class Comment {
  final int id;
  final String authorEmail, body, createdAt;
  Comment.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        authorEmail = j['author_email'] ?? '',
        body = j['body'] ?? '',
        createdAt = j['created_at'] ?? '';
}

/// HU-17 — plan de suscripción.
class SubscriptionPlan {
  final int id;
  final String code, name, price, interval;
  final List features;
  final bool isActive;
  SubscriptionPlan.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        code = j['code'] ?? '',
        name = j['name'] ?? '',
        price = '${j['price'] ?? '0'}',
        interval = j['interval'] ?? 'month',
        features = (j['features'] ?? []) as List,
        isActive = j['is_active'] ?? true;
}

/// HU-17 — suscripción del usuario.
class Subscription {
  final int id;
  final String status;
  final String? planCode;
  Subscription.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        status = j['status'] ?? '',
        planCode = j['plan_code'];
}
