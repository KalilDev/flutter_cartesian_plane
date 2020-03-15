double inverseLerp(num a, num b, num y) {
  if (a == null || b == null || y == null) {
    return null;
  }
  return (y - a) / (b - a);
}
