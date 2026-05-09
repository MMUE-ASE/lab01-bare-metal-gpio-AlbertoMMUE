#!/usr/bin/env bash
# Automatic grader for guided questions — Lab 1
#
# Usage:
#   bash check_answers.sh <answers.env> <answer_key.env>
#
# The answer key comes from a GitHub Actions organization secret
# and is never stored in the repository.

set -euo pipefail

STUDENT_FILE="${1:-answers.env}"
KEY_FILE="${2:-}"

# ---------------------------------------------------------------------------
# Parsing helpers
# ---------------------------------------------------------------------------

get_from() {
    local file="$1" key="$2"
    grep -E "^${key}=" "$file" 2>/dev/null \
        | head -1 | cut -d'=' -f2- | tr -d ' \r\t' || true
}

to_dec() {
    local val="${1,,}"; val="${val#\"}" ; val="${val%\"}"
    val="${val%%[ul]*}"
    if   [[ "$val" =~ ^0x([0-9a-f]+)$ ]]; then printf "%d" "$val" 2>/dev/null || echo ""
    elif [[ "$val" =~ ^0b([01]+)$      ]]; then echo "$((2#${val#0b}))"
    elif [[ "$val" =~ ^[0-9]+$         ]]; then echo "$((10#$val))"
    else echo ""; fi
}

norm_hex() {
    local val="${1,,}"; val="${val#0x}"; val="${val#\"}"; val="${val%\"}"
    val="${val%%[ul]*}"
    [[ "$val" =~ ^[0-9a-f]+$ ]] && printf "%08x" "0x${val}" 2>/dev/null || echo ""
}

