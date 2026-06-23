using CoverageTest
using Test

# When ExtendedLocalCoverage's `julia_args` test passes a (non-empty) file path via
# `test_args`, record this test process's heap-size hint so the parent can assert that
# `julia_args = ` --heap-size-hint=… ` ` actually reached the spawned test process.
if length(ARGS) >= 1 && !isempty(ARGS[1])
    write(ARGS[1], string(Base.JLOptions().heap_size_hint))
end

@test hello() == "Hello"
