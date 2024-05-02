import 'package:flutter/material.dart';
import 'package:stress/models/headache_score.dart';
import 'package:stress/screens/Splash.dart';
import 'package:provider/provider.dart';


void main(){
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HeadacheScore>(
      create: (context) => HeadacheScore(),
      child: MaterialApp(
        title: 'stress',
        theme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 243, 122, 49)),
          useMaterial3: true,
          
        ),
        home:  Splash()
      )
    );
  }
}



