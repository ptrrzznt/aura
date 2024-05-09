import 'package:flutter/material.dart';

class MusicSolution extends StatelessWidget {
  const MusicSolution({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chill with some tunes'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('To the home'),
              onPressed: () {
                //This allows to get back to the HomePage
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  
}