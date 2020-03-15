import 'dart:async';
import 'dart:isolate';

// This function wraps the low-level Isolate api.
// It requires an static function that will send an sendPort through the
// main sendPort and will listen to the events on it's receive port. The event
// will be of the Message type, and it will be the instance msg. The function
// will perform some computation with this message and then send an response of
// the Result type, which will be used to complete the future, freeing the
// resources afterwards.
Future<Result> runOnIsolate<Result, Message>(
    void Function(SendPort s) F, Message msg) async {
  // Setup communication with isolate
  final mainStream = ReceivePort();
  final errorStream = ReceivePort();
  final exitStream = ReceivePort();
  // Start isolate with F. Sidenote: F needs to be static and send the isolate's
  // sendPort through the main sink. We cannot wrap F because dart isolates can't
  // receive functions (even static ones), so the user MUSTN't fuck this up.
  final isolate = await Isolate.spawn<SendPort>(F, mainStream.sendPort,
      onError: errorStream.sendPort, onExit: exitStream.sendPort);

  void dispose() {
    isolate?.kill(priority: Isolate.immediate);
    mainStream.close();
    errorStream.close();
    exitStream.close();
  }

  final completer = Completer<Result>();

  mainStream.listen((data) {
    if (data is SendPort) {
      // This is the first message, and it ALWAYS should be the isolate's
      // [SendPort]. Be sure that F sends it!!!!
      data.send(msg);
    } else {
      // This is the actual calculation returned from the isolate, it should be
      // of the return type.
      try {
        final result = data as Result;
        completer.complete(result);
      } on CastError catch (e, s) {
        // The stack trace has no relevant info in this case.
        completer.completeError(e, s);
      } finally {
        dispose();
      }
    }
  });
  errorStream.listen((e) {
    completer.completeError(e);
    dispose();
  });
  exitStream.listen((e) {
    if (!completer.isCompleted) {
      // This shoudn't have happened!
      completer.completeError(Exception(
          'The isolate was killed before it completed the calculation!'));
      dispose();
    }
  });

  return completer.future;
}
