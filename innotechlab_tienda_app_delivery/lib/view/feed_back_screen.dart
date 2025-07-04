import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>(); // Key for form validation
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  // You might want to pre-fill the driver's email/ID if they are logged in
  // For simplicity, we'll assume the app knows who the user is.
  // If not, you might add a 'contact email' field.

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    if (_formKey.currentState!.validate()) {
      // Form is valid, process the feedback
      final String subject = _subjectController.text.trim();
      final String message = _messageController.text.trim();

      // TODO: Implement your logic here to send the feedback.
      // This could involve:
      // 1. Calling an API endpoint to submit the feedback.
      // 2. Sending an email (e.g., using a package like url_launcher for mailto:).
      // 3. Storing it in a database to be reviewed later.

      // For now, let's just print to console and show a success message.
      print('Feedback Submitted:');
      print('Subject: $subject');
      print('Message: $message');

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu feedback ha sido enviado, ¡gracias!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear the form fields
      _subjectController.clear();
      _messageController.clear();

      // Optionally, pop the screen after submission
      // Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayuda y Sugerencias'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¡Queremos escucharte!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Por favor, describe tu queja, petición o sugerencia para mejorar la aplicación o el sistema.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // Subject Field
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Asunto',
                  hintText: 'Ej: Problema con un pedido, Sugerencia de función',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.subject),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa un asunto.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Message Field
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Mensaje',
                  hintText: 'Describe tu queja, petición o sugerencia aquí...',
                  alignLabelWithHint: true, // Aligns label to top for multiline input
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.fromLTRB(12, 12, 12, 0), // Adjust padding for top icon
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Icon(Icons.message),
                    ),
                  ),
                ),
                maxLines: 6, // Allow multiple lines for the message
                keyboardType: TextInputType.multiline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa tu mensaje.';
                  }
                  if (value.length < 10) {
                    return 'El mensaje debe tener al menos 10 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity, // Make button full width
                child: ElevatedButton.icon(
                  onPressed: _submitFeedback,
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text(
                    'Enviar Feedback',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor, // Use your app's primary color
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}