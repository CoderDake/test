// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An enum of all Dart runtimes supported by the test runner.
class Runtime {
  // When adding new runtimes, be sure to update the baseline and derived
  // variable tests in test/backend/platform_selector/evaluate_test.

  /// The command-line Dart VM.
  static const Runtime vm = Runtime('VM', 'vm', isDartVM: true);

  /// Google Chrome.
  static const Runtime chrome =
      Runtime('Chrome', 'chrome', isBrowser: true, isJS: true, isBlink: true);

  /// Mozilla Firefox.
  static const Runtime firefox =
      Runtime('Firefox', 'firefox', isBrowser: true, isJS: true);

  /// Apple Safari.
  static const Runtime safari =
      Runtime('Safari', 'safari', isBrowser: true, isJS: true);

  /// Microsoft Internet Explorer.
  static const Runtime internetExplorer =
      Runtime('Internet Explorer', 'ie', isBrowser: true, isJS: true);

  /// The command-line Node.js VM.
  static const Runtime nodeJS = Runtime('Node.js', 'node', isJS: true);

  /// Google Chrome.
  static const Runtime experimentalChromeWasm = Runtime(
      'ExperimentalChromeWasm', 'experimental-chrome-wasm',
      isBrowser: true, isBlink: true, isWasm: true);

  /// The platforms that are supported by the test runner by default.
  static const List<Runtime> builtIn = [
    Runtime.vm,
    Runtime.chrome,
    Runtime.firefox,
    Runtime.safari,
    Runtime.internetExplorer,
    Runtime.nodeJS,
    Runtime.experimentalChromeWasm,
  ];

  /// The human-friendly name of the platform.
  final String name;

  /// The identifier used to look up the platform.
  final String identifier;

  /// The parent platform that this is based on, or `null` if there is no
  /// parent.
  final Runtime? parent;

  /// Returns whether this is a child of another platform.
  bool get isChild => parent != null;

  /// Whether this platform runs the Dart VM in any capacity.
  final bool isDartVM;

  /// Whether this platform is a browser.
  final bool isBrowser;

  /// Whether this platform runs Dart compiled to JavaScript.
  final bool isJS;

  /// Whether this platform uses the Blink rendering engine.
  final bool isBlink;

  /// Whether this platform has no visible window.
  final bool isHeadless;

  /// Whether this platform runs Dart compiled to WASM.
  final bool isWasm;

  /// Returns the platform this is based on, or [this] if it's not based on
  /// anything.
  ///
  /// That is, returns [parent] if it's non-`null` or [this] if it's `null`.
  Runtime get root => parent ?? this;

  const Runtime(this.name, this.identifier,
      {this.isDartVM = false,
      this.isBrowser = false,
      this.isJS = false,
      this.isBlink = false,
      this.isHeadless = false,
      this.isWasm = false})
      : parent = null;

  Runtime._child(this.name, this.identifier, Runtime this.parent)
      : isDartVM = parent.isDartVM,
        isBrowser = parent.isBrowser,
        isJS = parent.isJS,
        isBlink = parent.isBlink,
        isHeadless = parent.isHeadless,
        isWasm = parent.isWasm;

  /// Converts a JSON-safe representation generated by [serialize] back into a
  /// [Runtime].
  factory Runtime.deserialize(Object serialized) {
    if (serialized is String) {
      return builtIn
          .firstWhere((platform) => platform.identifier == serialized);
    }

    var map = serialized as Map;
    var parent = map['parent'];
    if (parent != null) {
      // Note that the returned platform's [parent] won't necessarily be `==` to
      // a separately-deserialized parent platform. This should be fine, though,
      // since we only deserialize platforms in the remote execution context
      // where they're only used to evaluate platform selectors.
      return Runtime._child(map['name'] as String, map['identifier'] as String,
          Runtime.deserialize(parent as Object));
    }

    return Runtime(map['name'] as String, map['identifier'] as String,
        isDartVM: map['isDartVM'] as bool,
        isBrowser: map['isBrowser'] as bool,
        isJS: map['isJS'] as bool,
        isBlink: map['isBlink'] as bool,
        isHeadless: map['isHeadless'] as bool,
        isWasm: map['isWasm'] as bool);
  }

  /// Converts [this] into a JSON-safe object that can be converted back to a
  /// [Runtime] using [Runtime.deserialize].
  Object serialize() {
    if (builtIn.contains(this)) return identifier;

    if (parent != null) {
      return {
        'name': name,
        'identifier': identifier,
        'parent': parent!.serialize()
      };
    }

    return {
      'name': name,
      'identifier': identifier,
      'isDartVM': isDartVM,
      'isBrowser': isBrowser,
      'isJS': isJS,
      'isBlink': isBlink,
      'isHeadless': isHeadless,
      'isWasm': isWasm,
    };
  }

  /// Returns a child of [this] that counts as both this platform's identifier
  /// and the new [identifier].
  ///
  /// This may not be called on a platform that's already a child.
  Runtime extend(String name, String identifier) {
    if (parent == null) return Runtime._child(name, identifier, this);
    throw StateError('A child platform may not be extended.');
  }

  @override
  String toString() => name;
}
