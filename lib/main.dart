import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';

void main() => runApp(MyApp());

enum Valik { Esimene, Teine, Kolmas, Enda_oma }
enum Algo { FCFS, SJF, RR3, TL_FCFS }

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Valik _valik = Valik.Esimene;
  TextEditingController _controller = TextEditingController();
  List<Widget> bodyList;
  bool hasResult = false;
  bool error = false;

  Widget resWidget;
  FocusNode focus = FocusNode();

  @override
  void initState() {
    resWidget = Padding(
      padding: EdgeInsets.all(50.0),
    );
    focus.addListener(() => setState(() => _valik = Valik.Enda_oma));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bodyList = List.generate(
      Valik.values.length,
      (index) => RadioListTile<Valik>(
        title: Row(
          children: [
            Text(Valik.values[index].toString().replaceFirst("Valik.", "").replaceAll("_", " ")),
            Spacer(),
            Text(index != 3 ? getData(Valik.values[index]) : ""),
          ],
        ),
        value: Valik.values[index],
        groupValue: _valik,
        onChanged: (Valik value) {
          setState(() {
            _valik = Valik.values[index];
          });
        },
      ),
    );
    bodyList.add(Padding(
      padding: const EdgeInsets.all(30.0),
      child: TextField(
        focusNode: focus,
        controller: _controller,
        decoration: InputDecoration(
          hintText: "Sisesta järjend kujul 1,10;4,2;12,3;13,2",
          errorText: error ? "Vigane järjend" : null,
        ),
      ),
    ));

    return MaterialApp(
      title: 'Protsessoriaja haldus',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Protsessoriaja haldus'),
        ),
        body: Center(
          child: Column(
            children: [
              Column(children: bodyList),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  Algo.values.length,
                  (index) => Flexible(
                    flex: 1,
                    child: RaisedButton(
                      onPressed: () {
                        try{
                          runAlgo(Algo.values[index]);
                          setState(() {
                            error = false;
                          });
                        } on Exception catch(e){
                          print(e);
                          setState(() {
                            error = true;
                          });
                        }
                      },
                      child: Text(Algo.values[index].toString().replaceFirst("Algo.", "")),
                    ),
                  ),
                ),
              ),
              resWidget,
            ],
          ),
        ),
      ),
    );
  }

  String getData(Valik valik) {
    switch (valik) {
      case Valik.Esimene:
        return "0,5;6,9;6,5;15,10";
      case Valik.Teine:
        return "0,2;0,4;12,4;15,5;21,10";
      case Valik.Kolmas:
        return "5,6;6,9;11,3;12,7";
      case Valik.Enda_oma:
        return _controller.text;
      default:
        return "";
    }
  }

  void runAlgo(Algo algo) {
    var rawInput = getData(_valik).split(";");
    List<List<num>> processes = new List.generate(rawInput.length, (i) {
      var str = rawInput[i].split(",");
      return [int.parse(str[0]), int.parse(str[1])];
    });

    switch (algo) {
      case Algo.FCFS:
        FCFS(processes);
        break;
      case Algo.SJF:
        SJF(processes);
        break;
      case Algo.RR3:
        // TODO: Handle this case.
        break;
      case Algo.TL_FCFS:
        // TODO: Handle this case.
        break;
    }
  }

  void FCFS(List<List<num>> processes) {
    num totalTime = 0;
    num count = 1;
    num totalWait = 0;
    List<ProcessBar> resList = new List();
    for (var process in processes) {
      if (process[0] > totalTime) {
        int time = process[0] - totalTime;
        resList.add(new ProcessBar(totalTime, totalTime + time, "", Colors.grey));
        totalTime += time;
      }
      var color = Colors.green;
      if (process[0] < totalTime) {
        totalWait += totalTime - process[0];
        color = Colors.orange;
      }
      resList.add(ProcessBar(totalTime, totalTime + process[1], "P$count", color));
      totalTime += process[1];
      count += 1;
    }
    setState(() {
      resWidget = ResultContainer(totalWait / processes.length, resList);
    });
  }

  void SJF(List<List<num>> processes) {
    print("Starting SJF with $processes");
    num totalTime = 0;
    num count = 0;
    num totalWait = 0;
    List<ProcessBar> resList = new List();
    List<Color> colors = List.generate(processes.length, (index) => Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0));
    var delayProcess = [0, double.infinity, -1];

    List<num> currentProcess = delayProcess;
    num currentWork = 0;
    Queue<List<num>> backlog = new Queue();
    while (true) {
      if (currentProcess[1] == 0) {
        resList.add(ProcessBar(totalTime - currentWork, totalTime, currentProcess[2] != -1 ? "P${currentProcess[2] + 1}" : "", currentProcess[2] != -1 ? colors[currentProcess[2]] : Colors.grey));
        print("Finished P${currentProcess[2] + 1}, saving P${currentProcess[2] + 1} work ($currentWork) in bar");
        currentWork = 0;
        if (backlog.isNotEmpty) {
          currentProcess = backlog.removeLast();
          print("\tStarting P${currentProcess[2] + 1} again");
        } else {
          print("\tQueue, is empty, starting delay task");
          currentProcess = delayProcess;
        }
      }

      if (count <= processes.length - 1) {
        while (processes[count][0] <= totalTime) {
          print("Starting process P${count + 1} ${processes[count]} at time $totalTime");
          processes[count].add(count);
          if (processes[count][1] < currentProcess[1]) {
            if (currentWork != 0) {
              resList
                  .add(ProcessBar(totalTime - currentWork, totalTime, currentProcess[2] != -1 ? "P${currentProcess[2] + 1}" : "", currentProcess[2] != -1 ? colors[currentProcess[2]] : Colors.grey));
            }
            print("\tNew process is shorter than existing, saving P${currentProcess[2] + 1} work ($currentWork) in bar and starting P${count + 1}");
            currentWork = 0;

            if (currentProcess[2] != -1) backlog.add(currentProcess);
            currentProcess = processes[count];
          } else {
            print("\tNew process is longer than existing, adding to queue");
            backlog.add(processes[count]);
          }
          count++;
          if (count > processes.length - 1) break;
        }
      }

      if (currentProcess[2] == -1 && count >= processes.length) {
        print("Finished SJF");
        break;
      }

      currentProcess[1]--;
      currentWork++;
      totalTime++;
      backlog.forEach((element) => totalWait++);
      print("#######P${currentProcess[2] + 1} $currentProcess, currentWork: $currentWork, time: $totalTime, totalWait: $totalWait, count $count, backlog: $backlog");
      if (totalTime > 60) break;
    }

    setState(() {
      resWidget = ResultContainer(totalWait / processes.length, resList);
    });
  }
}

class ResultContainer extends StatelessWidget {
  final double avgWait;
  final List<ProcessBar> list;

  const ResultContainer(this.avgWait, this.list);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(50.0),
      child: Column(
        children: [
          Text("Keskmine ooteaeg: ${avgWait.toStringAsFixed(2)}"),
          SizedBox(
            height: 20,
          ),
          Row(
            children: list,
          )
        ],
      ),
    );
  }
}

class ProcessBar extends StatelessWidget {
  final int start;
  final int end;
  final String text;
  final Color color;

  const ProcessBar(this.start, this.end, this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: end - start,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          border: Border(
            right: BorderSide(),
            left: BorderSide(color: Colors.black.withAlpha(start == 0 ? 255 : 0)),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Text(
                text,
                style: TextStyle(color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white),
              ),
            ),
            Positioned(
              right: 0,
              bottom: -20,
              child: Text(end.toString()),
            ),
            Positioned(
              left: 0,
              bottom: -20,
              child: Text(start == 0 ? '0' : ''),
            ),
          ],
        ),
      ),
    );
  }
}
