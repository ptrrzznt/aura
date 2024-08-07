import 'package:aura/models/work_sans.dart';
import 'package:aura/screens/Accountpage.dart';
import 'package:aura/screens/NPSpage.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:flutter/material.dart';
import 'package:aura/models/day.dart';
import 'package:provider/provider.dart';
import 'package:aura/models/homepage_widgets/headache_score.dart';
import 'package:aura/screens/Metricspage.dart';
import 'package:aura/models/palette.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/homepage_widgets/aura_score_indicator.dart';
import '../models/homepage_widgets/find_solutions.dart';
import '../models/seven_day_calendar.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  HomepageState createState() => HomepageState();
}

class HomepageState extends State<Homepage> with TickerProviderStateMixin {
  int currentIndex = 0;
  late TabController tabController;
  late Future<HeadacheScore> score;
  final day = Day();

  String name = 'User';

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        setState(() {
          currentIndex = tabController.index;
        });
      }
    });
    loadUserName();
    initializeScore();
  }

  // To dispose controllers after use
  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  // To show warnings for missing device data
  void _showErrorToast() {
    CherryToast.warning(
      height: 200,
      width: 400,
      title: const Text(
        'Warning!',
        style: WorkSans.titleSmall,
      ),
      description: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'One or more data not available',
              style:
                  WorkSans.headlineSmall.copyWith(fontWeight: FontWeight.w800),
            ),
            TextSpan(
              text: '\nStress estimate could be inaccurate!',
              style: WorkSans.headlineSmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.left,
      ),
      displayIcon: true,
      animationType: AnimationType.fromTop,
      animationDuration: const Duration(seconds: 1),
      toastDuration: const Duration(seconds: 5),
      inheritThemeColors: true,
      autoDismiss: true,
    ).show(context);
  }

  // Score initialization
  void initializeScore() {
    final headacheScore = HeadacheScore(showToastCallback: _showErrorToast);
    score = headacheScore.refreshScore();
  }

  // To update username
  Future<void> loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? 'User';
    });
  }

  // To change page using TabBar
  void _onItemTapped(int newIndex) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentIndex = newIndex;
      // Update username
      name = prefs.getString('name') ?? 'User';
    });
    tabController.animateTo(newIndex);

    if (newIndex == 0) {
      initializeScore();
      loadUserName();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Palette.white,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Aura"),
        ),
        // Drawer
        drawer: Drawer(
          backgroundColor: Palette.softBlue1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Logo
                Row(children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 60,
                    width: 60,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Aura',
                    style: WorkSans.titleSmall,
                  )
                ]),
                const SizedBox(height: 20),
                // To Homepage
                ListTile(
                  leading: const Icon(
                    Icons.health_and_safety,
                    color: Palette.deepBlue,
                  ),
                  title: const Text(
                    'Aura Score',
                    style: WorkSans.headlineSmall,
                  ),
                  onTap: () {
                    _onItemTapped(0);
                    Navigator.pop(context);
                  },
                ),
                // To Metricspage
                ListTile(
                  leading: const Icon(
                    Icons.query_stats,
                    color: Palette.deepBlue,
                  ),
                  title: const Text(
                    'Metrics',
                    style: WorkSans.headlineSmall,
                  ),
                  onTap: () {
                    _onItemTapped(1);
                    Navigator.pop(context);
                  },
                ),
                // To Accountpage
                ListTile(
                  leading: const Icon(
                    Icons.person,
                    color: Palette.deepBlue,
                  ),
                  title: const Text(
                    'Account',
                    style: WorkSans.headlineSmall,
                  ),
                  onTap: () {
                    _onItemTapped(2);
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                // Logout
                ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: Palette.deepBlue,
                    ),
                    title: const Text(
                      'Logout',
                      style: WorkSans.headlineSmall,
                    ),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: ((context) => NPSpage())));
                    }
                    ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            // Homepage elements
            Positioned(
              child: FutureBuilder<HeadacheScore>(
                future: score,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  final HeadacheScore score = snapshot.data!;
                  return Column(
                    children: [
                      Expanded(
                        child: TabBarView(
                          controller: tabController,
                          children: [
                            SingleChildScrollView(
                              child: Center(
                                  child: SizedBox(
                                      width: 350,
                                      child: Column(children: [
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              15, 0, 10, 0),
                                          child: Row(
                                            children: [
                                              Flexible(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    "Welcome, $name",
                                                    style: WorkSans.displaySmall
                                                        .copyWith(
                                                            color: Palette
                                                                .deepBlue),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              Image.asset(
                                                'assets/waving-hand_1f44b.png',
                                                scale: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 15,
                                        ),
                                        Consumer<Day>(
                                            builder: (context, day, child) {
                                          return Center(
                                              child: FittedBox(
                                                  child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              //TodayDate(day: day),
                                              SevenDayCalendar(day: day),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              // Text(
                                              //   'Your Aura Score:',
                                              //   style: WorkSans.displaySmall
                                              //       .copyWith(
                                              //           fontSize: 25,
                                              //           color: Palette.deepBlue,
                                              //           fontWeight:
                                              //               FontWeight.w400),
                                              // ),
                                              const SizedBox(
                                                height: 5,
                                              ),
                                              AuraScoreIndicator(
                                                  score: score,
                                                  day: day,
                                                  onTap: () =>
                                                      _onItemTapped(1)),
                                              const SizedBox(
                                                height: 20,
                                              ),
                                              const FindSolutions(),
                                            ],
                                          )));
                                        })
                                      ]))),
                            ),
                            Metricspage(),
                            const AccountPage(),
                          ],
                        ),
                      ),
                    
                    ],
                  );
                },
              ),
            ),
            Positioned(
            left: 28,
            right: 28,
            bottom: 30,
            child: Center(
              child: Container(
                height: 70, 
                width: 490,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.health_and_safety, size: 30),
                          onPressed: () => _onItemTapped(0),
                          color: currentIndex == 0 ? Palette.deepBlue : Colors.grey[600],
                        ),
                        Text('Aura Score', style: WorkSans.displaySmall.copyWith(fontSize: 12, color: currentIndex == 0 ? Palette.deepBlue : Colors.grey[700], fontWeight: FontWeight.w400),)
                      ],
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.query_stats, size: 30),
                          onPressed: () => _onItemTapped(1),
                          color: currentIndex == 1 ? Palette.deepBlue : Colors.grey[600],
                        ),
                        Text('Metrics', style: WorkSans.displaySmall.copyWith(fontSize: 12, color: currentIndex == 1 ? Palette.deepBlue : Colors.grey[700], fontWeight: FontWeight.w400),)
                      ],
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.person, size: 30),
                          onPressed: () => _onItemTapped(2),
                          color: currentIndex == 2 ? Palette.deepBlue : Colors.grey[600],
                        ),
                        Text('Account', style: WorkSans.displaySmall.copyWith(fontSize: 12, color: currentIndex == 2 ? Palette.deepBlue : Colors.grey[700], fontWeight: FontWeight.w400),)
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

// text to display according to AuraScore
String getText(double score) {
  if (score < 4) {
    return "Low";
  } else if ((score >= 4) & (score < 6)) {
    return "Medium";
  } else if ((score >= 6) & (score < 8)) {
    return "High";
  } else {
    return "Very high!";
  }
}

// to convert index values in DateTime
DateTime getDateForValue(int value) {
  DateTime now = DateTime.now();
  int difference = value - 3; // 3 is the central value and it represents today
  return now.add(Duration(days: difference));
}

