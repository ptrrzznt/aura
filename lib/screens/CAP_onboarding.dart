import 'package:aura/models/palette.dart';
import 'package:aura/screens/Homepage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final TextEditingController _capController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  void _submitCap() async {
    setState(() {
      _errorMessage = '';
    });

    String cap = _capController.text;

    if (cap.isEmpty) {
      setState(() {
        _errorMessage = 'CAP is neccessary';
        _isLoading = false;
      });
      return;
    }

    if (cap.length != 5) {
      setState(() {
        _errorMessage = 'CAP must be 5 numbers';
        _isLoading = false;
      });
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(cap)) {
      setState(() {
        _errorMessage = 'CAP must contain only numbers';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('address', cap);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Homepage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Palette.white,
            Palette.blue,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Enter your CAP', style: TextStyle(fontSize: 24)),
                SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: TextField(
                    controller: _capController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'CAP',
                      labelStyle: TextStyle(color: Colors.white, fontSize: 15),
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                _errorMessage.isNotEmpty
                    ? Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
                      )
                    : SizedBox.shrink(),
                SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _submitCap,
                        child: Text('Submit'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}