import 'package:flutter/material.dart';
import 'package:replay_riverpod/replay_riverpod.dart';

void main() {
  runApp(ProviderScope(observers: [AppProviderObserver()], child: const App()));
}

/// Custom [ProviderObserver] that observes all notifier state changes.
class AppProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    print('''
{
  "provider": "${provider.name ?? provider.runtimeType}",
  "newValue": "$newValue"
}''');
  }
}

/// {@template app}
/// A [StatelessWidget] that:
/// * uses [replay_riverpod](https://pub.dev/packages/replay_riverpod)
/// to manage the state of a counter.
/// {@endtemplate}
class App extends StatelessWidget {
  /// {@macro app}
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CounterPage(),
    );
  }
}

/// {@template counter_page}
/// A [StatelessWidget] that:
/// * demonstrates how to consume and interact with a [ReplayStateNotifier].
/// {@endtemplate}
class CounterPage extends ConsumerWidget {
  /// {@macro counter_page}
  const CounterPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final counter = ref.read(_counterProvider.notifier);
              return IconButton(
                icon: const Icon(Icons.undo),
                onPressed: counter.canUndo ? counter.undo : null,
              );
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final counter = ref.read(_counterProvider.notifier);
              return IconButton(
                icon: const Icon(Icons.redo),
                onPressed: counter.canRedo ? counter.redo : null,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(_counterProvider);
            return Text('$state', style: textTheme.headline2);
          },
        ),
      ),
      floatingActionButton: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              ref.read(_counterProvider.notifier).increment();
            },
          ),
          const SizedBox(height: 4),
          FloatingActionButton(
            child: const Icon(Icons.remove),
            onPressed: () {
              ref.read(_counterProvider.notifier).decrement();
            },
          ),
          const SizedBox(height: 4),
          FloatingActionButton(
            child: const Icon(Icons.delete_forever),
            onPressed: () {
              ref.read(_counterProvider.notifier).reset();
            },
          ),
        ],
      ),
    );
  }
}

/// {@template replay_counter_notifier}
/// A simple [ReplayStateNotifier] which manages an `int` as its state
/// and exposes three public methods to `increment`, `decrement`, and
/// `reset` the value of the state.
/// {@endtemplate}
class CounterNotifier extends ReplayStateNotifier<int> {
  /// {@macro replay_counter_notifier}
  CounterNotifier() : super(0);

  /// Increments the [CounterNotifier] state by 1.
  void increment() => state = state++;

  /// Decrements the [CounterNotifier] state by 1.
  void decrement() => state = state--;

  /// Resets the [CounterNotifier] state to 0.
  void reset() => state = 0;
}

final _counterProvider = StateNotifierProvider<CounterNotifier, int>(
  (ref) => CounterNotifier(),
);
