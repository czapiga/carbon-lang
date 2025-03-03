// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CARBON_TESTING_FILE_TEST_FILE_TEST_BASE_H_
#define CARBON_TESTING_FILE_TEST_FILE_TEST_BASE_H_

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include <functional>
#include <mutex>

#include "common/error.h"
#include "common/ostream.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/VirtualFileSystem.h"
#include "testing/file_test/autoupdate.h"

namespace Carbon::Testing {

// A framework for testing files. See README.md for documentation.
class FileTestBase : public testing::Test {
 public:
  struct TestFile {
    friend void PrintTo(const TestFile& f, std::ostream* os) {
      // Print content escaped.
      llvm::raw_os_ostream os_wrap(*os);
      os_wrap << "TestFile(" << f.filename << ", \"" << FormatEscaped(f.content)
              << "\")";
    }

    std::string filename;
    std::string content;
  };

  // Provided for child class convenience.
  using LineNumberReplacement = FileTestAutoupdater::LineNumberReplacement;

  // The result of Run(), used to detect errors. Failing test files should be
  // named with a `fail_` prefix to indicate an expectation of failure.
  //
  // If per_file_success is empty:
  // - The main file has a `fail_` prefix if !success.
  // - The prefix of split files is unused.
  //
  // If per_file_success is non-empty:
  // - Each file has a `fail_` prefix if !per_file_success[i].second.
  //   - Files may be in per_file_success that aren't part of the main test
  //     file. This allows tracking success in handling files that are
  //     well-known, such as standard libraries. It is still the responsibility
  //     of callers to use a `fail_` prefix if !per_file_success[i].second.
  // - If any file has a `fail_` prefix, success must be false, and the prefix
  //   of the main file is unused.
  // - If no file has a `fail_` prefix, the main file has a `fail_` prefix if
  //   !success.
  struct RunResult {
    bool success;

    // Per-file success results. May be empty.
    llvm::SmallVector<std::pair<std::string, bool>> per_file_success;
  };

  explicit FileTestBase(std::mutex* output_mutex, llvm::StringRef test_name)
      : output_mutex_(output_mutex), test_name_(test_name) {}

  // Implemented by children to run the test. The framework will validate the
  // content written to `output_stream` and `error_stream`. Children should use
  // `fs` for file content, and may add more files.
  //
  // If there is a split test file named "STDIN", then its contents will be
  // provided at `input_stream` instead of `fs`. Otherwise, `input_stream` will
  // be null.
  //
  // Any test expectations should be called from ValidateRun, not Run.
  //
  // The return value should be an error if there was an abnormal error, and
  // RunResult otherwise.
  virtual auto Run(const llvm::SmallVector<llvm::StringRef>& test_args,
                   llvm::IntrusiveRefCntPtr<llvm::vfs::InMemoryFileSystem>& fs,
                   FILE* input_stream, llvm::raw_pwrite_stream& output_stream,
                   llvm::raw_pwrite_stream& error_stream)
      -> ErrorOr<RunResult> = 0;

  // Implemented by children to do post-Run test expectations. Only called when
  // testing. Does not need to be provided if only CHECK test expectations are
  // used.
  virtual auto ValidateRun() -> void {}

  // Returns default arguments. Only called when a file doesn't set ARGS.
  virtual auto GetDefaultArgs() -> llvm::SmallVector<std::string> = 0;

  // Returns a map of string replacements to implement `%{key}` -> `value` in
  // arguments.
  virtual auto GetArgReplacements() -> llvm::StringMap<std::string> {
    return {};
  }

  // Returns a regex to match the default file when a line may not be present.
  // May return nullptr if unused. If GetLineNumberReplacements returns an entry
  // with has_file=false, this is required.
  virtual auto GetDefaultFileRE(llvm::ArrayRef<llvm::StringRef> /*filenames*/)
      -> std::optional<RE2> {
    return std::nullopt;
  }

  // Returns replacement information for line numbers. See LineReplacement for
  // construction.
  virtual auto GetLineNumberReplacements(
      llvm::ArrayRef<llvm::StringRef> filenames)
      -> llvm::SmallVector<LineNumberReplacement>;

  // Optionally allows children to provide extra replacements for autoupdate.
  virtual auto DoExtraCheckReplacements(std::string& /*check_line*/) -> void {}

  // Whether to allow running the test in parallel, particularly for autoupdate.
  // This can be overridden to force some tests to be run serially. At any given
  // time, all parallel tests and a single non-parallel test will be allowed to
  // run.
  virtual auto AllowParallelRun() const -> bool { return true; }

  // Runs a test and compares output. This keeps output split by line so that
  // issues are a little easier to identify by the different line.
  auto TestBody() -> void final;

