// Document Status Enum
enum DocumentStatus { aprovado, emRevisao, rejeitado, pendente, expirado }

// Modelo Simples para um Item de Documento
class DocumentItem {
  final String title;
  final DocumentStatus status;
  final String? rejectionReason;
  final DateTime? expiryDate;

  DocumentItem({
    required this.title,
    required this.status,
    this.rejectionReason,
    this.expiryDate,
  });
}
