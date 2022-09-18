// ignore_for_file: lines_longer_than_80_chars

import 'dart:collection';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'change_stack.dart';

/// {@template replay_riverpod}
/// A specialized [StateNotifier] which supports `undo` and `redo` operations.
///
/// [ReplayStateNotifier] accepts an optional `limit` which determines
/// the max size of the history.
///
/// A custom [ReplayStateNotifier] can be created by extending [ReplayStateNotifier].
///
/// ```dart
/// class CounterNotifier extends ReplayRiverpod<int> {
///   CounterNotifier() : super(0);
///
///   void increment() => emit(state + 1);
/// }
/// ```
///
/// Then the built-in `undo` and `redo` operations can be used.
///
/// ```dart
/// final notifier = CounterNotifier();
///
/// notifier.increment();
/// print(notifier.state); // 1
///
/// notifier.undo();
/// print(notifier.state); // 0
///
/// notifier.redo();
/// print(notifier.state); // 1
/// ```
///
/// The undo/redo history can be destroyed at any time by calling `clear`.
///
/// See also:
///
/// * [StateNotifier] for information about the [ReplayStateNotifier] superclass.
///
/// {@endtemplate}
abstract class ReplayStateNotifier<State> extends StateNotifier<State>
    with ReplayStateNotifierMixin<State> {
  /// {@macro replay_riverpod}
  ReplayStateNotifier(State state, {int? limit}) : super(state) {
    if (limit != null) {
      this.limit = limit;
    }
  }
}

/// A mixin which enables `undo` and `redo` operations
/// for [StateNotifier] classes.
mixin ReplayStateNotifierMixin<State> on StateNotifier<State> {
  late final _changeStack = _ChangeStack<State>(shouldReplay: shouldReplay);

  /// Sets the internal `undo`/`redo` size limit.
  /// By default there is no limit.
  set limit(int limit) => _changeStack.limit = limit;

  @override
  set state(State newState) {
    _changeStack.add(_Change<State>(
      state,
      newState,
      () => super.state = newState,
      (val) => super.state = val,
    ));
    super.state = newState;
  }

  /// Undo the last change.
  void undo() => _changeStack.undo();

  /// Redo the previous change.
  void redo() => _changeStack.redo();

  /// Checks whether the undo/redo stack is empty.
  bool get canUndo => _changeStack.canUndo;

  /// Checks whether the undo/redo stack is at the current change.
  bool get canRedo => _changeStack.canRedo;

  /// Clear undo/redo history.
  void clearHistory() => _changeStack.clear();

  /// Checks whether the given state should be replayed from the undo/redo stack.
  ///
  /// This is called at the time the state is being restored.
  /// By default [shouldReplay] always returns `true`.
  bool shouldReplay(State state) => true;
}
