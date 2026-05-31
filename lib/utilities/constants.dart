import 'package:flutter/material.dart';

const kTempTextStyle = TextStyle(
  fontFamily: 'Spartan MB',
  fontSize: 72.0,
  fontWeight: FontWeight.w900,
);

const kMessageTextStyle = TextStyle(
  fontFamily: 'Spartan MB',
  fontSize: 22.0,
  height: 1.4,
);

const kButtonTextStyle = TextStyle(
  fontSize: 22.0,
  fontFamily: 'Spartan MB',
);

const kConditionTextStyle = TextStyle(
  fontSize: 46.0,
);

const kSectionTitleStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

const textFieldDeco = InputDecoration(
  filled: true,
  fillColor: Color(0xFF1A2238),
  icon: Icon(
    Icons.location_city,
    color: Colors.white,
  ),
  hintText: 'Enter City Name',
  hintStyle: TextStyle(
    color: Colors.white70,
  ),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(
      Radius.circular(14.0),
    ),
    borderSide: BorderSide.none,
  ),
);

BoxDecoration glassCard(Color color) {
  return BoxDecoration(
    color: color.withOpacity(0.16),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(
      color: Colors.white.withOpacity(0.15),
      width: 1,
    ),
  );
}