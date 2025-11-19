import 'package:flutter/material.dart';

class AppColors {
  // --------------------------------------------------
  // 🎨 Solid Colors from Image (Renamed)
  // --------------------------------------------------
  static const Color lightLavender = Color(0xFFF4E7F8); // c1
  static const Color warmBeigePink = Color(0xFFF2DDDC); // c2
  static const Color peachPink = Color(0xFFF6BCBA);     // c3
  static const Color softLilac = Color(0xFFE3AADD);     // c4
  static const Color lavenderPurple = Color(0xFFC8A8E9); // c5
  static const Color coolLavenderBlue = Color(0xFFC3C7F4); // c6



  // --------------------------------------------------
  // 🎨 Shades for Light Lavender
  // --------------------------------------------------
  static const Color lightLavenderVeryLight = Color(0xFFFDF7FF);
  static const Color lightLavenderLight = Color(0xFFF9EFFF);
  static const Color lightLavenderDark = Color(0xFFE6D0F0);
  static const Color lightLavenderVeryDark = Color(0xFFD1B0E3);

  // --------------------------------------------------
  // 🎨 Shades for Warm Beige Pink
  // --------------------------------------------------
  static const Color warmBeigePinkVeryLight = Color(0xFFFFF7F6);
  static const Color warmBeigePinkLight = Color(0xFFFFEBE9);
  static const Color warmBeigePinkDark = Color(0xFFE0C3C2);
  static const Color warmBeigePinkVeryDark = Color(0xFFCCA6A5);

  // --------------------------------------------------
  // 🎨 Shades for Peach Pink
  // --------------------------------------------------
  static const Color peachPinkVeryLight = Color(0xFFFFF1F0);
  static const Color peachPinkLight = Color(0xFFFFD9D7);
  static const Color peachPinkDark = Color(0xFFE89A97);
  static const Color peachPinkVeryDark = Color(0xFFDC7773);

  // --------------------------------------------------
  // 🎨 Shades for Soft Lilac
  // --------------------------------------------------
  static const Color softLilacVeryLight = Color(0xFFFFF0FA);
  static const Color softLilacLight = Color(0xFFF8DAF3);
  static const Color softLilacDark = Color(0xFFC68BC5);
  static const Color softLilacVeryDark = Color(0xFFA56BA8);

  // --------------------------------------------------
  // 🎨 Shades for Lavender Purple
  // --------------------------------------------------
  static const Color lavenderPurpleVeryLight = Color(0xFFF4EEFC);
  static const Color lavenderPurpleLight = Color(0xFFEBDCF7);
  static const Color lavenderPurpleDark = Color(0xFFA785D0);
  static const Color lavenderPurpleVeryDark = Color(0xFF8A63B7);

  // --------------------------------------------------
  // 🎨 Shades for Cool Lavender Blue
  // --------------------------------------------------
  static const Color coolLavenderBlueVeryLight = Color(0xFFF2F3FF);
  static const Color coolLavenderBlueLight = Color(0xFFE1E4FF);
  static const Color coolLavenderBlueDark = Color(0xFFA0A7E0);
  static const Color coolLavenderBlueVeryDark = Color(0xFF7B83C7);

  // --------------------------------------------------
  // 🎨 Shades for bgLavender
  // --------------------------------------------------
  static const Color bgLavenderVeryLight = Color(0xFFFFF2FF);
  static const Color bgLavenderLight = Color(0xFFF9E0FF);
  static const Color bgLavender = Color(0xFFEEC7F4); // main
  static const Color bgLavenderDark = Color(0xFFD6A0E0);
  static const Color bgLavenderVeryDark = Color(0xFFB77AC9);

  // --------------------------------------------------
  // 🎨 Shades for bgSoftPink
  // --------------------------------------------------
  static const Color bgSoftPinkVeryLight = Color(0xFFFFF8F9);
  static const Color bgSoftPinkLight = Color(0xFFFFEAF0);
  static const Color bgSoftPink = Color(0xFFF5CDE2); // main
  static const Color bgSoftPinkDark = Color(0xFFE5A8C9);
  static const Color bgSoftPinkVeryDark = Color(0xFFCF82AC);

