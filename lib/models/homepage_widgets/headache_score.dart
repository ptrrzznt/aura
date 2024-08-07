import 'package:aura/services/openWeather.dart';
import 'package:aura/services/impact.dart';
import 'package:intl/intl.dart';
import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:ml_algo/ml_algo.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HeadacheScore {
  final List<double> _scores = List<double>.filled(7, 0.0);
  final impact = Impact();
  Function()? showToastCallback;

  HeadacheScore({this.showToastCallback});

  double operator [](int index) => _scores[index];

  Future<HeadacheScore> refreshScore() async {
    final stressScore = await getStress();
    final weatherScore = await getWeather();

    DateTime today = DateTime.now();
    DateTime yesterday = today.subtract(const Duration(days: 1));

    final SharedPreferences sp = await SharedPreferences.getInstance();
    final keys = sp.getKeys();

    if ((!keys.contains('lastDayRefreshed'))) {
      sp.setString('lastDayRefreshed', today.toIso8601String());
      sp.setDouble('day0', 0.0);
      sp.setDouble('day1', 0.0);
      sp.setDouble('day2', 0.0);
      sp.setDouble('day3', 0.0);
    }

    for (int i = 3; i < 7; i++) {
      _scores[i] = stressScore[i] + weatherScore[i];
    }

    if (equalDates(DateTime.parse(sp.getString('lastDayRefreshed')!), today)) {
      for (int i = 0; i < 3; i++) {
        _scores[i] = sp.getDouble('day$i')!;
      }
    } else if (equalDates(
        DateTime.parse(sp.getString('lastDayRefreshed')!), yesterday)) {

      sp.setDouble('day0', sp.getDouble('day1')!);
      sp.setDouble('day1', sp.getDouble('day2')!);
      sp.setDouble('day2', sp.getDouble('day3')!);
      sp.setDouble('day3', _scores[3]);
      sp.setString('lastDayRefreshed', today.toIso8601String());

      for (int i = 0; i < 3; i++) {
        _scores[i] = sp.getDouble('day$i')!;
      }
    } else {
      sp.setDouble('day0', 0.0);
      sp.setDouble('day1', 0.0);
      sp.setDouble('day2', 0.0);
      sp.setDouble('day3', _scores[3]);
      sp.setString('lastDayRefreshed', today.toIso8601String());
    }
    return this;
  } //refreshScore

  Future<List<double>> getStress() async {
    final todayData = await impact.getSleepHR();
    final hrv = await impact.calculateHRV();
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final age = sp.getString('age');
    final gender = (sp.getString('gender') == 'man')? 1 : 0;
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    final onMenstrual = ((sp.getString('onMenstrualDate') == formatter.format(DateTime.now())) & (gender == 0))? 1 : 0;

    const featureNames = [
      "hours_of_sleep",
      "heart_rate",
      "SDNN",
      "RMSSD",
      "age",
      'gender', 
      'onMenstrual'
    ];

    List<List<double>> rows =
        List.generate(7, (_) => List.filled(featureNames.length, 0.0));

    rows[3] = [todayData[0], todayData[1], hrv[0].toDouble(), hrv[1].toDouble(), int.parse(age!).toDouble(), gender.toDouble(), onMenstrual.toDouble()];

    for (int i=0; i<5; i++){
      if (rows[3][i] == 0) {
        if (showToastCallback != null) {
          showToastCallback!();
        }
    }
    }
    

    final data = DataFrame([
      featureNames,
      ...rows, 
    ]);

    final json = await rootBundle.loadString('assets/stress_model.json');
    final classifier = DecisionTreeClassifier.fromJson(json);
    final prediction = classifier.predict(data).toMatrix().asFlattenedList;
    for (int i = 4; i < 6; i++) {
      prediction[i] = prediction[3];
    }
    return prediction;
  } //getStress

  Future<List<double>> getWeather() async {
    final pressures = List<double>.filled(7, 0.0, growable: true);
    final dates = unixDates();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int zip = int.parse(prefs.getString('zipCode')!);

    final coordinates = await Openweather().getCoordinates(zip);
    final decodedResponse = await Openweather().getData(coordinates);
    double pressure;

    for (int i = 3; i < 7; i++) {
      final timestamp = dates[i];
      String selected = 'forecast';
      if (i == 3) {
        selected = 'current';
      }

      pressure = getPressureFromTimestamp(timestamp, decodedResponse, selected);
      pressures[i] = pressure;
    }

    final weatherScore = List<double>.filled(7, 0.0);

    for (int i = 3; i < 7; i++) {
      final tmp = pressures[i];
      if (tmp >= 1011.0) {
        weatherScore[i] = 1.0;
      } else if ((tmp < 1011) & (tmp >= 1009)) {
        weatherScore[i] = 3.0;
      } else if ((tmp < 1009) & (tmp >= 1007)) {
        weatherScore[i] = 2.0;
      } else if ((tmp < 1007) & (tmp >= 1005)) {
        weatherScore[i] = 3.0;
      } else if ((tmp < 1005) & (tmp >= 1003)) {
        weatherScore[i] = 4.0;
      } else if ((tmp < 1003) & (tmp >= 1001)) {
        weatherScore[i] = 2.0;
      } else if ((tmp < 1001) & (tmp >= 997)) {
        weatherScore[i] = 1.0;
      } else if (tmp < 997) {
        weatherScore[i] = 0.0;
      }
    }
    return weatherScore;
  } //getWeather
}

double getPressureFromTimestamp(
    int timestamp, Map<String, dynamic> decodedResponse, String selected) {
  double pressure = 0.0;

  if (selected == 'current') {
    if (decodedResponse['current'] != null &&
        decodedResponse['current']['pressure_mb'] != null) {
      pressure = decodedResponse['current']['pressure_mb'];
      //print('current timestamp found');
    } else {
      print("Error: 'current' or 'pressure_mb' is null in decodedResponse");
    }
  } else {
    if (decodedResponse['forecast'] != null &&
        decodedResponse['forecast']['forecastday'] != null) {
      for (var forecastday in decodedResponse['forecast']['forecastday']) {
        if (forecastday['hour'] != null) {
          for (var value in forecastday['hour']) {
            final forecastTimestamp = value['time_epoch'];
            if (forecastTimestamp == timestamp) {
              if (value['pressure_mb'] != null) {
                pressure = value['pressure_mb'].toDouble();
                //print('timestamp $timestamp found');
              } else {
                print("Error: 'pressure_mb' is null for timestamp: $timestamp");
              }
              break;
            }
          }
        } else {
          print("Error: 'hour' is null in 'forecastday'");
        }
      }
    } else {
      print("Error: 'forecast' or 'forecastday' is null in decodedResponse");
    }
  }
  return pressure;
}

List<int> unixDates() {
  List<DateTime> dates = List<DateTime>.filled(7, DateTime.now());

  for (int i = 0; i < 7; i++) {
    dates[i] =
        DateTime.now().subtract(const Duration(days: 3)).add(Duration(days: i));
  }
  List<int> unixTimestamps = [];
  for (int i = 0; i < dates.length; i++) {
    DateTime noonDate =
        DateTime(dates[i].year, dates[i].month, dates[i].day, 12, 0, 0);
    int unixTimestamp = noonDate.millisecondsSinceEpoch ~/ 1000;
    unixTimestamps.add(unixTimestamp);
  }
  return unixTimestamps;
}

bool equalDates(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
}

