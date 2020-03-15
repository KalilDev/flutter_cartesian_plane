export 'sdk/process_image.dart'
  if (dart.library.isolate) 'isolate/parallel_process_image.dart' 
  if (dart.library.html) 'html/parallel_process_image.dart' show parallelProcessImage;