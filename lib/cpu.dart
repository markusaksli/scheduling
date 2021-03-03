import 'dart:collection';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'main.dart';

enum CpuAlgo { FCFS, SJF, RR, TL_FCFS }

const int RR_WINDOW = 3;

String getCpuData(DataChoice? valik) {
  switch (valik) {
    case DataChoice.First:
      return "0,5;6,9;6,5;15,10";
    case DataChoice.Second:
      return "0,2;0,4;12,4;15,5;21,10";
    case DataChoice.Third:
      return "5,6;6,9;11,3;12,7";
    default:
      return "";
  }
}

Widget runCpuAlgo(CpuAlgo algo, StringBuffer log, List<List<num>> processes) {
  switch (algo) {
    case CpuAlgo.FCFS:
      return FCFS(processes, log);
    case CpuAlgo.SJF:
      return SJF(processes, log);
    case CpuAlgo.RR:
      return RR(processes, log, RR_WINDOW);
    case CpuAlgo.TL_FCFS:
      return TL_FCFS(processes, log);
  }
}

Widget FCFS(List<List<num>> processes, StringBuffer log) {
  log.write("Starting First Come First Serve with $processes");
  num totalTime = 0;
  num count = 1;
  num totalWait = 0;
  List<CpuProcessBar> resList = [];
  for (var process in processes) {
    if (process[0] > totalTime) {
      int time = process[0] - totalTime as int;
      log.write("\nWaiting for $time");
      resList.add(new CpuProcessBar(totalTime as int, totalTime + time, "", Colors.grey));
      totalTime += time;
    }
    //TODO: Add generated colors here as well
    var color = Colors.green;
    if (process[0] < totalTime) {
      log.write("\nP$count is waiting for ${totalTime - process[0]}");
      totalWait += totalTime - process[0];
      color = Colors.orange;
    }
    log.write("\nRunning P$count");
    resList.add(CpuProcessBar(totalTime as int, totalTime + (process[1] as int), "P$count", color));
    totalTime += process[1] as int;
    count += 1;
  }

  log.write("\nFinished FCFS");
  return CpuResult(totalWait / processes.length, resList);
}

Widget SJF(List<List<num>> processes, StringBuffer log) {
  log.write("Starting Shortest Job First with $processes");
  num totalTime = 0;
  num count = 0;
  num totalWait = 0;
  List<CpuProcessBar> resList = [];
  List<Color> colors = List.generate(processes.length, (index) => Color((Random(index).nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0));
  var delayProcess = [0, double.infinity, -1];

  List<num> currentProcess = delayProcess;
  num currentWork = 0;
  Queue<List<num>> backlog = new Queue();
  while (true) {
    if (currentProcess[1] == 0) {
      resList.add(CpuProcessBar(totalTime - currentWork as int, totalTime as int, currentProcess[2] != -1 ? "P${currentProcess[2] + 1}" : "", currentProcess[2] != -1 ? colors[currentProcess[2] as int] : Colors.grey));
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
      while (processes[count as int][0] <= totalTime) {
        log.write("\nStarting process P${count + 1} ${processes[count]} at time $totalTime");
        processes[count].add(count);
        if (processes[count][1] < currentProcess[1]) {
          if (currentWork != 0) {
            resList
                .add(CpuProcessBar(totalTime - currentWork as int, totalTime as int, currentProcess[2] != -1 ? "P${currentProcess[2] + 1}" : "", currentProcess[2] != -1 ? colors[currentProcess[2] as int] : Colors.grey));
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

  return CpuResult(totalWait / processes.length, resList);
}

Widget RR(List<List<num>> processes, StringBuffer log, int n) {
  log.write("Starting Round Robin ($n) with $processes");
  num totalTime = 0;
  num count = 0;
  num totalWait = 0;
  List<CpuProcessBar> resList = [];
  List<Color> colors = List.generate(processes.length, (index) => Color((Random(index).nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0));
  var delayProcess = [0, double.infinity, -1];

  List<num> currentProcess = delayProcess;
  num currentWork = 0;
  Queue<List<num>> backlog = new Queue();
  Queue<List<num>> queue = new Queue();
  while (true) {
    if (count <= processes.length - 1) {
      while (processes[count as int][0] <= totalTime) {
        log.write("\nQueueing process P${count + 1} ${processes[count]} at time $totalTime");
        processes[count].add(count);
        queue.add(processes[count]);
        count++;
        if (count > processes.length - 1) break;
      }
    }

    if (currentProcess[1] == 0 || currentWork == n || (currentProcess[2] == -1 && (backlog.isNotEmpty || queue.isNotEmpty))) {
      if (currentWork != 0)
        resList.add(CpuProcessBar(totalTime - currentWork as int, totalTime as int, currentProcess[2] != -1 ? "P${currentProcess[2] + 1}" : "", currentProcess[2] != -1 ? colors[currentProcess[2] as int] : Colors.grey));
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
  log.write("\nFinished RR$n");
  return CpuResult(totalWait / processes.length, resList);
}

Widget TL_FCFS(List<List<num>> processes, StringBuffer log) {
  log.write("Starting Two-Layer First Come First Serve with $processes");
  num totalTime = 0;
  num count = 0;
  num totalWait = 0;
  List<CpuProcessBar> resList = [];
  List<Color> colors = List.generate(processes.length, (index) => Color((Random(index).nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0));
  var delayProcess = [0, double.infinity, -1];

  List<num> currentProcess = delayProcess;
  num currentWork = 0;
  Queue<List<num>> hQueue = new Queue();
  Queue<List<num>> lQueue = new Queue();
  bool processingLow = false;
  while (true) {
    if (currentProcess[1] == 0) {
      resList.add(CpuProcessBar(totalTime - currentWork as int, totalTime as int, currentProcess[2] != -1 ? "P${currentProcess[2] + 1}" : "", currentProcess[2] != -1 ? colors[currentProcess[2] as int] : Colors.grey));
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
      while (processes[count as int][0] <= totalTime) {
        log.write("\nQueueing process P${count + 1} ${processes[count]} at time $totalTime");
        processes[count].add(count);
        if ((processes[count][1] <= 6 && processingLow) || currentProcess[2] == -1) {
          if (currentWork != 0) {
            resList
                .add(CpuProcessBar(totalTime - currentWork as int, totalTime as int, currentProcess[2] != -1 ? "P${currentProcess[2] + 1}" : "", currentProcess[2] != -1 ? colors[currentProcess[2] as int] : Colors.grey));
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

  return CpuResult(totalWait / processes.length, resList);
}

class CpuResult extends StatelessWidget {
  final double avgWait;
  final List<CpuProcessBar> list;

  const CpuResult(this.avgWait, this.list);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Average wait: ${avgWait.toStringAsFixed(2)}",
          style: GoogleFonts.sourceCodePro(),
        ),
        SizedBox(
          height: 20,
        ),
        SizedBox(
          height: 50,
          child: Row(
            children: list,
          ),
        ),
      ],
    );
  }
}

class CpuProcessBar extends StatelessWidget {
  final int start;
  final int end;
  final String text;
  final Color color;

  const CpuProcessBar(this.start, this.end, this.text, this.color);

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
              child: Text(
                end.toString(),
                style: GoogleFonts.sourceCodePro(),
              ),
            ),
            Positioned(
              left: 0,
              bottom: -20,
              child: Text(
                start == 0 ? '0' : '',
                style: GoogleFonts.sourceCodePro(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
