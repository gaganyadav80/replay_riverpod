// ignore_for_file: cascade_invocations, invalid_use_of_protected_member

import 'dart:async';

import 'package:test/test.dart';

import 'provider/counter_notifier.dart';

var log = <String>[];

void Function() overridePrint(void testFn()) => () {
      var spec = ZoneSpecification(print: (_, __, ___, String msg) {
        // Add to log instead of printing to stdout
        log.add(msg);
      });
      return Zone.current.fork(specification: spec).run<void>(testFn);
    };

void main() {
  group('ReplayNotifier', () {
    group('initial state', () {
      test('is correct', () {
        expect(CounterNotifier().state, 0);
      });
    });

    group('canUndo', () {
      test('is false when no state changes have occurred', () async {
        final counterNotifier = CounterNotifier();
        expect(counterNotifier.canUndo, isFalse);
        counterNotifier.dispose();
      });

      test('is true when a single state change has occurred', () async {
        final counterNotifier = CounterNotifier();
        await Future<void>.delayed(Duration.zero, counterNotifier.increment);
        expect(counterNotifier.canUndo, isTrue);
        counterNotifier.dispose();
      });

      test('is false when undos have been exhausted', () async {
        final counterNotifier = CounterNotifier();
        await Future<void>.delayed(Duration.zero, counterNotifier.increment);
        await Future<void>.delayed(Duration.zero, counterNotifier.undo);
        expect(counterNotifier.canUndo, isFalse);
        counterNotifier.dispose();
      });
    });

    group('canRedo', () {
      test('is false when no state changes have occurred', () async {
        final counterNotifier = CounterNotifier();
        expect(counterNotifier.canRedo, isFalse);
        counterNotifier.dispose();
      });

      test('is true when a single undo has occurred', () async {
        final counterNotifier = CounterNotifier();
        await Future<void>.delayed(Duration.zero, counterNotifier.increment);
        await Future<void>.delayed(Duration.zero, counterNotifier.undo);
        expect(counterNotifier.canRedo, isTrue);
        counterNotifier.dispose();
      });

      test('is false when redos have been exhausted', () async {
        final counterNotifier = CounterNotifier();
        await Future<void>.delayed(Duration.zero, counterNotifier.increment);
        await Future<void>.delayed(Duration.zero, counterNotifier.undo);
        await Future<void>.delayed(Duration.zero, counterNotifier.redo);
        expect(counterNotifier.canRedo, isFalse);
        counterNotifier.dispose();
      });
    });

    group('clearHistory', () {
      test('clears history and redos on new counterNotifier', () async {
        final counterNotifier = CounterNotifier()..clearHistory();
        expect(counterNotifier.canRedo, isFalse);
        expect(counterNotifier.canUndo, isFalse);
        counterNotifier.dispose();
      });
    });

    group('undo', () {
      test('does nothing when no state changes have occurred', () async {
        final states = <int>[];
        final counterNotifier = CounterNotifier();
        counterNotifier.addListener(states.add, fireImmediately: false);
        counterNotifier
          ..undo()
          ..dispose();

        expect(states, isEmpty);
      });

      test('does nothing when limit is 0', () async {
        final states = <int>[];
        final counterNotifier = CounterNotifier(limit: 0);
        counterNotifier.addListener(states.add, fireImmediately: false);

        counterNotifier
          ..increment()
          ..undo()
          ..dispose();

        expect(states, const <int>[1]);
      });

      test('skips states filtered out by shouldReplay at undo time', () async {
        final states = <int>[];
        final counterNotifier =
            CounterNotifier(shouldReplayCallback: (i) => !i.isEven);
        counterNotifier.addListener(states.add, fireImmediately: false);
        counterNotifier
          ..increment()
          ..increment()
          ..increment();
        await Future<void>.delayed(Duration.zero);
        counterNotifier
          ..undo()
          ..undo()
          ..undo()
          ..dispose();

        expect(states, const <int>[1, 2, 3, 1]);
      });

      test(
          'doesn\'t skip states that would be filtered out by shouldReplay '
          'at transition time but not at undo time', () async {
        var replayEvens = false;
        final states = <int>[];
        final counterNotifier = CounterNotifier(
          shouldReplayCallback: (i) => !i.isEven || replayEvens,
        );
        counterNotifier.addListener(states.add, fireImmediately: false);
        counterNotifier
          ..increment()
          ..increment()
          ..increment();
        await Future<void>.delayed(Duration.zero);
        replayEvens = true;
        counterNotifier
          ..undo()
          ..undo()
          ..undo()
          ..dispose();

        expect(states, const <int>[1, 2, 3, 2, 1, 0]);
      });

      test('loses history outside of limit', () async {
        final states = <int>[];
        final counterNotifier = CounterNotifier(limit: 1);
        counterNotifier.addListener(states.add, fireImmediately: false);
        counterNotifier
          ..increment()
          ..increment()
          ..undo()
          ..undo();
        counterNotifier.dispose();

        expect(states, const <int>[1, 2, 1]);
      });

      test('reverts to initial state', () async {
        final states = <int>[];
        final counterNotifier = CounterNotifier();
        counterNotifier.addListener(states.add, fireImmediately: false);
        counterNotifier
          ..increment()
          ..undo();
        counterNotifier.dispose();

        expect(states, const <int>[1, 0]);
      });

      test('reverts to previous state with multiple state changes ', () async {
        final states = <int>[];
        final counterNotifier = CounterNotifier();
        counterNotifier.addListener(states.add, fireImmediately: false);
        counterNotifier
          ..increment()
          ..increment()
          ..undo();
        counterNotifier.dispose();

        expect(states, const <int>[1, 2, 1]);
      });
    });

    group('redo', () {
      test('does nothing when no state changes have occurred', () async {
        final states = <int>[];
        final counterNotifier = CounterNotifier();
        counterNotifier.addListener(states.add, fireImmediately: false);
        counterNotifier.redo();
        counterNotifier.dispose();

        expect(states, isEmpty);
      });

      test('does nothing when no undos have occurred', () async {
        final states = <int>[];
        final counterNotifier = CounterNotifier();
        counterNotifier.addListener(states.add, fireImmediately: false);
        counterNotifier
          ..increment()
          ..increment()
          ..redo();
        counterNotifier.dispose();

        expect(states, const <int>[1, 2]);
      });

      test('works when one undo has occurred', () async {
        final states = <int>[];
        final counterNotifier = CounterNotifier();
        counterNotifier.addListener(states.add, fireImmediately: false);
        counterNotifier
          ..increment()
          ..increment()
          ..undo()
          ..redo();
        counterNotifier.dispose();

        expect(states, const <int>[1, 2, 1, 2]);
      });

      test('does nothing when undos have been exhausted', () async {
        final states = <int>[];
        final counterNotifier = CounterNotifier();
        counterNotifier.addListener(states.add, fireImmediately: false);
        counterNotifier
          ..increment()
          ..increment()
          ..undo()
          ..redo()
          ..redo();
        counterNotifier.dispose();

        expect(states, const <int>[1, 2, 1, 2]);
      });

      test(
          'does nothing when undos has occurred '
          'followed by a new state change', () async {
        final states = <int>[];
        final counterNotifier = CounterNotifier();
        counterNotifier.addListener(states.add, fireImmediately: false);
        counterNotifier
          ..increment()
          ..increment()
          ..undo()
          ..decrement()
          ..redo();
        counterNotifier.dispose();

        expect(states, const <int>[1, 2, 1, 0]);
      });

      test(
          'redo does not redo states which were'
          ' filtered out by shouldReplay at undo time', () async {
        final states = <int>[];
        final counterNotifier =
            CounterNotifier(shouldReplayCallback: (i) => !i.isEven);
        counterNotifier.addListener(states.add, fireImmediately: false);
        counterNotifier
          ..increment()
          ..increment()
          ..increment()
          ..undo()
          ..undo()
          ..undo()
          ..redo()
          ..redo()
          ..redo();
        counterNotifier.dispose();

        expect(states, const <int>[1, 2, 3, 1, 3]);
      });

      test(
          'redo does not redo states which were'
          ' filtered out by shouldReplay at transition time', () async {
        var replayEvens = false;
        final states = <int>[];
        final counterNotifier = CounterNotifier(
          shouldReplayCallback: (i) => !i.isEven || replayEvens,
        );
        counterNotifier.addListener(states.add, fireImmediately: false);
        counterNotifier
          ..increment()
          ..increment()
          ..increment()
          ..undo()
          ..undo()
          ..undo();
        replayEvens = true;
        counterNotifier
          ..redo()
          ..redo()
          ..redo();
        counterNotifier.dispose();

        expect(states, const <int>[1, 2, 3, 1, 2, 3]);
      });
    });
  });

  group('ReplayMixin', () {
    group('initial state', () {
      test('is correct', () {
        expect(CounterNotifierMixin().state, 0);
      });
    });

    group('canUndo', () {
      test('is false when no state changes have occurred', () async {
        final counterNotifier = CounterNotifierMixin();
        expect(counterNotifier.canUndo, isFalse);
        counterNotifier.dispose();
      });

      test('is true when a single state change has occurred', () async {
        final counterNotifier = CounterNotifierMixin()..increment();
        expect(counterNotifier.canUndo, isTrue);
        counterNotifier.dispose();
      });

      test('is false when undos have been exhausted', () async {
        final counterNotifier = CounterNotifierMixin()
          ..increment()
          ..undo();
        expect(counterNotifier.canUndo, isFalse);
        counterNotifier.dispose();
      });
    });

    group('canRedo', () {
      test('is false when no state changes have occurred', () async {
        final counterNotifier = CounterNotifierMixin();
        expect(counterNotifier.canRedo, isFalse);
        counterNotifier.dispose();
      });

      test('is true when a single undo has occurred', () async {
        final counterNotifier = CounterNotifierMixin()
          ..increment()
          ..undo();
        expect(counterNotifier.canRedo, isTrue);
        counterNotifier.dispose();
      });

      test('is false when redos have been exhausted', () async {
        final counterNotifier = CounterNotifierMixin()
          ..increment()
          ..undo()
          ..redo();
        expect(counterNotifier.canRedo, isFalse);
        counterNotifier.dispose();
      });
    });

    group('clearHistory', () {
      test('clears history and redos on new counterNotifier', () async {
        final counterNotifier = CounterNotifierMixin()..clearHistory();
        expect(counterNotifier.canRedo, isFalse);
        expect(counterNotifier.canUndo, isFalse);
        counterNotifier.dispose();
      });
    });

    group('undo', () {
      test('does nothing when no state changes have occurred', () async {
        final states = <int>[];
        final counterNotifier = CounterNotifierMixin();
        counterNotifier.addListener(states.add, fireImmediately: false);
        counterNotifier.undo();
        counterNotifier.dispose();

        expect(states, isEmpty);
      });

      test('does nothing when limit is 0', () async {
        final states = <int>[];
        final counterNotifier = CounterNotifierMixin(limit: 0);
        counterNotifier.addListener(states.add, fireImmediately: false);
        counterNotifier
          ..increment()
          ..undo();
        counterNotifier.dispose();

        expect(states, const <int>[1]);
      });

      test('loses history outside of limit', () async {
        final states = <int>[];
        final counterNotifier = CounterNotifierMixin(limit: 1);
        counterNotifier.addListener(states.add, fireImmediately: false);
        counterNotifier
          ..increment()
          ..increment()
          ..undo()
          ..undo();
        counterNotifier.dispose();

        expect(states, const <int>[1, 2, 1]);
      });

      test('reverts to initial state', () async {
        final states = <int>[];
        final counterNotifier = CounterNotifierMixin();
        counterNotifier.addListener(states.add, fireImmediately: false);
        counterNotifier
          ..increment()
          ..undo();
        counterNotifier.dispose();

        expect(states, const <int>[1, 0]);
      });

      test('reverts to previous state with multiple state changes ', () async {
        final states = <int>[];
        final counterNotifier = CounterNotifierMixin();
        counterNotifier.addListener(states.add, fireImmediately: false);
        counterNotifier
          ..increment()
          ..increment()
          ..undo();
        counterNotifier.dispose();

        expect(states, const <int>[1, 2, 1]);
      });
    });

    group('redo', () {
      test('does nothing when no state changes have occurred', () async {
        final states = <int>[];
        final counterNotifier = CounterNotifierMixin();
        counterNotifier.addListener(states.add, fireImmediately: false);
        await Future<void>.delayed(Duration.zero, counterNotifier.redo);
        counterNotifier.dispose();

        expect(states, isEmpty);
      });

      test('does nothing when no undos have occurred', () async {
        final states = <int>[];
        final counterNotifier = CounterNotifierMixin();
        counterNotifier.addListener(states.add, fireImmediately: false);
        counterNotifier
          ..increment()
          ..increment()
          ..redo();
        counterNotifier.dispose();

        expect(states, const <int>[1, 2]);
      });

      test('works when one undo has occurred', () async {
        final states = <int>[];
        final counterNotifier = CounterNotifierMixin();
        counterNotifier.addListener(states.add, fireImmediately: false);
        counterNotifier
          ..increment()
          ..increment()
          ..undo()
          ..redo();
        counterNotifier.dispose();

        expect(states, const <int>[1, 2, 1, 2]);
      });

      test('does nothing when undos have been exhausted', () async {
        final states = <int>[];
        final counterNotifier = CounterNotifierMixin();
        counterNotifier.addListener(states.add, fireImmediately: false);
        counterNotifier
          ..increment()
          ..increment()
          ..undo()
          ..redo()
          ..redo();
        counterNotifier.dispose();

        expect(states, const <int>[1, 2, 1, 2]);
      });

      test(
          'does nothing when undos has occurred '
          'followed by a new state change', () async {
        final states = <int>[];
        final counterNotifier = CounterNotifierMixin();
        counterNotifier.addListener(states.add, fireImmediately: false);
        counterNotifier
          ..increment()
          ..increment()
          ..undo()
          ..decrement()
          ..redo();
        counterNotifier.dispose();

        expect(states, const <int>[1, 2, 1, 0]);
      });
    });
  });
}
