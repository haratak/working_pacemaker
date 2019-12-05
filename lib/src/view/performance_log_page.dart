import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:working_pacemaker/src/localization/localization.dart';
import 'package:working_pacemaker/src/subject/performance_log_page_subject.dart';
import 'package:working_pacemaker/src/view/performance_log_page/charts.dart';

class PerformanceLogPage extends StatelessWidget {
  Widget build(BuildContext context) {
    final subject = Provider.of<PerformanceLogPageSubject>(context);

    return Scaffold(
      appBar: AppBar(title: Text(l(context).yourPerformance)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: CustomScrollView(
            slivers: [
              SliverFixedExtentList(
                delegate: SliverChildListDelegate([
                  Card(
                    child: StreamBuilder<ChartView>(
                      stream: subject.today,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return Container();

                        return PerformanceChartContent(
                          chartView: snapshot.data,
                        );
                      },
                    ),
                  ),
                  Card(
                    child: StreamBuilder<ChartView>(
                      stream: subject.lastSevenDays,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return Container();

                        return PerformanceChartContent(
                          chartView: snapshot.data,
                        );
                      },
                    ),
                  ),
                  Card(
                    child: StreamBuilder<ChartView>(
                      stream: subject.thisMonth,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return Container();

                        return PerformanceChartContent(
                          chartView: snapshot.data,
                        );
                      },
                    ),
                  ),
                ]),
                itemExtent: 280,
              ),
              StreamBuilder<UnmodifiableListView<ChartView>>(
                stream: subject.listOfRest,
                initialData: UnmodifiableListView([]),
                builder: (context, snapshot) {
                  final listItems = snapshot.data
                      .map(
                        (chartView) => Card(
                          child: PerformanceChartContent(
                            chartView: chartView,
                          ),
                        ),
                      )
                      .toList();
                  return SliverFixedExtentList(
                    delegate: SliverChildListDelegate(listItems),
                    itemExtent: 280,
                  );
                },
              ),
              StreamBuilder<bool>(
                stream: subject.showViewAllLogsButton,
                initialData: false,
                builder: (context, snapshot) {
                  final items = <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(l(context).logKeepingInformation,
                            style: Theme.of(context).textTheme.caption),
                      ],
                    ),
                  ];

                  if (snapshot.data) {
                    items.add(
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: RaisedButton.icon(
                            icon: Icon(Icons.date_range),
                            label: Text(l(context).showAllLogs),
                            onPressed: () =>
                                subject.showAllLogsButtonPressed.add(null),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(children: items),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