  // --------------------------------------------------
  // 🎨 Shades for bgWarmPink fatima used for story 
  // --------------------------------------------------
  static const Color bgWarmPinkVeryLight = Color(0xFFFFF5F5);
  static const Color bgWarmPinkLight = Color(0xFFFFE0E0);
  static const Color bgWarmPink = Color(0xFFFFD1DA); // main
  static const Color bgWarmPinkDark = Color(0xFFEBA1AB);
  static const Color bgWarmPinkVeryDark = Color(0xFFD97B83);

  // --------------------------------------------------
  // 🎨 Shades for bgBlushRose
  // --------------------------------------------------
  static const Color bgBlushRoseVeryLight = Color(0xFFFFF5F5);
  static const Color bgBlushRoseLight = Color(0xFFFFE2E2);
  static const Color bgBlushRose = Color(0xFFFFC6D3); // main
  static const Color bgBlushRoseDark = Color(0xFFE8A2B0);
  static const Color bgBlushRoseVeryDark = Color(0xFFC87D8C);


  // --------------------------------------------------
  // 🌈 Gradients Between Adjacent Colors
  // --------------------------------------------------
  static const Gradient lightToBeige = LinearGradient(
    colors: [lightLavender, warmBeigePink],
  );

  static const Gradient beigeToPeach = LinearGradient(
    colors: [warmBeigePink, peachPink],
  );

  static const Gradient peachToLilac = LinearGradient(
    colors: [peachPink, softLilac],
  );

  static const Gradient lilacToPurple = LinearGradient(
    colors: [softLilac, lavenderPurple],
  );

  static const Gradient purpleToBlue = LinearGradient(
    colors: [lavenderPurple, coolLavenderBlue],
  );

  // --------------------------------------------------
  // 🌈 Extended Combined Gradients
  // --------------------------------------------------
  static const Gradient softPastel = LinearGradient(
    colors: [lightLavender, warmBeigePink, peachPink],
  );

  static const Gradient deepPastel = LinearGradient(
    colors: [peachPink, softLilac, lavenderPurple, coolLavenderBlue],
  );

  // --------------------------------------------------
  // 🌈 Full Gradient (Top → Bottom)
  // --------------------------------------------------
  static const Gradient fullPastelGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      lightLavender,
      warmBeigePink,
      peachPink,
      softLilac,
      lavenderPurple,
      coolLavenderBlue,
    ],
  );

  // --------------------------------------------------
  // 🌈 Simple Vertical Gradient
  // --------------------------------------------------
  static const Gradient verticalSoft = LinearGradient(
    colors: [lightLavender, coolLavenderBlue],
  );



  // --------------------------------------------------
  // 🌈 Background Gradients (Code 2)
  // --------------------------------------------------
  static const Gradient bgLavenderToSoftPink = LinearGradient(
    colors: [bgLavender, bgSoftPink],
  );

  static const Gradient bgSoftPinkToWarmPink = LinearGradient(
    colors: [bgSoftPink, bgWarmPink],
  );

  static const Gradient bgWarmPinkToBlush = LinearGradient(
    colors: [bgWarmPink, bgBlushRose],
  );

  static const Gradient bgLavenderToWarmPink = LinearGradient(
    colors: [bgLavender, bgWarmPink],
  );

  static const Gradient bgSoftPinkToBlush = LinearGradient(
    colors: [bgSoftPink, bgBlushRose],
  );

  static const Gradient bgFullBlend = LinearGradient(
    colors: [bgLavender, bgSoftPink, bgWarmPink, bgBlushRose],
  );

  static const Gradient bgOriginal = LinearGradient(
    colors: [bgLavender, bgBlushRose],
  );

static const Gradient pinkToPeach = LinearGradient(
  colors: [
    AppColors.bgSoftPinkDark, 
     AppColors.bgSoftPink,        
     AppColors.bgWarmPink,   
     AppColors.peachPinkLight,   





  ],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);


}