# Pad with dots to a fixed column
dots() {
    local label="$1" width=36
    local n=$(( width - ${#label} ))
    [[ $n -lt 2 ]] && n=2
    printf '%*s' "$n" '' | tr ' ' '.'
}

# ---------------------------------------------------------------------------
# Comparison type per key
# ---------------------------------------------------------------------------

declare -A KEY_TYPE
KEY_TYPE[B1_PIN]="pin";            KEY_TYPE[LD2_PIN]="pin"
KEY_TYPE[B1_IDLE_LEVEL]="int";     KEY_TYPE[B1_PRESSED_LEVEL]="int"
KEY_TYPE[RCC_BASE]="hex";          KEY_TYPE[GPIOB_BASE]="hex";       KEY_TYPE[GPIOC_BASE]="hex"
KEY_TYPE[GPIOBEN_BIT]="int";       KEY_TYPE[GPIOCEN_BIT]="int";      KEY_TYPE[AHB1ENR_MASK]="hex"
KEY_TYPE[MODER_BITS_PER_PIN]="int"; KEY_TYPE[MODER_INPUT_VAL]="int"; KEY_TYPE[MODER_OUTPUT_VAL]="int"
KEY_TYPE[PB7_MODER_BIT]="int";     KEY_TYPE[PC13_MODER_BIT]="int"
KEY_TYPE[IDR_OFFSET]="hex";        KEY_TYPE[ODR_OFFSET]="hex"
KEY_TYPE[PC13_IDR_BIT]="int";      KEY_TYPE[PB7_ODR_BIT]="int"

# ---------------------------------------------------------------------------
# Hints per key (without revealing the answer)
# ---------------------------------------------------------------------------

declare -A HINT
HINT[B1_PIN]="UM1974 → section 'Push-button'"
HINT[LD2_PIN]="UM1974 → section 'LEDs'"
HINT[B1_IDLE_LEVEL]="check the pull-up resistor in the schematic"
HINT[B1_PRESSED_LEVEL]="what voltage does the button connect to the pin when closed?"
HINT[RCC_BASE]="RM0402 → Memory map → AHB1 peripherals"
HINT[GPIOB_BASE]="RM0402 → Memory map → AHB1 peripherals"
HINT[GPIOC_BASE]="RM0402 → Memory map → AHB1 peripherals"
HINT[GPIOBEN_BIT]="RM0402 → RCC_AHB1ENR → field GPIOBEN"
HINT[GPIOCEN_BIT]="RM0402 → RCC_AHB1ENR → field GPIOCEN"
HINT[AHB1ENR_MASK]="OR of the two previous bits"
HINT[MODER_BITS_PER_PIN]="RM0402 → GPIOx_MODER → width of each MODERy field"
HINT[MODER_INPUT_VAL]="RM0402 → GPIOx_MODER → value '00'"
HINT[MODER_OUTPUT_VAL]="RM0402 → GPIOx_MODER → value '01'"
HINT[PB7_MODER_BIT]="formula: pin_number × bits_per_pin"
HINT[PC13_MODER_BIT]="formula: pin_number × bits_per_pin"
HINT[IDR_OFFSET]="RM0402 → GPIO register table → GPIOx_IDR"
HINT[ODR_OFFSET]="RM0402 → GPIO register table → GPIOx_ODR"
HINT[PC13_IDR_BIT]="bit N of IDR corresponds to pin N"
HINT[PB7_ODR_BIT]="bit N of ODR corresponds to pin N"

# ---------------------------------------------------------------------------
# Display order with section markers (## prefix)
# ---------------------------------------------------------------------------

ORDERED_KEYS=(
    "##Block 1 . Board hardware"
    B1_PIN LD2_PIN B1_IDLE_LEVEL B1_PRESSED_LEVEL
    "##Block 2 . Memory map"
    RCC_BASE GPIOB_BASE GPIOC_BASE
    "##Block 3 . Peripheral clock (RCC_AHB1ENR)"
    GPIOBEN_BIT GPIOCEN_BIT AHB1ENR_MASK
    "##Block 4 . Pin mode (GPIOx_MODER)"
    MODER_BITS_PER_PIN MODER_INPUT_VAL MODER_OUTPUT_VAL PB7_MODER_BIT PC13_MODER_BIT
    "##Block 5 . Read and write (IDR / ODR)"
    IDR_OFFSET ODR_OFFSET PC13_IDR_BIT PB7_ODR_BIT
)

# ---------------------------------------------------------------------------
# Input guards
# ---------------------------------------------------------------------------

if [[ ! -f "$STUDENT_FILE" ]]; then
    echo "ERROR: Student file not found: $STUDENT_FILE"
    exit 1
fi

if [[ -z "$KEY_FILE" || ! -f "$KEY_FILE" ]]; then
    echo "ERROR: Answer key required as second argument."
    echo "       Local: bash check_answers.sh answers.env answer_key.env"
    echo "       CI:    the workflow generates it from secret LAB1_ANSWER_KEY"
    exit 1
fi

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------

echo ""
echo ".------------------------------------------------."
echo "|  Lab 1  .  Guided Questions Grader             |"
echo "|  STM32F412ZG  .  NUCLEO-144                    |"
echo "'------------------------------------------------'"

PASSED=0; FAILED=0; SKIPPED=0

# ---------------------------------------------------------------------------
# Grading loop
# ---------------------------------------------------------------------------

for item in "${ORDERED_KEYS[@]}"; do

    # Section marker
    if [[ "$item" == "##"* ]]; then
        echo ""
        echo "  -- ${item#"##"} --"
        echo ""
        continue
    fi

    key="$item"
    student_raw=$(get_from "$STUDENT_FILE" "$key")
    expected_raw=$(get_from "$KEY_FILE" "$key")
    type="${KEY_TYPE[$key]}"

    if [[ -z "$student_raw" ]]; then
        printf "  ⬜  %s %s no answer\n" "$key" "$(dots "$key")"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    case "$type" in
        hex) got=$(norm_hex "$student_raw"); exp=$(norm_hex "$expected_raw") ;;
        pin) got="${student_raw^^}";         exp="${expected_raw^^}"          ;;
        int) got=$(to_dec "$student_raw");   exp=$(to_dec "$expected_raw")   ;;
    esac

    if [[ -z "$got" ]]; then
        printf "  ❌  %s %s unrecognized format ('%s')\n" "$key" "$(dots "$key")" "$student_raw"
        printf "       → %s\n" "${HINT[$key]:-check the Reference Manual}"
        FAILED=$((FAILED + 1))
    elif [[ "$got" == "$exp" ]]; then
        printf "  ✅  %s %s ok\n" "$key" "$(dots "$key")"
        PASSED=$((PASSED + 1))
    else
        printf "  ❌  %s %s incorrect\n" "$key" "$(dots "$key")"
        printf "       → %s\n" "${HINT[$key]:-check the Reference Manual}"
        FAILED=$((FAILED + 1))
    fi

