import 'package:flutter/material.dart';
import 'package:climatea/utilities/constants.dart';

class CityScreen extends StatefulWidget {
  const CityScreen({super.key});

  @override
  State<CityScreen> createState() => _CityScreenState();
}

class _CityScreenState extends State<CityScreen> {
  String cityName = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/city_background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        constraints: const BoxConstraints.expand(),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.topLeft,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(
                    Icons.arrow_back_ios,
                    size: 40.0,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20.0),
                child: TextField(
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  decoration: textFieldDeco,
                  onChanged: (value) {
                    cityName = value;
                  },
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context, cityName.trim());
                },
                child: Text(
                  'Get Climate View',
                  style: kButtonTextStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}