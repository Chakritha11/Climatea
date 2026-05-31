import 'package:flutter/material.dart';

class LocationScreenn extends StatelessWidget {
  const LocationScreenn({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Location Screen"),
      ),
      body: Center(
        child: Text("This is the Location Screen"),
      ),
    );
  }
} 
