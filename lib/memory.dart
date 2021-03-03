import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'main.dart';

enum MemoryAlgo { First_Fit, Last_Fit, Best_Fit, Worst_Fit, Random_Fit }

const int MEMORY_SIZE = 50;

String getMemoryData(DataChoice? valik) {
  switch (valik) {
    case DataChoice.First:
      return "1,8;35,4;3,6;4,2;1,4;3,3;1,2;5,1;50,1";
    case DataChoice.Second:
      return "1,8;7,4;10,6;25,2;1,4;13,3;6,2;8,1;50,1";
    case DataChoice.Third:
      return "1,10;6,6;3,7;2,4;1,6;5,2;1,4;5,2;3,1";
    default:
      return "";
  }
}

Widget runMemoryAlgo(MemoryAlgo algo, StringBuffer log, List<List<num>> rawProcesses) {
  List<MemoryProcess> processes = [];
  for (int i = 0; i < rawProcesses.length; i++) {
    processes.add(MemoryProcess(rawProcesses[i], MemoryProcess.generateName(i)));
  }
  var memory = new Memory(log);
  switch (algo) {
    case MemoryAlgo.First_Fit:
      return memoryFit(processes: processes, memory: memory, log: log);
    case MemoryAlgo.Last_Fit:
      return memoryFit(processes: processes, memory: memory, log: log, reverseChunkPriority: true);
    case MemoryAlgo.Best_Fit:
      return memoryFit(processes: processes, memory: memory, log: log, sortByChunkSize: true);
    case MemoryAlgo.Worst_Fit:
      return memoryFit(processes: processes, memory: memory, log: log, reverseChunkPriority: true, sortByChunkSize: true);
    case MemoryAlgo.Random_Fit:
      return memoryFit(processes: processes, memory: memory, log: log, random: true);
  }
}

class MemoryProcess {
  static int charA = 'A'.codeUnitAt(0);
  late String name;
  Color? color;
  late num size;
  late num time;
  num? regStart;
  num? regEnd;

  MemoryProcess(List<num> request, String name) {
    this.name = name;
    size = request[0];
    time = request[1];
    //TODO: look at making this consistent
    color = Color((Random(name.hashCode).nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
  }

  void setReg(regStart, regEnd) {
    this.regStart = regStart;
    this.regEnd = regEnd;
  }

  static String generateName(int index) {
    return String.fromCharCode(charA + index);
  }

  @override
  String toString() {
    return "$name: $size,$time";
  }
}

class Memory {
  final List<bool> regs = List.generate(MEMORY_SIZE, (index) => true);
  final StringBuffer log;
  num time = 1;
  List<MemoryProcess> processes = [];

  Memory(this.log);

  List<List<num>> getFreeChunks() {
    List<List<num>> chunks = [];
    for (var i = 0; i < regs.length; i++) {
      if (regs[i]) {
        List<num> chunk = [i];
        while (i + 1 < regs.length) {
          if (!regs[i + 1]) break;
          i++;
        }
        chunk.add(i);
        chunks.add(chunk);
      }
    }
    return chunks;
  }

  void addProcess(MemoryProcess process) {
    assert(process.regStart != null && process.regEnd != null);
    processes.add(process);
    for (var i = process.regStart!; i <= process.regEnd!; i++) regs[i as int] = false;
  }

  void tick() {
    log.write("\n######$time - $processes");
    List<MemoryProcess> removeList = [];
    for (var process in processes) {
      process.time--;
      if (process.time == 0) {
        for (var i = process.regStart!; i <= process.regEnd!; i++) regs[i as int] = true;
        removeList.add(process);
      }
    }
    for (var process in removeList) {
      processes.remove(process);
      log.write("\n######Process $process finished");
    }
    time++;
  }

  bool isEmpty() {
    return processes.isEmpty;
  }
}

Widget memoryFit({required List<MemoryProcess> processes, required Memory memory, required StringBuffer log, bool reverseChunkPriority = false, bool sortByChunkSize = false, bool random = false}) {
  log.write("Starting ${random ? "random-fit" : sortByChunkSize ? reverseChunkPriority ? "worst-fit" : "best-fit" : reverseChunkPriority ? "last-fit" : "first-fit"} with $processes");
  List<TableRow> resultList = [];
  for (var process in processes) {
    var chunks = memory.getFreeChunks();
    if (sortByChunkSize & chunks.isNotEmpty) {
      chunks.sort((List<num> a, List<num> b) {
        num compare = (a[1] - a[0]).compareTo(b[1] - b[0]);
        if (reverseChunkPriority) {
          compare *= -1;
        }
        if (compare == 0) {
            compare = a[0].compareTo(b[0]);
        }
        return compare as int;
      });
    }
    if(!sortByChunkSize && reverseChunkPriority){
      chunks = chunks.reversed.toList();
    }
    log.write("\nTrying to add process $process to free chunks $chunks");
    bool added = false;
    for (var chunk in chunks) {
      if (random) {
        chunk = chunks[Random().nextInt(chunks.length)];
      }
      if (chunk[1] - chunk[0] >= process.size - 1) {
        process.setReg(chunk[0], chunk[0] + process.size - 1);
        log.write("\n   Added process $process to range [${process.regStart}, ${process.regEnd}]");
        memory.addProcess(process);
        added = true;
        resultList.add(rowFromMemory(memory, process.toString(), false, false));
        memory.tick();
        break;
      }
    }
    if (!added) {
      log.write("\n!---Could not add process $process---!");
      resultList.add(rowFromMemory(memory, process.toString(), true, true));
      log.write("\nFailed to complete ${random ? "random-fit" : sortByChunkSize ? reverseChunkPriority ? "worst-fit" : "best-fit" : reverseChunkPriority ? "last-fit" : "first-fit"}");
      return resultFromList(resultList);
    }
  }
  while (!memory.isEmpty()) {
    resultList.add(rowFromMemory(memory, "-", false, false));
    memory.tick();
  }
  resultList.add(rowFromMemory(memory, "-", true, false));
  log.write("\nFinished ${random ? "random-fit" : sortByChunkSize ? reverseChunkPriority ? "worst-fit" : "best-fit" : reverseChunkPriority ? "last-fit" : "first-fit"} successfully");
  return resultFromList(resultList);
}

class MemoryResult extends StatelessWidget {
  final List<TableRow> list;

  const MemoryResult(this.list);

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Table(
        children: list,
        columnWidths: {
          0: FixedColumnWidth(MEMORY_SIZE.toDouble()),
          1: IntrinsicColumnWidth(),
        },
      ),
    );
  }
}

