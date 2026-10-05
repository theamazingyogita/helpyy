import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/handwritten.dart';
import '../../widgets/screen_heading.dart';
import '../bloc/calls_bloc.dart';
import 'widgets/call_record_row.dart';

class CallsTab extends StatelessWidget {
  const CallsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CallsBloc(context.read())..add(const CallsStarted()),
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<CallsBloc, CallsState>(
          builder: (context, state) => ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              const ScreenHeading(eyebrow: 'Your escapes', title: 'Calls.'),
              const SizedBox(height: 20),
              const Divider(),
              ...switch (state.status) {
                CallsStatus.loading => const <Widget>[],
                CallsStatus.failed => const [
                  Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Text('Your call history could not be read.'),
                  ),
                ],
                CallsStatus.ready when state.records.isEmpty => const [
                  Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Handwritten(
                      'no escapes yet, lucky you',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                CallsStatus.ready => [
                  for (final record in state.records)
                    CallRecordRow(record: record),
                ],
              },
            ],
          ),
        ),
      ),
    );
  }
}
