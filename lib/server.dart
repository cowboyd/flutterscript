import "lisp.dart";
import "dart:io";
import "dart:async";
import "dart:convert";
import "flutterscript.dart";

void main(List<String> args) async {
  Server server = await Server.create(3001);
  print("listening on port 3001");
  await server.listen();
}

class Server {
  FlutterScript interpreter;
  HttpServer http;
  int port;

  Server(this.interpreter, this.http);

  static Future<Server> create(int port) async {
    FlutterScript interp = await FlutterScript.create();
    HttpServer http = await HttpServer.bind(InternetAddress.anyIPv6, port);
    return Server(interp, http);
  }

  listen() async {
    await for (HttpRequest request in http) {
      Stream<String> body = request.transform(Utf8Decoder());
      try {
        var x = await interpreter.evalStream(body);
        request.response.write(str(x));
      } catch (error) {
        request.response.write(error);
      }
      request.response.close();
    }
  }
}
