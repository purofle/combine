import 'package:combine/src/combine_isolate/combine_isolate.dart';
import 'package:combine/src/isolate_context.dart';
import 'package:combine/src/isolate_factory/native_isolate_factory.dart'
    if (dart.library.html) 'package:combine/src/isolate_factory/web_isolate_factory.dart';

/// [Combine] is used to [spawn] a new [CombineIsolate].
class Combine {
  factory Combine() {
    return _instance;
  }

  Combine._();

  /// `late` is used to make this singleton lazy. So it will be initialized
  /// only while first usage.
  static late final _instance = Combine._();

  final _isolateFactory = IsolateFactoryImpl();

  /// Create a new [CombineIsolate] which is just a representation of `Isolate`
  /// so when you create a [CombineIsolate].
  ///
  /// `Isolate` will be created under the hood except web platform.
  ///
  /// [entryPoint] is a function which will be called in Isolate.
  Future<CombineIsolate> spawn<T>(
    IsolateEntryPoint<T> entryPoint, {
    T? argument,
    bool errorsAreFatal = true,
    String? debugName = "combine_isolate",
  }) async {
    return _isolateFactory.create(
      entryPoint,
      argument: argument,
      debugName: debugName,
      errorsAreFatal: errorsAreFatal,
    );
  }
}

/// Typedef for a function which will be called in Isolate.
typedef IsolateEntryPoint<T> = void Function(IsolateContext context);
