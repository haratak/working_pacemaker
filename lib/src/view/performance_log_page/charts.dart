import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:working_pacemaker/src/subject/performance_log_page_subject.dart';

class PerformanceChartContent extends StatelessWidget {
  final ChartView _chartView;

  PerformanceChartContent({
    Key key,
    @required ChartView chartView,
  })  : assert(chartView != null),
        _chartView = chartView,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_chartView.duration}',
                    style: theme.textTheme.subhead
                        .copyWith(color: theme.accentColor)),
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 20),
                  child: Text(
                    '${_chartView.totalWorkingTime}',
                    style: theme.textTheme.headline.copyWith(
                        fontSize: 36,
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                ),
              ],
            ),
          ),
          // Delay this chart rendering, so that page loading animation can
          // take precedence and would be smoothly rendered.
          FutureBuilder<bool>(
            future:
                Future.delayed(const Duration(milliseconds: 50), () => true),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Container();
              return Expanded(
                child: PerformanceChart(_chartView.dataSet),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PerformanceChart extends StatelessWidget {
  final List<charts.Series<ChartData, DateTime>> _seriesList;

  factory PerformanceChart(List<ChartData> data) {
    return PerformanceChart._(_createData(data));
  }

  PerformanceChart._(this._seriesList);

  @override
  Widget build(BuildContext context) {
    return charts.TimeSeriesChart(
      _seriesList,
      domainAxis: const charts.DateTimeAxisSpec(
        tickFormatterSpec: charts.AutoDateTimeTickFormatterSpec(
          hour: charts.TimeFormatterSpec(
            format: 'h',
            transitionFormat: 'h',
          ),
          day: charts.TimeFormatterSpec(
            format: 'd',
            transitionFormat: 'd',
          ),
        ),
      ),
      animate: false,
      defaultRenderer: charts.BarRendererConfig<DateTime>(),
      defaultInteractions: false,
      behaviors: [charts.SelectNearest(), charts.DomainHighlighter()],
    );
  }

  static List<charts.Series<ChartData, DateTime>> _createData(
      List<ChartData> dataSet) {
    return [
      charts.Series<ChartData, DateTime>(
        id: 'PerformanceLog',
        colorFn: (_, __) => charts.MaterialPalette.indigo.shadeDefault,
        domainFn: (data, _) => data.time,
        measureFn: (data, _) => data.y,
        data: dataSet,
      )
    ];
  }
}
