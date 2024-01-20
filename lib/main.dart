import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Log App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StudyLogScreen(),
    );
  }
}

class StudyLogScreen extends StatefulWidget {
  @override
  _StudyLogScreenState createState() => _StudyLogScreenState();
}

class _StudyLogScreenState extends State<StudyLogScreen> {
  TextEditingController _userController = TextEditingController();
  TextEditingController _subjectController = TextEditingController();
  TextEditingController _chapterController = TextEditingController();
  TextEditingController _taskDoneController = TextEditingController();
  TextEditingController _percentCompletedController = TextEditingController();
  List<Map<String, dynamic>> _studyLogs = [];
  String _adminPassword = '2429'; // Replace with a secure password
  bool _isAdminLoggedIn = false;
  DateTime _examDate = DateTime(2024, 2, 21);
  int? _daysLeft;

  @override
  void initState() {
    super.initState();
    _updateDaysLeft();
  }

  void _updateDaysLeft() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30)); // Indian Standard Time (IST) offset
    final difference = _examDate.difference(now);
    _daysLeft = difference.inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Study Log App'),
      ),
      backgroundColor: Colors.purple[50],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20),
            Text(
              'Boards in: ' + _daysLeft.toString() + ' days',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _userController,
              decoration: InputDecoration(labelText: 'Enter your name'),
            ),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(labelText: 'Enter the subject'),
            ),
            TextField(
              controller: _chapterController,
              decoration: InputDecoration(labelText: 'Enter the chapter'),
            ),
            TextField(
              controller: _taskDoneController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(labelText: 'Enter the task done'),
            ),
            TextField(
              controller: _percentCompletedController,
              decoration: InputDecoration(labelText: 'Enter % completed'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                logStudy();
              },
              child: Text('Log Study'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _isAdminLoggedIn ? viewAdminLogs() : showAdminLoginDialog();
              },
              child: Text(_isAdminLoggedIn ? 'View Admin Logs' : 'Admin Login'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _studyLogs.length,
                itemBuilder: (context, index) {
                  var log = _studyLogs[index];
                  return ListTile(
                    title: Text(
                      '${log['user']} - Subject: ${log['subject']}, Chapter: ${log['chapter']}, Task Done: ${log['taskDone']}, % Completed: ${log['percentCompleted']}%',
                    ),
                    subtitle: Text(log['timestamp']),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void logStudy() async {
    String user = _userController.text;
    String subject = _subjectController.text;
    String chapter = _chapterController.text;
    String taskDone = _taskDoneController.text;
    String percentCompleted = _percentCompletedController.text;
    String timestamp = DateTime.now().toString();

    Map<String, dynamic> studyEntry = {
      'user': user,
      'subject': subject,
      'chapter': chapter,
      'taskDone': taskDone,
      'percentCompleted': percentCompleted,
      'timestamp': timestamp,
    };

    // Make a POST request to the Flask server
    await http.post(
      Uri.parse('http://your-flask-server-url/study_logs'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(studyEntry),
    );

    // Update the local study logs
    setState(() {
      _studyLogs.add(studyEntry);
    });
  }

  void viewAdminLogs() async {
    // Make a GET request to the Flask server to fetch admin logs
    final response = await http.get('http://your-flask-server-url/study_logs');

    if (response.statusCode == 200) {
      // Parse the JSON response
      List<dynamic> logs = jsonDecode(response.body)['study_logs'];

      // Update the local study logs
      setState(() {
        _studyLogs = logs.cast<Map<String, dynamic>>();
      });

      // Show the admin logs dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Admin Logs'),
            content: Container(
              width: double.maxFinite,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Subject')),
                  DataColumn(label: Text('Chapter')),
                  DataColumn(label: Text('% Completed')),
                ],
                rows: _studyLogs.map((log) {
                  return DataRow(cells: [
                    DataCell(Text(log['user'])),
                    DataCell(Text(log['subject'])),
                    DataCell(Text(log['chapter'])),
                    DataCell(Text('${log['percentCompleted']}%')),
                  ]);
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    } else {
      // Handle error
      print('Failed to fetch admin logs. Status code: ${response.statusCode}');
    }
  }

  void showAdminLoginDialog() {
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Admin Login'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Enter Admin Password'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (passwordController.text == _adminPassword) {
                  Navigator.of(context).pop();
                  setState(() {
                    _isAdminLoggedIn = true;
                  });
                  viewAdminLogs();
                } else {
                  Navigator.of(context).pop();
                  showAdminLoginError();
                }
              },
              child: Text('Login'),
            ),
          ],
        );
      },
    );
  }

  void showAdminLoginError() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text('Invalid Admin Password'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
