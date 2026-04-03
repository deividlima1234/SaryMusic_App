import 'package:just_audio/just_audio.dart';
void main() async {
  final AndroidEqualizer eq = AndroidEqualizer();
  final params = eq.parameters;
  print(params.runtimeType);
}
