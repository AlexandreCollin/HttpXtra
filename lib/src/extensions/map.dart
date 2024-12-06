extension MergableMap on Map {
  Map<K, V> merge<K, V>(Map<K, V> other) {
    return {...this, ...other};
  }
}
