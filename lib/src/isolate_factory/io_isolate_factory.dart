import 'dart:async';
import 'dart:isolate';

import 'package:combine/combine.dart';
import 'package:combine/src/bindings/isolate_binding.dart';
import 'package:combine/src/combine_isolate/io_combine_isolate.dart';
import 'package:combine/src/isolate_factory/i_isolate_factory.dart';
import 'package:combine/src/isolate_messenger/internal_isolate_messenger/io_internal_isolate_messenger.dart';
import 'package:combine/src/method_channel_middleware/isolated_method_channel_middleware.dart';
import 'package:combine/src/method_channel_middleware/ui_method_channel_middleware.dart';
import 'package:flutter/services.dart';

class IOIsolateFactory extends IIsolateFactory {
  @override
  Future<ICombineIsolate> create<T>(
    IsolateEntryPoint<T> entryPoint, {
    Map<String, Object?>? argumentsMap,
    T? argument,
    String? debugName,
    bool errorsAreFatal = true,
  }) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn<_IsolateSetup<T>>(
      _runInIsolate<T>,
      _IsolateSetup<T>(
        receivePort.sendPort,
        entryPoint,
        argumentsMap,
        argument,
      ),
      debugName: debugName,
      errorsAreFatal: errorsAreFatal,
    );

    final receivePortStream = receivePort.asBroadcastStream().cast<Object>();
    final sendPort = await receivePortStream.first as SendPort;

    final isolateMessenger = IOInternalIsolateMessenger(
      sendPort,
      receivePortStream,
    );

    UIMethodChannelMiddleware(
      ServicesBinding.instance!.defaultBinaryMessenger,
      isolateMessenger,
    ).initialize();
    return IOCombineIsolate(isolate, isolateMessenger.toIsolateMessenger());
  }

  static void _runInIsolate<T>(_IsolateSetup<T> setup) {
    final receivePort = ReceivePort();
    final isolateMessenger = IOInternalIsolateMessenger(
      setup.sendPort,
      receivePort.asBroadcastStream().cast<Object>(),
    );
    isolateMessenger.send(receivePort.sendPort);

    final isolateContext = IsolateContext(
      argumentsMap: setup.argumentsMap ?? {},
      argument: setup.argument,
      isolateMessenger: isolateMessenger.toIsolateMessenger(),
    );

    IsolatedMethodChannelMiddleware(isolateMessenger).initialize();
    IsolateBinding();
    setup.entryPoint(isolateContext);
  }
}

class _IsolateSetup<T> {
  _IsolateSetup(
    this.sendPort,
    this.entryPoint,
    this.argumentsMap,
    this.argument,
  );

  final SendPort sendPort;
  final IsolateEntryPoint<T> entryPoint;
  final Map<String, Object?>? argumentsMap;
  final T? argument;
}
