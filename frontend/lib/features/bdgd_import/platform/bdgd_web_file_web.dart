import 'dart:html' as html;

class WebFile {
  final html.File value;
  WebFile(this.value);

  WebBlob slice(int start, int end) => WebBlob(value.slice(start, end));
}

class WebBlob {
  final html.Blob value;
  WebBlob(this.value);
}

class WebFormData {
  final html.FormData value = html.FormData();

  void appendBlob(String name, WebBlob blob, String fileName) {
    value.appendBlob(name, blob.value, fileName);
  }

  void append(String name, String value) {
    this.value.append(name, value);
  }
}

class WebHttpRequest {
  final html.HttpRequest request = html.HttpRequest();

  int? get status => request.status;
  Stream<html.Event> get onLoad => request.onLoad;
  Stream<html.Event> get onError => request.onError;
  void open(String method, String url) => request.open(method, url);
  void setRequestHeader(String name, String value) => request.setRequestHeader(name, value);
  void send(WebFormData formData) => request.send(formData.value);
}

WebBlob webBlob(List<Object> parts) => WebBlob(html.Blob(parts));
WebFormData webFormData() => WebFormData();
WebHttpRequest webHttpRequest() => WebHttpRequest();
