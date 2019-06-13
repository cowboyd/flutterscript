import "dart:io";
import "dart:async";
import "dart:convert";

main(List<String> args) async {
  var client = Client(Uri.parse(args.first));

  var lines = stdin.transform(Utf8Decoder()).transform(LineSplitter());

  stdout.write("> ");
  await for (String line in lines) {
    var response = await client.eval(line);
    await stdout.addStream(response);
    stdout.write("\n> ");
  }
}

class Client {
  HttpClient http;
  Uri uri;

  Client(this.uri) {
    this.http = HttpClient();
  }

  Future<Stream<List<int>>> eval(String line) async {
    var request = await http.openUrl("POST", uri);
    request.add(Utf8Codec().encode(line));
    return request.close();

  }
}
