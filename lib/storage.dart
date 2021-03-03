import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'main.dart';

enum StorageAlgo { Run }

enum StorageOperationType { CREATE, ADD, DELETE }

const int DRIVE_SIZE = 48;

String getStorageData(DataChoice? valik) {
  switch (valik) {
    case DataChoice.First:
      return "A,2;B,3;A,-;C,4;B,+3;D,5;E,15;C,-;F,5";
    case DataChoice.Second:
      return "A,4;B,3;C,6;D,5;C,+2;B,-;E,5;A,-;F,10";
    case DataChoice.Third:
      return "A,2;B,3;C,4;D,5;B,-;E,7;D,-;E,+3;F,10";
    default:
      return "";
  }
}

Widget runStorageAlgo(StringBuffer log, List<StorageOperation> operations) {
  log.writeln('Started storage algo\n');
  int step = 0;
  HardDrive drive = HardDrive(log);
  List<TableRow> resultList = [];
  for (var operation in operations) {
    step++;
    log.writeln('Step $step:');
    if (operation.operationType == StorageOperationType.DELETE) {
      drive.deleteFile(operation.fileName);
    } else {
      if (!drive.addFile(operation.fileName, operation.size)) {
        resultList.add(rowFromDrive(drive, step, true, true));
        log.writeln('\nStorage algo failed!');
        return resultFromList(resultList);
      }
    }
    resultList.add(rowFromDrive(drive, step, false, false));
  }
  resultList.add(rowFromDrive(drive, step, true, false));
  var frags = drive.fragmentedFiles();
  log.writeln('\nStorage algo completed successfully!');
  return Column(
    children: [
      resultFromList(resultList),
      Text('Fragmented files: ${(frags[0] * 100).toStringAsFixed(2)}%'),
      Text('Fragmented area: ${(frags[1] * 100).toStringAsFixed(2)}%'),
    ],
  );
}

class HardDrive {
  final List<String?> blocks = List.generate(DRIVE_SIZE, (index) => '');
  final StringBuffer log;

  HardDrive(this.log);

  bool addFile(String? fileName, num size) {
    if (size > DRIVE_SIZE) {
      log.writeln('Attempted to add file ($size) larger than the total drive size ($DRIVE_SIZE)!');
      return false;
    }
    log.writeln('Allocating $size blocks to $fileName');
    num block = 0;
    for (int i = 1; i <= size; i++) {
      while (blocks[block as int] != '') {
        log.write(blocks[block]);
        block++;
        if (block >= blocks.length) {
          log.writeln('\nCould not allocate any more blocks (wrote $i/$size)!');
          return false;
        }
      }
      blocks[block] = fileName;
      block++;
      if (block >= blocks.length) {
        log.writeln('\nCould not allocate any more blocks (wrote $i/$size)!');
        return false;
      }
      log.write('[$fileName]');
    }
    log.write('\n\n');
    return true;
  }

  void deleteFile(String? fileName) {
    log.writeln('Deleting $fileName');
    for (int i = 0; i < blocks.length; i++) {
      if (blocks[i] == fileName) {
        log.write('($fileName)');
        blocks[i] = '';
      } else {
        log.write('${blocks[i] == '' ? ' ' : blocks[i]}');
      }
    }
    log.write('\n\n');
  }

  List<num> fragmentedFiles() {
    List<String?> files = [];
    List<num> sizes = [];
    List<bool> fragmented = [];
    String? last = blocks[0];
    for (int i = 0; i < blocks.length; i++) {
      if (blocks[i] == '') {
        last = blocks[i];
        continue;
      }
      int fileIndex = files.indexOf(blocks[i]);
      if (fileIndex == -1) {
        files.add(blocks[i]);
        sizes.add(1);
        fragmented.add(false);
      } else {
        if (last != blocks[i]) {
          fragmented[fileIndex] = true;
        }
        sizes[fileIndex] += 1;
      }
      last = blocks[i];
    }
    int fragmentedCount = 0;
    int fragmentedSize = 0;
    for (int i = 0; i < files.length; i++) {
      log.writeln('${files[i]} size: ${sizes[i]}${fragmented[i] ? ', fragmented' : ''}');
      if (fragmented[i]) {
        fragmentedCount++;
        fragmentedSize += sizes[i] as int;
      }
    }
    var result = [fragmentedCount / files.length, fragmentedSize / sizes.reduce((value, element) => value + element)];
    log.writeln('Fragmented files: ${(result[0] * 100).toStringAsFixed(2)}%');
    log.writeln('Fragmented area compared to total used area: ${(result[1] * 100).toStringAsFixed(2)}%');
    return [fragmentedCount / files.length, fragmentedSize / sizes.reduce((value, element) => value + element)];
  }
}

class StorageOperation {
  String? fileName;
  StorageOperationType? operationType;
  late num size;

  StorageOperation(String input) {
    var split = input.split(',');
    fileName = split[0];
    if (split[1] == '-') {
      operationType = StorageOperationType.DELETE;
    } else if (RegExp(r'^\+[0-9]+$').hasMatch(split[1])) {
      operationType = StorageOperationType.ADD;
      size = int.parse(split[1].replaceAll('+', ''));
    } else if (RegExp(r'^[0-9]+$').hasMatch(split[1])) {
      operationType = StorageOperationType.CREATE;
      size = int.parse(split[1]);
    } else {
      throw Exception('Invalid operation format');
    }
  }
}

class StorageResult extends StatelessWidget {
  final List<TableRow> list;
  const StorageResult(this.list);

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Table(
        children: list,
        columnWidths: {
          0: FixedColumnWidth(50),
        },
      ),
    );
  }
}

StorageResult resultFromList(List<TableRow> list) {
  List<TableCell> headerCellList = List.generate(
    DRIVE_SIZE,
    (index) => TableCell(
      verticalAlignment: TableCellVerticalAlignment.bottom,
      child: Container(
        alignment: Alignment.bottomCenter,
        child: Text(
          (index + 1).toString(),
          maxLines: 1,
          overflow: TextOverflow.fade,
        ),
      ),
    ),
  );
  headerCellList.insert(
    0,
    TableCell(
      child: Container(),
    ),
  );
  list.insert(0, TableRow(children: headerCellList));
  return StorageResult(list);
}

TableRow rowFromDrive(HardDrive drive, int step, bool finalRow, bool failed) {
  Color? freeColor = Colors.grey[600];
  if (finalRow) {
    if (failed) {
      freeColor = Colors.red;
    } else {
      freeColor = Colors.green;
    }
  }
  List<TableCell> cellList = List.generate(
    DRIVE_SIZE,
    (index) {
      var color = freeColor;
      if (!finalRow) {
        if (drive.blocks[index] != '') {
          color = color = Color((Random(drive.blocks[index].hashCode).nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
        }
      }
      return TableCell(
        child: Container(
          color: color,
          alignment: Alignment.center,
          child: Text(finalRow ? "" : drive.blocks[index]!),
        ),
      );
    },
  );
  cellList.insert(
    0,
    TableCell(
      child: Container(
        alignment: Alignment.centerRight,
        child: Text(
          finalRow
              ? failed
                  ? 'Fail'
                  : 'Done'
              : 'Step $step',
        ),
      ),
    ),
  );
  return TableRow(children: cellList, decoration: BoxDecoration(color: finalRow ? freeColor : Colors.transparent));
}
