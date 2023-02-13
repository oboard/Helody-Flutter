//LazyTodoUUID => L U I D
import 'dart:math';

const urlAlphabet = 'FILTHM123456789abcdefghijklmnopqrstuvwxyz';

class Luid {
  String v1() {
    return '${nanoId(4)}23${nanoId(4)}a';
  }

  String nanoId([int size = 21]) {
    return customAlphabet(urlAlphabet, size);
  }

  String customAlphabet(String alphabet, int size) {
    final len = alphabet.length;
    String id = '';
    while (0 < size--) {
      id += alphabet[Random.secure().nextInt(len)];
    }
    return id;
  }
}
