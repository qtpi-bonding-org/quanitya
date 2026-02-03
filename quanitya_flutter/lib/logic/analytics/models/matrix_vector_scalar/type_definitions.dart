/// Base type definitions for the matrix-vector-scalar system.
///
/// These typedefs provide mathematical precision and clarity for
/// analysis operations while maintaining flexibility.
library;

/// Flexible numeric type - can be int or double
typedef Numeric = num;

/// Single value: 42.0
typedef Scalar = Numeric;

/// 1D array: [7.5, 8.2, 6.9]
typedef Vector = List<Numeric>;

/// 2D array: [[timestamp, value], ...]
typedef Matrix = List<List<Numeric>>;