import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const TemplateMain());
}

final class TemplateMain extends StatelessWidget {
  const TemplateMain({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      title: 'Flutter Template',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'Flutter Template',
          ),
        ),
      ),
    );
  }
}
