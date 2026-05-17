import 'dart:developer';
import 'dart:io';

void main() async {
  log('===================================================');
  log('🛡️  Aether Architecture Linter (Diagnostic Mode) 🛡️');
  log('===================================================');

  final File pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    log('❌ CRITICAL ERROR: Not running in a Flutter project root.');
    log('💡 HEALING: `cd` into your project directory before running this.');
    return;
  }

  final File reportFile = File('ARCHITECTURE_REPORT.md');
  final StringBuffer out = StringBuffer();
  out.writeln('# Aether Diagnostic Report\n');

  // 1. Strict Lints
  log('⏳ Running Diagnostic: Code Quality (flutter analyze)...');
  try {
    final ProcessResult analyze = await Process.run('flutter', <String>['analyze']);
    if (analyze.exitCode == 0) {
      log('✅ Linter: PASS');
      out.writeln('### 1. Code Quality');
      out.writeln('✅ **PASS:** Zero static analysis warnings.');
    } else {
      log('❌ Linter: FAIL');
      out.writeln('### 1. Code Quality');
      out.writeln('❌ **FAIL:** Static analysis found issues.');
      out.writeln('\n💡 **HEALING ACTION:** Look at the terminal output of `flutter analyze` and resolve the warnings. Did you specify types? Did you await all Futures?');
    }
  } catch (e) {
    log('❌ CRITICAL ERROR: Could not run "flutter analyze". Is Flutter in your PATH?');
    return;
  }

  // 2. Outcome Verification (Tests)
  log('⏳ Running Diagnostic: Concurrency Check (flutter test)...');
  final File testFile = File('test/raid_concurrency_test.dart');
  
  if (!testFile.existsSync()) {
    log('❌ Tests: FAIL (raid_concurrency_test.dart is missing)');
    out.writeln('\n### 2. Concurrency Outcome');
    out.writeln('❌ **FAIL:** Missing test file.');
    out.writeln('\n💡 **HEALING ACTION:** You must place the provided `raid_concurrency_test.dart` file in the `test/` directory.');
  } else {
    try {
      final ProcessResult testResult = await Process.run('flutter', <String>['test', 'test/raid_concurrency_test.dart']);
      if (testResult.exitCode == 0) {
        log('✅ Tests: PASS');
        out.writeln('\n### 2. Concurrency Outcome');
        out.writeln('✅ **PASS:** Your architecture survived the Thundering Herd.');
      } else {
        log('❌ Tests: FAIL');
        out.writeln('\n### 2. Concurrency Outcome');
        out.writeln('❌ **FAIL:** The 50-request blast failed to yield exactly 15 slots.');
        out.writeln('\n💡 **HEALING ACTION:** Read your test failure logs. Did your `joinRaid()` method correctly handle the race condition? Are you using locks or transactions?');
      }
    } catch (e) {
      log('❌ CRITICAL ERROR: Could not execute "flutter test".');
    }
  }

  try {
    reportFile.writeAsStringSync(out.toString());
    log('\n===================================================');
    log('📄 Report saved to ARCHITECTURE_REPORT.md');
    log('👀 Read the report for HEALING ACTIONS to fix your architecture.');
    log('===================================================');
  } catch (e) {
    log('❌ Could not write to ARCHITECTURE_REPORT.md. Check file permissions.');
  }
}
