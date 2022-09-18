<p align="center">
  <a href="https://pub.dev/packages/replay_riverpod"><img src="https://img.shields.io/pub/v/replay_riverpod.svg" alt="Pub"></a>
  <a href="https://github.com/gaganyadav80/replay_riverpod"><img src="https://img.shields.io/github/stars/gaganyadav80/replay_riverpod.svg?style=flat&logo=github&colorB=deeppink&label=stars" alt="Star on Github"></a>
  <a href="https://github.com/tenhobi/effective_dart"><img src="https://img.shields.io/badge/style-effective_dart-40c4ff.svg" alt="style: effective dart"></a>
  <a href="https://docs.flutter.dev/development/data-and-backend/state-mgmt/options#riverpod"><img src="https://img.shields.io/badge/flutter-website-deepskyblue.svg" alt="Flutter Website"></a>
  <a href="https://github.com/Solido/awesome-flutter#standard"><img src="https://img.shields.io/badge/awesome-flutter-blue.svg?longCache=true" alt="Awesome Flutter"></a>
  <a href="https://fluttersamples.com"><img src="https://img.shields.io/badge/flutter-samples-teal.svg?longCache=true" alt="Flutter Samples"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
</p>

An extension to [package:riverpod](https://github.com/rrousselGit/riverpod) which adds automatic undo and redo support to riverpod states.

Like [package:replay_bloc](https://pub.dev/packages/replay_bloc).

**Learn more at [riverpod.dev](https://riverpod.dev)!**


---

## Creating a ReplayStateNotifier

```dart
class CounterNotifer extends ReplayStateNotifier<int> {
  CounterNotifer() : super(0);

  void increment() => emit(state + 1);
}
```

## Using a CounterNotifer

```dart
void main() {
  final notifier = CounterNotifer();

  // trigger a state change
  notifier.increment();
  print(notifier.state); // 1

  // undo the change
  notifier.undo();
  print(notifier.state); // 0

  // redo the change
  notifier.redo();
  print(notifier.state); // 1
}
```

## ReplayStateNotifierMixin

If you wish to be able to use a `ReplayStateNotifier` in conjuction with a different type of state notifier like `HydratedStateNotifier` available with the package [package:hydrated_riverpod](https://pub.dev/packages/hydrated_riverpod), you can use the `ReplayStateNotifierMixin`.

```dart
class CounterNotifier extends HydratedStateNotifier<int> with ReplayStateNotifierMixin {
  CounterNotifier() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);

  @override
  int fromJson(Map<String, dynamic> json) => json['value'] as int;

  @override
  Map<String, int> toJson(int state) => {'value': state};
}
```

