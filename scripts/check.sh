#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

Analyze() {
	luau-lsp analyze \
		--definitions=globalTypes.d.luau \
		--base-luaurc=.luaurc \
		--flag:LuauSolverV2=true \
		"$@" 2>&1 | grep -v "^\[INFO\]" || true
}

echo "Checking formatting"
stylua --check init.luau src test examples

echo "Type checking"
Output="$(Analyze init.luau src/*.luau test/types/Valid.luau test/Tests.luau test/Testkit.luau $(find examples -name "*.luau"))"
Errors="$(printf '%s\n' "$Output" | grep -c "Error" || true)"
Baseline="$(tr -d '[:space:]' < scripts/strict-baseline.txt)"

if [ -n "$Output" ]; then
	printf '%s\n' "$Output"
fi

if [ "$Errors" -gt "$Baseline" ]; then
	echo "Type errors rose to $Errors, the baseline is $Baseline"
	exit 1
fi

if [ "$Errors" -lt "$Baseline" ]; then
	echo "Type errors fell to $Errors, lower scripts/strict-baseline.txt to match"
	exit 1
fi

echo "Checking that misuse is rejected"
for File in test/types/invalid/*.luau; do
	if ! Analyze "$File" | grep -q "TypeError"; then
		echo "$File should fail to type check but passed"
		exit 1
	fi
done

echo "Running tests"
lute run test/Tests.luau

echo "Building"
rojo build default.project.json -o SwiftPacket.rbxm > /dev/null
rm -f SwiftPacket.rbxm

echo "All checks passed"
