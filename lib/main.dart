import 'dart:collection';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(MyApp());

enum Valik { Esimene, Teine, Kolmas, Enda_oma }
enum Algo { FCFS, SJF, RR3, TL_FCFS }

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Valik _valik = Valik.Esimene;
  TextEditingController _controller;
  List<Widget> bodyList;
  List<bool> isSelected = List.generate(Algo.values.length, (index) => false);
  bool hasResult = false;
  bool error = false;
  String choiceText = "";

  Widget resWidget;
  FocusNode focus = FocusNode();

  @override
  void initState() {
    _controller = TextEditingController(text: choiceText);
    resWidget = Padding(padding: EdgeInsets.all(50.0));
    focus.addListener(() {
      if (focus.hasFocus) setState(() => _valik = Valik.Enda_oma);
    });
    super.initState();
  }

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
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
        activeColor: Colors.orangeAccent,
        groupValue: _valik,
        onChanged: (Valik value) {
          setState(() {
            _valik = value;
            if (value != Valik.Enda_oma) {
              focus.unfocus();
              error = false;
            } else {
              focus.requestFocus();
            }
            for (int i = 0; i < isSelected.length; i++) if (isSelected[i]) runAlgo(Algo.values[i]);
          });
        },
      ),
    );
    bodyList.add(Flexible(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
        child: TextField(
          cursorColor: Colors.orangeAccent,
          focusNode: focus,
          controller: _controller,
          decoration: InputDecoration(
            hintText: "Sisesta järjend kujul 1,10;4,2;12,3;13,2",
            errorText: error ? "Vigane järjend" : null,
          ),
          onChanged: (s){
            setState(() {
              choiceText = s;
              for (int i = 0; i < isSelected.length; i++) if (isSelected[i]) runAlgo(Algo.values[i]);
            });
          },
        ),
      ),
    ));

    return MaterialApp(
      title: 'Protsessoriaja haldus',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.orange,
        primaryColorDark: Colors.orange,
        accentColor: Colors.orangeAccent,
        highlightColor: Colors.orangeAccent,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Protsessoriaja haldus'),
        ),
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints.tightFor(width: max(700, constraints.maxWidth)),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Column(children: bodyList),
                          ),
                          Flexible(
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    "Protsesside tabel",
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                                Flexible(
                                  child: Builder(
                                    builder: (context) {
                                      List<List<num>> processes;
                                      if(choiceText.isEmpty && _valik == Valik.Enda_oma){
                                        return Container(
                                          color: Colors.grey[600],
                                          alignment: Alignment.center,
                                          child: Text("Sisesta järjend"),
                                        );
                                      }
                                      try {
                                        processes = cleanInput();
                                        processes[processes.length - 1][1];
                                      } on Error {
                                        return Container(
                                          color: Colors.grey[600],
                                          alignment: Alignment.center,
                                          child: Text("Vigane järjend"),
                                        );
                                      } on Exception{
                                        return Container(
                                          color: Colors.grey[600],
                                          alignment: Alignment.center,
                                          child: Text("Vigane järjend"),
                                        );
                                      }
                                      var heading = TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orangeAccent,
                                      );
                                      return Container(
                                        color: Colors.grey[600],
                                        child: Table(
                                          border: TableBorder.all(),
                                          children: List.generate((processes.length + 1), (index) {
                                            if (index == 0) {
                                              return TableRow(
                                                children: [
                                                  TableCellPadded(
                                                    child: Text(
                                                      "ID",
                                                      style: heading,
                                                    ),
                                                  ),
                                                  TableCellPadded(
                                                    child: Text(
                                                      "Saabumise aeg",
                                                      style: heading,
                                                    ),
                                                  ),
                                                  TableCellPadded(
                                                    child: Text(
                                                      "Protsessoriaja soov",
                                                      style: heading,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            } else {
                                              return TableRow(
                                                children: List.generate(
                                                  3,
                                                  (i) => TableCellPadded(
                                                    child: Text(i == 0 ? "P$index" : processes[index - 1][i - 1].toString()),
                                                  ),
                                                ),
                                              );
                                            }
                                          }),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) => ToggleButtons(
                        selectedColor: Colors.orange,
                        selectedBorderColor: Colors.orange[200],
                        fillColor: Colors.grey[700],
                        splashColor: Colors.orangeAccent,
                        isSelected: isSelected,
                        onPressed: (int index) {
                          if (isSelected[index]) {
                            setState(() {
                              isSelected[index] = false;
                              error = false;
                              resWidget = Padding(padding: EdgeInsets.all(50.0));
                            });
                          } else {
                            runAlgo(Algo.values[index]);
                          }
                        },
                        children: List.generate(
                          Algo.values.length,
                          (index) => Container(
                            width: (constraints.maxWidth - 100) / Algo.values.length,
                            alignment: Alignment.center,
                            child: Text(
                              Algo.values[index].toString().replaceFirst("Algo.", ""),
                              style: GoogleFonts.sourceCodePro(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    resWidget,
                  ],
                ),
              ),
            ),
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
        return choiceText;
      default:
        return "";
    }
  }

  List<List<num>> cleanInput() {
    var rawInput = getData(_valik).split(";");
    return List.generate(rawInput.length, (i) {
      var str = rawInput[i].split(",");
      return [int.parse(str[0]), int.parse(str[1])];
    });
  }

  void runAlgo(Algo algo) {
    try {
      List<List<num>> processes = cleanInput();
      switch (algo) {
        case Algo.FCFS:
          FCFS(processes);
          break;
        case Algo.SJF:
          SJF(processes);
          break;
        case Algo.RR3:
          RR(processes, 3);
          break;
        case Algo.TL_FCFS:
          TL_FCFS(processes);
          break;
      }

      setState(() {
        error = false;
        for (int i = 0; i < isSelected.length; i++) {
          isSelected[i] = i == algo.index;
        }
      });
    } on Exception catch (e) {
      print(e);
      setState(() {
        resWidget = Padding(padding: EdgeInsets.all(50.0));
        error = true;
      });
    } on Error catch (e) {
      print(e);
      setState(() {
        resWidget = Padding(padding: EdgeInsets.all(50.0));
        error = true;
      });
    }
  }

  void FCFS(List<List<num>> processes) {
    StringBuffer log = new StringBuffer("Starting FCFS with $processes");
    num totalTime = 0;
    num count = 1;
    num totalWait = 0;
    List<ProcessBar> resList = new List();
    for (var process in processes) {
      if (process[0] > totalTime) {
        int time = process[0] - totalTime;
        log.write("\nWaiting for $time");
        resList.add(new ProcessBar(totalTime, totalTime + time, "", Colors.grey));
        totalTime += time;
      }
      var color = Colors.green;
      if (process[0] < totalTime) {
        log.write("\nP$count is waiting for ${totalTime - process[0]}");
        totalWait += totalTime - process[0];
        color = Colors.orange;
      }
      log.write("\nRunning P$count");
      resList.add(ProcessBar(totalTime, totalTime + process[1], "P$count", color));
      totalTime += process[1];
      count += 1;
    }
    setState(() {
      resWidget = ResultContainer(totalWait / processes.length, resList, log);
    });
  }

  void SJF(List<List<num>> processes) {
    StringBuffer log = new StringBuffer("Starting SJF with $processes");
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
        log.write("\nFinished P${currentProcess[2] + 1}, saving work ($currentWork) in bar");
        currentWork = 0;
        if (backlog.isNotEmpty) {
          currentProcess = backlog.removeLast();
          log.write("\n   Starting P${currentProcess[2] + 1} again");
        } else {
          log.write("\n   Queue, is empty, starting delay task");
          currentProcess = delayProcess;
        }
      }

      if (count <= processes.length - 1) {
        while (processes[count][0] <= totalTime) {
          log.write("\nStarting process P${count + 1} ${processes[count]} at time $totalTime");
          processes[count].add(count);
          if (processes[count][1] < currentProcess[1]) {
            if (currentWork != 0) {
              resList
                  .add(ProcessBar(totalTime - currentWork, totalTime, currentProcess[2] != -1 ? "P${currentProcess[2] + 1}" : "", currentProcess[2] != -1 ? colors[currentProcess[2]] : Colors.grey));
            }
            log.write("\n   New process is shorter than existing, saving work ($currentWork) in bar and starting P${count + 1}");
            currentWork = 0;

            if (currentProcess[2] != -1) backlog.add(currentProcess);
            currentProcess = processes[count];
          } else {
            log.write("\n   New process is longer than existing, adding to queue");
            backlog.add(processes[count]);
          }
          count++;
          if (count > processes.length - 1) break;
        }
      }

      if (currentProcess[2] == -1 && count >= processes.length) {
        log.write("\nFinished SJF");
        break;
      }

      currentProcess[1]--;
      currentWork++;
      totalTime++;
      backlog.forEach((element) => totalWait++);
      log.write("\n#######P${currentProcess[2] + 1} $currentProcess, currentWork: $currentWork, time: $totalTime, totalWait: $totalWait, count $count, backlog: $backlog");
    }

    setState(() {
      resWidget = ResultContainer(totalWait / processes.length, resList, log);
    });
  }

  void RR(List<List<num>> processes, int n) {
    StringBuffer log = new StringBuffer("Starting RR$n with $processes");
    num totalTime = 0;
    num count = 0;
    num totalWait = 0;
    List<ProcessBar> resList = new List();
    List<Color> colors = List.generate(processes.length, (index) => Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0));
    var delayProcess = [0, double.infinity, -1];

    List<num> currentProcess = delayProcess;
    num currentWork = 0;
    Queue<List<num>> backlog = new Queue();
    Queue<List<num>> queue = new Queue();
    while (true) {
      if (count <= processes.length - 1) {
        while (processes[count][0] <= totalTime) {
          log.write("\nQueueing process P${count + 1} ${processes[count]} at time $totalTime");
          processes[count].add(count);
          queue.add(processes[count]);
          count++;
          if (count > processes.length - 1) break;
        }
      }

      if (currentProcess[1] == 0 || currentWork == n || (currentProcess[2] == -1 && (backlog.isNotEmpty || queue.isNotEmpty))) {
        if (currentWork != 0)
          resList.add(ProcessBar(totalTime - currentWork, totalTime, currentProcess[2] != -1 ? "P${currentProcess[2] + 1}" : "", currentProcess[2] != -1 ? colors[currentProcess[2]] : Colors.grey));
        log.write("\nStopping P${currentProcess[2] + 1}, saving work ($currentWork) in bar");
        if (currentProcess[1] != 0 && currentProcess[2] != -1) {
          log.write("\n   Backlogged P${currentProcess[2] + 1}");
          backlog.add(currentProcess);
        } else {
          log.write("\n   Finished P${currentProcess[2] + 1}");
        }

        currentWork = 0;
        if (queue.isNotEmpty) {
          log.write("\n   Starting P${queue.last[2] + 1} from queue $queue");
          currentProcess = queue.removeFirst();
        } else if (backlog.isNotEmpty) {
          log.write("\n   Starting P${backlog.last[2] + 1} from backlog $backlog");
          currentProcess = backlog.removeFirst();
        } else {
          if (count >= processes.length) break;
          log.write("\n   Queue, is empty, starting delay task");
          currentProcess = delayProcess;
        }
      }

      currentProcess[1]--;
      currentWork++;
      totalTime++;
      backlog.forEach((element) => totalWait++);
      queue.forEach((element) => totalWait++);
      log.write("\n#######P${currentProcess[2] + 1} $currentProcess, currentWork: $currentWork, time: $totalTime, totalWait: $totalWait, count $count, backlog: $backlog");
    }

    setState(() {
      resWidget = ResultContainer(totalWait / processes.length, resList, log);
    });
  }

  void TL_FCFS(List<List<num>> processes) {
    StringBuffer log = new StringBuffer("Starting TL_FCFS with $processes");
    num totalTime = 0;
    num count = 0;
    num totalWait = 0;
    List<ProcessBar> resList = new List();
    List<Color> colors = List.generate(processes.length, (index) => Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0));
    var delayProcess = [0, double.infinity, -1];

    List<num> currentProcess = delayProcess;
    num currentWork = 0;
    Queue<List<num>> hQueue = new Queue();
    Queue<List<num>> lQueue = new Queue();
    bool processingLow = false;
    while (true) {
      if (currentProcess[1] == 0) {
        resList.add(ProcessBar(totalTime - currentWork, totalTime, currentProcess[2] != -1 ? "P${currentProcess[2] + 1}" : "", currentProcess[2] != -1 ? colors[currentProcess[2]] : Colors.grey));
        log.write("\nFinished P${currentProcess[2] + 1}, saving work ($currentWork) in bar");
        currentWork = 0;
        if (hQueue.isNotEmpty) {
          processingLow = false;
          currentProcess = hQueue.removeLast();
          log.write("\n   Starting P${currentProcess[2] + 1} from high-priority queue");
        } else if (lQueue.isNotEmpty) {
          processingLow = true;
          currentProcess = lQueue.removeLast();
          log.write("\n   Starting P${currentProcess[2] + 1} from low-priority queue");
        } else {
          processingLow = true;
          log.write("\n   Starting delay task");
          currentProcess = delayProcess;
        }
      }

      if (count <= processes.length - 1) {
        while (processes[count][0] <= totalTime) {
          log.write("\nQueueing process P${count + 1} ${processes[count]} at time $totalTime");
          processes[count].add(count);
          if ((processes[count][1] <= 6 && processingLow) || currentProcess[2] == -1) {
            if (currentWork != 0) {
              resList
                  .add(ProcessBar(totalTime - currentWork, totalTime, currentProcess[2] != -1 ? "P${currentProcess[2] + 1}" : "", currentProcess[2] != -1 ? colors[currentProcess[2]] : Colors.grey));
            }
            log.write("\n   New process is higher priority than P${currentProcess[2] + 1}, saving work ($currentWork) in bar and starting P${count + 1}");
            currentWork = 0;

            if (currentProcess[2] != -1) {
              if (processingLow) {
                log.write("\n   Adding P${count + 1} back to low-priority queue");
                lQueue.add(currentProcess);
              } else {
                log.write("\n   Adding P${count + 1} back to high-priority queue");
                hQueue.add(currentProcess);
              }
            }

            currentProcess = processes[count];
          } else if (processes[count][1] <= 6) {
            log.write("\n   Adding P${count + 1} to high-priority queue");
            hQueue.add(processes[count]);
          } else {
            log.write("\n   Adding P${count + 1} to low-priority queue");
            lQueue.add(processes[count]);
          }
          count++;
          if (count > processes.length - 1) break;
        }
      }

      if (currentProcess[2] == -1 && count >= processes.length) {
        log.write("\nFinished TL_FCFS");
        break;
      }

      currentProcess[1]--;
      currentWork++;
      totalTime++;
      hQueue.forEach((element) => totalWait++);
      lQueue.forEach((element) => totalWait++);
      log.write("\n#######P${currentProcess[2] + 1} $currentProcess, currentWork: $currentWork, time: $totalTime, totalWait: $totalWait, count $count, hQueue: $hQueue, lQueue: $lQueue");
    }

    setState(() {
      resWidget = ResultContainer(totalWait / processes.length, resList, log);
    });
  }
}

class ResultContainer extends StatelessWidget {
  final double avgWait;
  final List<ProcessBar> list;
  final StringBuffer log;

  const ResultContainer(this.avgWait, this.list, this.log);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(50.0),
      child: Container(
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),color: Colors.grey[800],boxShadow: [BoxShadow(color:Colors.grey[900],blurRadius: 15)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Keskmine ooteaeg: ${avgWait.toStringAsFixed(2)}", style: GoogleFonts.sourceCodePro(),),
            SizedBox(
              height: 20,
            ),
            SizedBox(
              height: 50,
              child: Row(
                children: list,
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(0.0, 50, 0.0, 0.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
                color: Colors.grey[700],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  log.toString(),
                  style: GoogleFonts.sourceCodePro(),
                  maxLines: 50,
                ),
              ),
            ),
          ],
        ),
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
                style: GoogleFonts.sourceCodePro(
                  color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: -20,
              child: Text(end.toString(), style: GoogleFonts.sourceCodePro(),),
            ),
            Positioned(
              left: 0,
              bottom: -20,
              child: Text(start == 0 ? '0' : '', style: GoogleFonts.sourceCodePro(),),
            ),
          ],
        ),
      ),
    );
  }
}

class TableCellPadded extends StatelessWidget {
  final EdgeInsets padding;
  final Widget child;
  final TableCellVerticalAlignment verticalAlignment;

  const TableCellPadded({Key key, this.padding, @required this.child, this.verticalAlignment}) : super(key: key);

  @override
  TableCell build(BuildContext context) => TableCell(verticalAlignment: verticalAlignment, child: Padding(padding: padding ?? EdgeInsets.all(5.0), child: child));
}
