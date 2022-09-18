import 'package:replay_riverpod/replay_riverpod.dart';

class CounterNotifier extends ReplayStateNotifier<int> {
  CounterNotifier({
    int? limit,
    this.shouldReplayCallback,
  }) : super(0, limit: limit);

  final bool Function(int)? shouldReplayCallback;

  void increment() => state = state + 1;
  void decrement() => state = state - 1;

  @override
  bool shouldReplay(int state) {
    return shouldReplayCallback?.call(state) ?? super.shouldReplay(state);
  }
}

class CounterNotifierMixin extends StateNotifier<int>
    with ReplayStateNotifierMixin<int> {
  CounterNotifierMixin({int? limit}) : super(0) {
    if (limit != null) {
      this.limit = limit;
    }
  }

  void increment() => state = state + 1;
  void decrement() => state = state - 1;
}