  // Runs the test and autoupdates checks. Returns true if updated.
  auto Autoupdate() -> ErrorOr<bool>;

  // Runs the test and dumps output.
  auto DumpOutput() -> ErrorOr<Success>;

  // Returns the name of the test (relative to the repo root).
  auto test_name() const -> llvm::StringRef { return test_name_; }

 private:
  // Encapsulates test context generated by processing and running.
  struct TestContext {
    // The input test file content. Other parts may reference this.
    std::string input_content;

    // Lines which don't contain CHECKs, and thus need to be retained by
    // autoupdate. Their file and line numbers are attached.
    //
    // If there are splits, then the splitting line is in the respective file.
    // For N splits, the 0th file is the parts of the input file which are not
    // in any split, plus one file per split file.
    llvm::SmallVector<FileTestLine> non_check_lines;

    // Whether there are splits.
    bool has_splits = false;

    // Arguments for the test, generated from ARGS.
    llvm::SmallVector<std::string> test_args;

    // Extra arguments for the test, generated from EXTRA-ARGS. Unlike ARGS,
    // setting EXTRA-ARGS does not suppress the default arguments.
    llvm::SmallVector<std::string> extra_args;

    // Files in the test, generated by content and splits.
    llvm::SmallVector<TestFile> test_files;

    // The location of the autoupdate marker, for autoupdated files.
    std::optional<int> autoupdate_line_number;

    // Whether there should be an AUTOUPDATE-SPLIT.
    bool autoupdate_split = false;

    // Whether to capture stderr and stdout that would head to console,
    // generated from SET-CAPTURE-CONSOLE-OUTPUT.
    bool capture_console_output = false;

    // Whether checks are a subset, generated from SET-CHECK-SUBSET.
    bool check_subset = false;

    // Whether `--dump_output` is specified, causing `Run` output to go to the
    // console. Output is typically captured for tests and autoupdate.
    bool dump_output = false;

    // stdout and stderr based on CHECK lines in the file.
    llvm::SmallVector<testing::Matcher<std::string>> expected_stdout;
    llvm::SmallVector<testing::Matcher<std::string>> expected_stderr;

    // stdout and stderr from Run. 16 is arbitrary but a required value.
    llvm::SmallString<16> actual_stdout;
    llvm::SmallString<16> actual_stderr;

    RunResult run_result = {.success = false};
  };

  // Processes the test file and runs the test. Returns an error if something
  // went wrong.
  auto ProcessTestFileAndRun(TestContext& context) -> ErrorOr<Success>;

  // Does replacements in ARGS for %s and %t.
  auto DoArgReplacements(llvm::SmallVector<std::string>& test_args,
                         const llvm::SmallVector<TestFile>& test_files)
      -> ErrorOr<Success>;

  // Processes the test input, producing test files and expected output.
  auto ProcessTestFile(TestContext& context) -> ErrorOr<Success>;

  // Runs the FileTestAutoupdater, returning the result.
  auto RunAutoupdater(const TestContext& context, bool dry_run) -> bool;

  // An optional mutex for output. If provided, it will be locked during `Run`
  // when stderr/stdout are being captured (SET-CAPTURE-CONSOLE-OUTPUT), in
  // order to avoid output conflicts.
  std::mutex* output_mutex_;

  llvm::StringRef test_name_;
};

// Aggregate a name and factory function for tests using this framework.
struct FileTestFactory {
  // The test fixture name.
  const char* name;

  // A factory function for tests. The output_mutex is optional; see
  // `FileTestBase::output_mutex_`.
  std::function<auto(llvm::StringRef exe_path, std::mutex* output_mutex,
                     llvm::StringRef test_name)
                    ->FileTestBase*>
      factory_fn;
};

// Must be implemented by the individual file_test to initialize tests.
//
// We can't use INSTANTIATE_TEST_CASE_P because of ordering issues between
// container initialization and test instantiation by InitGoogleTest, but this
// also allows us more flexibility in execution.
//
// The `CARBON_FILE_TEST_FACTOR` macro below provides a standard, convenient way
// to implement this function.
extern auto GetFileTestFactory() -> FileTestFactory;

// Provides a standard GetFileTestFactory implementation.
#define CARBON_FILE_TEST_FACTORY(Name)                                    \
  auto GetFileTestFactory() -> FileTestFactory {                          \
    return {#Name, [](llvm::StringRef exe_path, std::mutex* output_mutex, \
                      llvm::StringRef test_name) {                        \
              return new Name(exe_path, output_mutex, test_name);         \
            }};                                                           \
  }

}  // namespace Carbon::Testing

#endif  // CARBON_TESTING_FILE_TEST_FILE_TEST_BASE_H_
