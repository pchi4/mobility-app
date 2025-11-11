import 'package:flutter/material.dart';

// Este widget é um formulário para coletar detalhes do veículo,
// exibido apenas durante o cadastro de Motorista.
class VehicleDetailsForm extends StatelessWidget {
  const VehicleDetailsForm({
    super.key,
    required this.vehicleModelController,
    required this.licensePlateController,
    required this.vehicleColorController,
    required this.vehicleYearController,
    required this.gradientStart,
    required this.inputFillColor,
    required this.borderRadius,
  });

  final TextEditingController vehicleModelController;
  final TextEditingController licensePlateController;
  final TextEditingController vehicleColorController;
  final TextEditingController vehicleYearController;
  final Color gradientStart;
  final Color inputFillColor;
  final double borderRadius;

  // Helper para construir um campo de texto padrão
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: gradientStart),
        filled: true,
        fillColor: inputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: gradientStart, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),

        // Separador visual para a seção do veículo
        Row(
          children: [
            Expanded(child: Divider(color: gradientStart.withOpacity(0.5))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                'Detalhes do Veículo',
                style: TextStyle(
                  color: gradientStart,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(child: Divider(color: gradientStart.withOpacity(0.5))),
          ],
        ),

        const SizedBox(height: 30),

        // Marca e Modelo
        _buildTextFormField(
          controller: vehicleModelController,
          label: 'Marca e Modelo (Ex: Toyota Corolla)',
          icon: Icons.car_rental_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'O modelo do veículo é obrigatório.';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Placa
        _buildTextFormField(
          controller: licensePlateController,
          label: 'Placa (Ex: AAA1234)',
          icon: Icons.vpn_key_outlined,
          validator: (value) {
            if (value == null || value.isEmpty || value.length < 7) {
              return 'A placa é obrigatória e deve ser completa.';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Cor e Ano (em uma única linha)
        Row(
          children: [
            // Cor
            Expanded(
              child: _buildTextFormField(
                controller: vehicleColorController,
                label: 'Cor',
                icon: Icons.palette_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'A cor é obrigatória.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 20),

            // Ano
            Expanded(
              child: _buildTextFormField(
                controller: vehicleYearController,
                label: 'Ano',
                icon: Icons.calendar_today,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty || value.length != 4) {
                    return 'Ano inválido.';
                  }
                  final year = int.tryParse(value);
                  if (year == null ||
                      year < 2000 ||
                      year > DateTime.now().year + 1) {
                    return 'Ano inválido.';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),

        // O espaçamento final para o botão de cadastro será controlado pela tela pai
      ],
    );
  }
}
