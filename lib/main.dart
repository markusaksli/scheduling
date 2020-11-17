import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scheduling/cpu.dart';

void main() => runApp(AlgoApp());

enum DataChoice { First, Second, Third, Own }
enum Component { CPU, Memory }

class AlgoApp extends StatefulWidget {
  @override
  _AlgoAppState createState() => _AlgoAppState();
}

class _AlgoAppState extends State<AlgoApp> {
  DataChoice dataChoice = DataChoice.First;
  Component component = Component.CPU;
  TextEditingController _controller;
  List<bool> selectedAlgo = List.generate(4, (index) => false);
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
      title: 'Resource management',
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
          title: const Text('Resource management'),
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
                                      List<List<num>> processes;
                                      if (choiceText.isEmpty && dataChoice == DataChoice.Own) {
                                        return const TableErrorContainer(
                                          text: "Enter a process array",
                                        );
                                      }
                                      try {
                                        processes = cleanInput();
                                        processes[processes.length - 1][1];
                                      } catch (e) {
                                        return const TableErrorContainer(
                                          text: "Faulty process array",
                                        );
                                      }
                                      return ProcessTable(processes: processes);
                                    },
                                  ),
                                ),
                              ],
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
                    resWidget,
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
    List algoEnum;
    switch (component) {
      case Component.CPU:
        algoEnum = CpuAlgo.values;
        break;
      case Component.Memory:
        // TODO: Handle this case.
        break;
    }
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
          width: (constraints.maxWidth - 100) / algoEnum.length,
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
        title: Text(index != 3 ? getData(DataChoice.values[index]) : ""),
        value: DataChoice.values[index],
        activeColor: Colors.orangeAccent,
        groupValue: dataChoice,
        onChanged: (DataChoice value) {
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
            hintText: "Enter a process array such as 1,10;4,2;12,3;13,2",
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
        onChanged: (Component value) {
          setState(() {
            component = value;
            for (int i = 0; i < selectedAlgo.length; i++) if (selectedAlgo[i]) runAlgo(i);
          });
        },
      ),
    );
    return componentList;
  }

  String getData(DataChoice valik) {
    switch (valik) {
      case DataChoice.First:
        return "0,5;6,9;6,5;15,10";
      case DataChoice.Second:
        return "0,2;0,4;12,4;15,5;21,10";
      case DataChoice.Third:
        return "5,6;6,9;11,3;12,7";
      case DataChoice.Own:
        return choiceText;
      default:
        return "";
    }
  }

  List<List<num>> cleanInput() {
    var rawInput = getData(dataChoice).split(";");
    return List.generate(rawInput.length, (i) {
      var str = rawInput[i].split(",");
      return [int.parse(str[0]), int.parse(str[1])];
    });
  }

  void runAlgo(int algoIndex) {
    try {
      StringBuffer log = new StringBuffer();
      Widget algoResult;
      switch (component) {
        case Component.CPU:
          algoResult = runCpuAlgo(CpuAlgo.values[algoIndex], log, cleanInput());
          break;
        case Component.Memory:
          // TODO: Handle this case.
          break;
      }
      setState(() {
        resWidget = AlgoResult(algoResult, log);
        error = false;
        for (int i = 0; i < selectedAlgo.length; i++) {
          selectedAlgo[i] = i == algoIndex;
        }
      });
    } catch (e) {
      setState(() {
        error = true;
        resWidget = const Padding(
          padding: EdgeInsets.all(50.0),
        );
      });
    }
  }
}

class TableErrorContainer extends StatelessWidget {
  const TableErrorContainer({
    Key key,
    this.text,
  }) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[600],
      alignment: Alignment.center,
      child: Text(text),
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

class ProcessTable extends StatelessWidget {
  const ProcessTable({
    Key key,
    @required this.processes,
  }) : super(key: key);

  final List<List<num>> processes;
  static const TextStyle heading = TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.orangeAccent,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[600],
      child: Table(
        border: TableBorder.all(),
        children: List.generate((processes.length + 1), (index) {
          if (index == 0) {
            return const TableRow(
              children: [
                TableCellPadded(
                  child: Text(
                    "ID",
                    style: heading,
                  ),
                ),
                TableCellPadded(
                  child: Text(
                    "Arrival time",
                    style: heading,
                  ),
                ),
                TableCellPadded(
                  child: Text(
                    "Requested resource amount",
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
  }
}

class AlgoResult extends StatelessWidget {
  final Widget resultWidget;
  final StringBuffer log;

  const AlgoResult(this.resultWidget, this.log);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(50.0),
      child: Container(
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: Colors.grey[800], boxShadow: [BoxShadow(color: Colors.grey[900], blurRadius: 15)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            resultWidget,
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