done

# ---------------------------------------------------------------------------
# Final summary
# ---------------------------------------------------------------------------

TOTAL=$(( PASSED + FAILED + SKIPPED ))

# Score out of 10 (integer division)
if [[ $TOTAL -gt 0 ]]; then
    SCORE=$(( PASSED * 10 / TOTAL ))
    filled=$(( PASSED * 20 / TOTAL ))
    bar=""
    for (( i=0; i<20; i++ )); do
        [[ $i -lt $filled ]] && bar+="█" || bar+="░"
    done
    pct=$(( PASSED * 100 / TOTAL ))
else
    SCORE=0; bar="░░░░░░░░░░░░░░░░░░░░"; pct=0
fi

# ---------------------------------------------------------------------------
# ASCII art based on score — LD2 brightness
# ---------------------------------------------------------------------------

echo ""

if [[ $SCORE -eq 10 ]]; then
    echo "          . . . . . . . ."
    echo "        .                 ."
    echo "      .    * . * . * . *    ."
    echo "     .   *               *   ."
    echo "      .    * . * . * . *    ."
    echo "        .                 ."
    echo "          . . . . . . . ."
    echo "        [ LD2  full brightness ]"
elif [[ $SCORE -ge 7 ]]; then
    echo "          . . . . . ."
    echo "        .     * *     ."
    echo "       .    *     *    ."
    echo "        .     * *     ."
    echo "          . . . . . ."
    echo "          [ LD2  on ]"
elif [[ $SCORE -ge 5 ]]; then
    echo "          . . . . ."
    echo "        .    . .    ."
    echo "       .             ."
    echo "        .    . .    ."
    echo "          . . . . ."
    echo "          [ LD2  dim ]"
else
    echo "          . . . . ."
    echo "        .           ."
    echo "       .             ."
    echo "        .           ."
    echo "          . . . . ."
    echo "          [ LD2  off ]"
fi

# ---------------------------------------------------------------------------
# Score box
# ---------------------------------------------------------------------------

echo ""
echo ".------------------------------------------------."
printf "|  Correct: %2d / %2d  .  Score: %2d / 10%-11s|\n" \
    "$PASSED" "$TOTAL" "$SCORE" ""
printf "|  [%s]  %3d%%%-18s|\n" "$bar" "$pct" ""
echo "|                                                |"

if [[ $SCORE -eq 10 ]]; then
    echo "|  Perfect register map. The chip obeys you.     |"
    echo "|  Time to write the driver. 🚀                  |"
elif [[ $SCORE -ge 7 ]]; then
    echo "|  Good work. You know your registers.           |"
    echo "|  Fix the remaining errors and reach 10. 💪     |"
elif [[ $SCORE -ge 5 ]]; then
    echo "|  Passing, but the MCU deserves better.         |"
    echo "|  Go back to the Reference Manual. 📖           |"
else
    echo "|  The LED is still off... for now.              |"
    echo "|  Every register you read gets you closer. 🔍  |"
fi

echo "'------------------------------------------------'"
echo ""

[[ $FAILED -eq 0 && $SKIPPED -eq 0 ]] && exit 0 || exit 1
