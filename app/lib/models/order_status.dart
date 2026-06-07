abstract final class OrderStatuses {
  static const values = ['Обработка', 'Принят', 'Готовится', 'Готов', 'Выдан'];

  static int indexOf(String status) {
    final index = values.indexOf(status);
    return index < 0 ? 0 : index;
  }

  static double progressOf(String status) {
    return (indexOf(status) + 1) / values.length;
  }

  static String? nextAfter(String status) {
    final index = indexOf(status);
    if (index >= values.length - 1) {
      return null;
    }
    return values[index + 1];
  }
}
