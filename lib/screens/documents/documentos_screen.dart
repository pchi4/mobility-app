import 'package:flutter/material.dart';

// --- Modelo de Documento Simulado ---
class Document {
  final String title;
  final String requiredFor; // Ex: 'Motorista', 'Veículo'
  String status; // Ex: 'Pendente', 'Em Revisão', 'Aprovado', 'Rejeitado'
  String? fileUrl; // URL do arquivo (se já foi enviado)

  Document({
    required this.title,
    required this.requiredFor,
    this.status = 'Pendente',
    this.fileUrl,
  });
}

class DocumentosScreen extends StatefulWidget {
  const DocumentosScreen({super.key});

  @override
  State<DocumentosScreen> createState() => _DocumentosScreenState();
}

class _DocumentosScreenState extends State<DocumentosScreen> {
  // Lista de documentos simulados. Em um app real, isso viria de um serviço.
  final List<Document> documents = [
    Document(
      title: 'CNH (Carteira Nacional de Habilitação)',
      requiredFor: 'Motorista',
    ),
    Document(
      title: 'CRLV (Documento do Veículo)',
      requiredFor: 'Veículo',
      status: 'Em Revisão',
    ),
    Document(
      title: 'Comprovante de Residência',
      requiredFor: 'Motorista',
      status: 'Aprovado',
      fileUrl: 'link_simulado_123',
    ),
    Document(
      title: 'Vistoria Veicular (Opcional)',
      requiredFor: 'Veículo',
      status: 'Rejeitado',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // Calcula o status geral
    final String overallStatus = _getOverallStatus();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Documentos e Validação',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Visão Geral do Status
            _buildOverallStatusCard(overallStatus, primaryColor),

            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Text(
                'Documentos Necessários',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            // 2. Lista de Documentos
            ...documents
                .map((doc) => _buildDocumentTile(doc, primaryColor))
                .toList(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- Funções Auxiliares de UI e Lógica ---

  String _getOverallStatus() {
    if (documents.any((doc) => doc.status == 'Pendente')) {
      return 'Incompleto';
    }
    if (documents.any((doc) => doc.status == 'Rejeitado')) {
      return 'Rejeitado';
    }
    if (documents.any((doc) => doc.status == 'Em Revisão')) {
      return 'Em Revisão';
    }
    return 'Aprovado';
  }

  Widget _buildOverallStatusCard(String status, Color primaryColor) {
    Color cardColor;
    String message;

    switch (status) {
      case 'Aprovado':
        cardColor = Colors.green.shade50;
        message =
            'Parabéns! Todos os seus documentos estão aprovados. Você pode dirigir.';
        break;
      case 'Rejeitado':
        cardColor = Colors.red.shade50;
        message =
            'Atenção! Alguns documentos foram rejeitados. Revise os itens pendentes.';
        break;
      case 'Em Revisão':
        cardColor = Colors.orange.shade50;
        message = 'Seus documentos estão em análise. Aguarde a validação.';
        break;
      case 'Incompleto':
      default:
        cardColor = Colors.blue.shade50;
        message =
            'Faltam documentos para completar seu cadastro. Envie-os para iniciar a validação.';
        break;
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      color: cardColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle_outline, color: primaryColor, size: 30),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Geral: $status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(message, style: TextStyle(color: Colors.grey.shade800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTile(Document doc, Color primaryColor) {
    IconData icon;
    Color color;

    switch (doc.status) {
      case 'Aprovado':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'Rejeitado':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case 'Em Revisão':
        icon = Icons.access_time;
        color = Colors.orange;
        break;
      case 'Pendente':
      default:
        icon = Icons.upload_file;
        color = Colors.grey;
        break;
    }

    // Ação ao clicar no documento
    void handleTap() {
      // Lógica de upload/revisão
      if (doc.status == 'Pendente' || doc.status == 'Rejeitado') {
        _handleUpload(doc);
      } else {
        // Mostrar o arquivo ou detalhes (se houver)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Detalhes do documento ${doc.title} (Status: ${doc.status})',
            ),
          ),
        );
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(
          doc.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'Status: ${doc.status}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        trailing: doc.status == 'Pendente' || doc.status == 'Rejeitado'
            ? Icon(Icons.cloud_upload, color: primaryColor)
            : const Icon(Icons.chevron_right),
        onTap: handleTap,
      ),
    );
  }

  void _handleUpload(Document doc) async {
    // 💡 Lógica de upload real:
    // 1. Abrir seletor de arquivos/câmera.
    // 2. Fazer o upload para o Firebase Storage.
    // 3. Atualizar o status no Firebase Firestore para 'Em Revisão'.

    // Simulação:
    setState(() {
      doc.status = 'Em Revisão';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Abrindo seletor para upload de ${doc.title}...')),
    );
  }
}
