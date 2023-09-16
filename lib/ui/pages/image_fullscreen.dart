import 'package:flutter/material.dart';

class FullScreenImage extends StatelessWidget {
  final String url;
  const FullScreenImage({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
      ),
      body: Center(
        child: Hero(
          tag: url,
          child: Image.network(url),
        ),
      ),
    );
  }
}