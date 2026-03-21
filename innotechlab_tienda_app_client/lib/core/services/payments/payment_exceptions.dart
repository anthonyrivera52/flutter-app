abstract class PaymentException implements Exception {
  final String message;
  final String? code;

  PaymentException(this.message, {this.code});

  @override
  String toString() =>
      'PaymentException: $message${code != null ? ' (code: $code)' : ''}';
}

class PaymentConnectionException extends PaymentException {
  PaymentConnectionException(super.message);
}

class PaymentValidationException extends PaymentException {
  PaymentValidationException(super.message, {super.code});
}

class PaymentProcessingException extends PaymentException {
  PaymentProcessingException(super.message, {super.code});
}

class PaymentAuthenticationException extends PaymentException {
  PaymentAuthenticationException(super.message, {super.code});
}

class PaymentInsufficientFundsException extends PaymentException {
  PaymentInsufficientFundsException()
    : super('Fondos insuficientes', code: '006');
}

class PaymentCardDeclinedException extends PaymentException {
  PaymentCardDeclinedException() : super('Tarjeta rechazada', code: '005');
}

class PaymentCardExpiredException extends PaymentException {
  PaymentCardExpiredException() : super('Tarjeta expirada', code: '007');
}

class PaymentInvalidCvvException extends PaymentException {
  PaymentInvalidCvvException() : super('CVV inválido', code: '008');
}

class PaymentNetworkException extends PaymentException {
  PaymentNetworkException() : super('Error de red. Verifica tu conexión.');
}

class PaymentCancelledException extends PaymentException {
  PaymentCancelledException() : super('Pago cancelado');
}

class PaymentTimeoutException extends PaymentException {
  PaymentTimeoutException()
    : super('La operación tardó demasiado. Intenta de nuevo.');
}

class PaymentAlreadyProcessedException extends PaymentException {
  PaymentAlreadyProcessedException()
    : super('Esta orden ya tiene un pago procesado');
}

extension PaymentExceptionExtension on PaymentException {
  static PaymentException fromCode(String code, String? message) {
    switch (code) {
      case '005':
        return PaymentCardDeclinedException();
      case '006':
        return PaymentInsufficientFundsException();
      case '007':
        return PaymentCardExpiredException();
      case '008':
        return PaymentInvalidCvvException();
      default:
        return PaymentProcessingException(message ?? 'Error desconocido');
    }
  }
}