MemoryResult resultFromList(List<TableRow> list) {
  List<TableCell> headerCellList = List.generate(
    MEMORY_SIZE,
    (index) => TableCell(
      verticalAlignment: TableCellVerticalAlignment.bottom,
      child: Container(
        alignment: Alignment.bottomCenter,
        child: Text(
          index.toString(),
          maxLines: 1,
          overflow: TextOverflow.fade,
        ),
      ),
    ),
  );
  headerCellList.insertAll(
    0,
    [
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.bottom,
        child: Container(
          alignment: Alignment.centerLeft,
          child: Text(
            "Time",
            style: TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.fade,
          ),
        ),
      ),
      TableCell(
        child: Container(
          alignment: Alignment.center,
          child: Text(
            "Added\nprocess",
            style: TextStyle(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.fade,
          ),
        ),
      ),
    ],
  );
  list.insert(0, TableRow(children: headerCellList));
  return MemoryResult(list);
}

TableRow rowFromMemory(Memory memory, String addedProcess, bool finalRow, bool failed) {
  Color? freeColor = Colors.grey[600];
  if (finalRow) {
    if (failed) {
      freeColor = Colors.red;
    } else {
      freeColor = Colors.green;
    }
  }
  List<TableCell> cellList = List.generate(
    MEMORY_SIZE,
    (index) => TableCell(
      child: Container(
        color: freeColor,
        alignment: Alignment.center,
        child: Text(finalRow ? "" : "-"),
      ),
    ),
  );
  if (!finalRow) {
    for (var process in memory.processes) {
      List<TableCell> processCellList = List.generate(
        process.size as int,
        (index) => TableCell(
          child: Container(
            alignment: Alignment.center,
            color: process.color,
            child: Text(
              process.name,
              style: TextStyle(
                color: process.color!.computeLuminance() > 0.5 ? Colors.black : Colors.white,
              ),
            ),
          ),
        ),
      );
      cellList.replaceRange(process.regStart as int, process.regEnd! + 1 as int, processCellList);
    }
  }
  cellList.insertAll(
    0,
    [
      TableCell(
        child: Container(
          alignment: Alignment.centerLeft,
          child: Text(
            !failed && finalRow ? '' : memory.time.toString(),
          ),
        ),
      ),
      TableCell(
        child: Container(
          alignment: Alignment.center,
          child: Text(
            !failed && finalRow ? 'Done' : addedProcess,
            maxLines: 1,
            overflow: TextOverflow.fade,
          ),
        ),
      ),
    ],
  );
  return TableRow(children: cellList, decoration: BoxDecoration(color: finalRow ? freeColor : Colors.transparent));
}
