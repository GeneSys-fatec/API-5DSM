class WebFile {
  WebBlob slice(int start, int end) => throw UnsupportedError('Web upload is unavailable');
}

class WebBlob {}

class WebFormData {
  void appendBlob(String name, WebBlob blob, String fileName) {}
  void append(String name, String value) {}
}

class WebHttpRequest {
  int? status;
  Stream<Object> get onLoad => const Stream<Object>.empty();
  Stream<Object> get onError => const Stream<Object>.empty();
  void open(String method, String url) {}
  void setRequestHeader(String name, String value) {}
  void send(WebFormData formData) {}
}

WebBlob webBlob(List<Object> parts) => WebBlob();
WebFormData webFormData() => WebFormData();
WebHttpRequest webHttpRequest() => WebHttpRequest();
