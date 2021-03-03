import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scheduling/cpu.dart';
import 'package:scheduling/memory.dart';
import 'package:scheduling/storage.dart';

void main() => runApp(AlgoApp());

enum DataChoice { First, Second, Third, Own }
enum Component { CPU, Memory, Storage }

class AlgoApp extends StatefulWidget {
  @override
  _AlgoAppState createState() => _AlgoAppState();
}

class _AlgoAppState extends State<AlgoApp> {
  DataChoice? dataChoice = DataChoice.First;
  Component? component = Component.CPU;
  TextEditingController? _controller;
  late List<bool> selectedAlgo;
  bool hasResult = false;
  bool error = false;
  String choiceText = "";

  Widget? resWidget;
  FocusNode focus = FocusNode();

  @override
  void initState() {
    setSelectedAlgoList();
    _controller = TextEditingController(text: choiceText);
    resWidget = Padding(padding: EdgeInsets.all(50.0));
    focus.addListener(() {
      if (focus.hasFocus) setState(() => dataChoice = DataChoice.Own);
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
    return MaterialApp(
      title: 'Resource Scheduling',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.orange,
        primaryColorDark: Colors.orange,
        accentColor: Colors.orangeAccent,
        highlightColor: Colors.orangeAccent,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: Colors.blue.withAlpha(0),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('${component.toString().split(".")[1]} Scheduling'),
        ),
        drawer: Drawer(
          child: ListView(
            children: generateComponentSelectionList(),
          ),
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
                            child: Column(children: generateDataInputList()),
                          ),
                          Flexible(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(0, 0, 20.0, 0),
                              child: Column(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      "Process table",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  Flexible(
                                    child: Builder(
                                      builder: (context) {
                                        List processes;
                                        if (choiceText.isEmpty && dataChoice == DataChoice.Own) {
                                          return const TableErrorContainer(
                                            text: "Enter a process array",
                                          );
                                        }
                                        try {
                                          if (component == Component.Storage) {
                                            processes = parseStorageOperations();
                                          } else {
                                            processes = parseComputationProcesses();
                                            processes[processes.length - 1][1];
                                          }
                                        } catch (e) {
                                          return const TableErrorContainer(
                                            text: "Faulty process array",
                                          );
                                        }
                                        switch (component) {
                                          case Component.CPU:
                                            return ProcessTable.fromProcessList(processes as List<List<num>>, "Arrival time", "Length", (int index) => "P${index + 1}");
                                          case Component.Memory:
                                            return ProcessTable.fromProcessList(processes as List<List<num>>, "Amount of memory", "Length", (int index) => MemoryProcess.generateName(index));
                                          case Component.Storage:
                                            return ProcessTable.fromStorageList(processes as List<StorageOperation>);
                                          default:
                                            return TableErrorContainer(
                                              text: "No component selected",
                                            );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) => buildAlgoToggle(constraints),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    resWidget!,
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ToggleButtons buildAlgoToggle(BoxConstraints constraints) {
    List algoEnum = getComponentAlgoEnum()!;
    return ToggleButtons(
      selectedColor: Colors.orange,
      selectedBorderColor: Colors.orange[200],
      fillColor: Colors.grey[700],
      splashColor: Colors.orangeAccent,
      isSelected: selectedAlgo,
      borderRadius: BorderRadius.circular(10),
      onPressed: (int index) {
        if (selectedAlgo[index]) {
          setState(() {
            selectedAlgo[index] = false;
            error = false;
            resWidget = Padding(padding: EdgeInsets.all(50.0));
          });
        } else {
          runAlgo(index);
        }
      },
      children: List.generate(
        algoEnum.length,
        (index) => Container(
          width: (constraints.maxWidth - 40) / algoEnum.length,
          alignment: Alignment.center,
          child: Text(
            algoEnum[index].toString().split(".")[1],
            style: GoogleFonts.sourceCodePro(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  List<Widget> generateDataInputList() {
    List<Widget> inputList = List.generate(
      DataChoice.values.length,
      (index) => RadioListTile<DataChoice>(
        title: Text(index != 3 ? getData(DataChoice.values[index]) : "Create your own"),
        value: DataChoice.values[index],
        activeColor: Colors.orangeAccent,
        groupValue: dataChoice,
        onChanged: (DataChoice? value) {
          setState(() {
            dataChoice = value;
            if (value != DataChoice.Own) {
              focus.unfocus();
              error = false;
            } else {
              focus.requestFocus();
            }
            for (int i = 0; i < selectedAlgo.length; i++) if (selectedAlgo[i]) runAlgo(i);
          });
        },
      ),
    );
    inputList.add(Flexible(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
        child: TextField(
          cursorColor: Colors.orangeAccent,
          focusNode: focus,
          controller: _controller,
          decoration: InputDecoration(
            hintText: "Enter your own process array",
            errorText: error ? "Faulty process array" : null,
          ),
          onChanged: (s) {
            setState(() {
              choiceText = s;
              for (int i = 0; i < selectedAlgo.length; i++) if (selectedAlgo[i]) runAlgo(i);
            });
          },
        ),
      ),
    ));
    inputList.insert(
        0,
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Choose a process array",
            style: TextStyle(fontSize: 18),
          ),
        ));
    return inputList;
  }

  List<Widget> generateComponentSelectionList() {
    List<Widget> componentList = List.generate(
      Component.values.length,
      (index) => RadioListTile<Component>(
        title: Text(Component.values[index].toString().split(".")[1]),
        value: Component.values[index],
        activeColor: Colors.orangeAccent,
        groupValue: component,
        onChanged: (Component? value) {
          setState(() {
            component = value;
            resWidget = Padding(
              padding: EdgeInsets.all(50.0),
            );
            setSelectedAlgoList();
          });
        },
      ),
    );
    componentList.insert(
      0,
      DrawerHeader(
        decoration: BoxDecoration(color: Colors.orange),
        child: Text(
          "Select a component",
          style: TextStyle(fontSize: 24, color: Colors.black),
        ),
      ),
    );
    return componentList;
  }

  List? getComponentAlgoEnum() {
    List? algoEnum;
    switch (component) {
      case Component.CPU:
        algoEnum = CpuAlgo.values;
        break;
      case Component.Memory:
        algoEnum = MemoryAlgo.values;
        break;
      case Component.Storage:
        algoEnum = StorageAlgo.values;
        break;
    }
    return algoEnum;
  }

  void setSelectedAlgoList() {
    setState(() {
      selectedAlgo = List.generate(getComponentAlgoEnum()!.length, (index) => false);
    });
  }

  String getData(DataChoice? choice) {
    if (choice == DataChoice.Own) {
      return choiceText;
    }
    switch (component) {
      case Component.CPU:
        return getCpuData(choice);
      case Component.Memory:
        return getMemoryData(choice);
      case Component.Storage:
        return getStorageData(choice);
      default:
        return "";
    }
  }

  List<List<num>> parseComputationProcesses() {
    var rawInput = getData(dataChoice).split(";");
    return List.generate(rawInput.length, (i) {
      var str = rawInput[i].split(",");
      return [int.parse(str[0]), int.parse(str[1])];
    });
  }

  List<StorageOperation> parseStorageOperations() {
    var rawInput = getData(dataChoice).split(';');
    return List.generate(rawInput.length, (index) => StorageOperation(rawInput[index]));
  }

  void runAlgo(int algoIndex) {
    StringBuffer log = new StringBuffer();
    log.writeln("Parsing input");
    try {
      Widget? algoResult;
      switch (component) {
        case Component.CPU:
          algoResult = runCpuAlgo(CpuAlgo.values[algoIndex], log, parseComputationProcesses());
          break;
        case Component.Memory:
          algoResult = runMemoryAlgo(MemoryAlgo.values[algoIndex], log, parseComputationProcesses());
          break;
        case Component.Storage:
          algoResult = runStorageAlgo(log, parseStorageOperations());
          break;
      }
      setState(() {
        resWidget = AlgoResult(algoResult, log);
        error = false;
        for (int i = 0; i < selectedAlgo.length; i++) {
          selectedAlgo[i] = i == algoIndex;
        }
      });
    } catch (e, s) {
      setState(() {
        print("$e\n$s");
        error = true;
        resWidget = AlgoResult(Container(), log);
      });
    }
  }
}

class TableErrorContainer extends StatelessWidget {
  const TableErrorContainer({
    Key? key,
    this.text,
  }) : super(key: key);

  final String? text;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[600],
      alignment: Alignment.center,
      child: Text(text!),
    );
  }
}

class TableCellPadded extends StatelessWidget {
  final EdgeInsets? padding;
  final Widget child;
  final TableCellVerticalAlignment? verticalAlignment;

  const TableCellPadded({Key? key, this.padding, required this.child, this.verticalAlignment}) : super(key: key);

  @override
  TableCell build(BuildContext context) => TableCell(verticalAlignment: verticalAlignment, child: Padding(padding: padding ?? EdgeInsets.all(5.0), child: child));
}

class ProcessTable extends StatelessWidget {
  final List<TableRow> rows;
  static const TextStyle heading = TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.orangeAccent,
  );

  static ProcessTable fromProcessList(List<List<num>> processes, String firstProperty, String secondProperty, Function generateID) {
    List<TableRow> rowList = List.generate(
      processes.length,
      (index) {
        List<TableCellPadded> cellList = List.generate(processes[index].length, (secondIndex) => TableCellPadded(child: Text(processes[index][secondIndex].toString())));
        cellList.insert(0, TableCellPadded(child: Text(generateID(index))));
        return TableRow(
          children: cellList,
        );
      },
    );
    rowList.insert(
        0,
        TableRow(
          children: [
            const TableCellPadded(
              child: Text(
                "ID",
                style: heading,
              ),
            ),
            TableCellPadded(
              child: Text(
                firstProperty,
                style: heading,
              ),
            ),
            TableCellPadded(
              child: Text(
                secondProperty,
                style: heading,
              ),
            ),
          ],
        ));
    return ProcessTable(rows: rowList);
  }

  static ProcessTable fromStorageList(List<StorageOperation> operations) {
    List<TableRow> rowList = List.generate(
      operations.length,
      (index) {
        var operation = operations[index];
        List<TableCellPadded> cellList = [
          TableCellPadded(child: Text((index + 1).toString())),
          TableCellPadded(child: Text(operation.operationType.toString().split('.')[1])),
          TableCellPadded(child: Text(operation.fileName!)),
        ];
        if (operation.operationType == StorageOperationType.DELETE) {
          cellList.add(const TableCellPadded(child: Text('Entire file')));
        } else {
          cellList.add(TableCellPadded(child: Text(operation.size.toString())));
        }
        return TableRow(
          children: cellList,
        );
      },
    );
    rowList.insert(
        0,
        TableRow(
          children: [
            const TableCellPadded(
              child: Text(
                'Step',
                style: heading,
              ),
            ),
            const TableCellPadded(
              child: Text(
                'Operation',
                style: heading,
              ),
            ),
            const TableCellPadded(
              child: Text(
                "Filename",
                style: heading,
              ),
            ),
            const TableCellPadded(
              child: Text(
                'Size',
                style: heading,
              ),
            ),
          ],
        ));
    return ProcessTable(rows: rowList);
  }

  const ProcessTable({
    Key? key,
    required this.rows,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[600],
      child: Table(
        border: TableBorder.all(),
        children: rows,
      ),
    );
  }
}

class AlgoResult extends StatelessWidget {
  final Widget? resultWidget;
  final StringBuffer log;

  const AlgoResult(this.resultWidget, this.log);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: Colors.grey[800], boxShadow: [BoxShadow(color: Colors.grey[900]!, blurRadius: 15)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            resultWidget!,
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
