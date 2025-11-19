import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobility_app/models/document_models.dart';

// Importe o enum e o modelo de dados se estiverem em um arquivo separado
// import 'document_models.dart';

// === WIDGET AUXILIAR: DocumentStatusTile ===
// Será colocado aqui para fins de código completo
class DocumentStatusTile extends StatelessWidget {
  final DocumentItem document;
  final VoidCallback onUploadPressed;

  const DocumentStatusTile({
    super.key,
    required this.document,
    required this.onUploadPressed,
  });

  Color getStatusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.aprovado:
        return Colors.green.shade700;
      case DocumentStatus.emRevisao:
        return Colors.orange.shade700;
      case DocumentStatus.rejeitado:
      case DocumentStatus.expirado:
        return Colors.red.shade700;
      case DocumentStatus.pendente:
      default:
        return Colors.grey.shade500;
    }
  }

  IconData getStatusIcon(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.aprovado:
        return Icons.check_circle;
      case DocumentStatus.emRevisao:
        return Icons.access_time_filled;
      case DocumentStatus.rejeitado:
      case DocumentStatus.expirado:
        return Icons.cancel;
      case DocumentStatus.pendente:
      default:
        return Icons.upload_file;
    }
  }

  String getStatusText(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.aprovado:
        return 'Aprovado';
      case DocumentStatus.emRevisao:
        return 'Em Revisão';
      case DocumentStatus.rejeitado:
        return 'Rejeitado';
      case DocumentStatus.expirado:
        return 'Expirado';
      case DocumentStatus.pendente:
      default:
        return 'Pendente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(document.status);
    final statusText = getStatusText(document.status);
    final statusIcon = getStatusIcon(document.status);

    // Define a ação principal (o que o botão vai fazer)
    Widget actionButton;
    if (document.status == DocumentStatus.pendente ||
        document.status == DocumentStatus.rejeitado ||
        document.status == DocumentStatus.expirado) {
      actionButton = TextButton.icon(
        onPressed: onUploadPressed,
        icon: const Icon(Icons.cloud_upload),
        label: Text(
          document.status == DocumentStatus.pendente ? 'Upload' : 'Reenviar',
        ),
        style: TextButton.styleFrom(foregroundColor: statusColor),
      );
    } else if (document.status == DocumentStatus.aprovado) {
      actionButton = IconButton(
        icon: const Icon(Icons.visibility, color: Colors.blueGrey),
        onPressed: () {
          // Simular visualização
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Visualizar ${document.title}')),
          );
        },
      );
    } else {
      actionButton = const SizedBox(width: 48); // Espaço para alinhamento
    }

    // Informação secundária (data de expiração ou motivo de rejeição)
    Widget? subtitleWidget;
    if (document.status == DocumentStatus.rejeitado &&
        document.rejectionReason != null) {
      subtitleWidget = Text(
        'Motivo: ${document.rejectionReason!}',
        style: TextStyle(color: Colors.red.shade500, fontSize: 13),
      );
    } else if (document.expiryDate != null &&
        document.status != DocumentStatus.expirado) {
      final formattedDate = DateFormat(
        'dd/MM/yyyy',
      ).format(document.expiryDate!);
      subtitleWidget = Text(
        'Válido até: $formattedDate',
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      );
    } else if (document.status == DocumentStatus.expirado) {
      subtitleWidget = const Text(
        'VENCIDO! Reenvie imediatamente.',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor, size: 30),
        title: Text(
          document.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitleWidget,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              statusText,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            actionButton,
          ],
        ),
        onTap: () {
          // Permite que o usuário clique no item para ver mais detalhes se necessário
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Detalhes de ${document.title}: $statusText'),
            ),
          );
        },
      ),
    );
  }
}
// === FIM DO WIDGET AUXILIAR ===

class DocumentosScreen extends StatefulWidget {
  const DocumentosScreen({super.key});

  @override
  State<DocumentosScreen> createState() => _DocumentosScreenState();
}

class _DocumentosScreenState extends State<DocumentosScreen> {
  // Mock de dados dos documentos
  List<DocumentItem> driverDocuments = [
    DocumentItem(
      title: 'CNH (Carteira Nacional de Habilitação)',
      status: DocumentStatus.rejeitado,
      rejectionReason: 'Foto desfocada. Reenvie.',
      expiryDate: DateTime.now().add(const Duration(days: 300)),
    ),
    DocumentItem(
      title: 'CRLV (Veículo)',
      status: DocumentStatus.aprovado,
      expiryDate: DateTime.now().add(const Duration(days: 50)),
    ),
    DocumentItem(
      title: 'Certidão de Antecedentes Criminais',
      status: DocumentStatus.emRevisao,
    ),
    DocumentItem(
      title: 'Comprovante de Residência',
      status: DocumentStatus.pendente,
    ),
    DocumentItem(
      title: 'Seguro APP (Vencido)',
      status: DocumentStatus.expirado,
      expiryDate: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  // Função para simular o upload (em um app real, chamaria a API)
  void _handleUpload(String documentTitle) {
    setState(() {
      final index = driverDocuments.indexWhere(
        (doc) => doc.title == documentTitle,
      );
      if (index != -1) {
        // Simula o envio de um documento para revisão
        driverDocuments[index] = DocumentItem(
          title: documentTitle,
          status: DocumentStatus.emRevisao,
          expiryDate: driverDocuments[index]
              .expiryDate, // Mantém a data de expiração se houver
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Upload de $documentTitle enviado para Revisão!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requiresImmediateAttention = driverDocuments.any(
      (doc) =>
          doc.status == DocumentStatus.rejeitado ||
          doc.status == DocumentStatus.expirado,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos do Motorista'),
        backgroundColor: requiresImmediateAttention
            ? Colors.red.shade700
            : Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (requiresImmediateAttention)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade700),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Atenção! Documentos pendentes, expirados ou rejeitados bloqueiam a sua conta.',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Status de Verificação',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            // Lista de Documentos
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: driverDocuments.length,
              itemBuilder: (context, index) {
                final doc = driverDocuments[index];
                return DocumentStatusTile(
                  document: doc,
                  onUploadPressed: () => _handleUpload(doc.title),
                );
              },
            ),

            const Divider(height: 30, thickness: 1),

            // Área para Notas Legais
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Nota: A análise dos documentos pode levar até 48 horas úteis.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
