#!/bin/bash

#Check 1 command line arg was provided.
if [ "$#" -ne 1 ]; then
    echo "Usage: bash assembler.sh <file.vsc>" >&2
    exit 1 
fi

input_file="$1"

#Check if the input file exists
if [ ! -f "$input_file" ]; then
    echo "Error: input file not found" >&2
    exit 1
fi

case "$input_file" in
    *.vsc)
        ;;
    *)
        echo "Error: input file must be .vsc file" >&2
        exit 1 
        ;;
esac

output_file="${input_file%.vsc}.bin"

to_binary() {
    number=$1
    bits=$2
    binary=""

    for ((j=0; j<bits; j++)); do
        binary="$((number%2))$binary"
        number=$((number/2))
    done

    echo "$binary"
}

write_byte() {
    byte_value=$1
    printf "\\$(printf '%03o' "$byte_value")" >> "$output_file"
}


n_values=$(sed -n '1p' "$input_file")

static_values=()
for ((i=0; i<n_values; i++)); do
    line_number=$((i+2))
    value=$(sed -n "${line_number}p" "$input_file")
    static_values+=("$value")
done


instruction_start=$((n_values +2))

: > "$output_file"

write_byte "$n_values"

for value in "${static_values[@]}"; do
    write_byte "$value"
done


while IFS=',' read -r instruction register address; do
    case "$instruction" in
        LOAD)
            opcode="000001"
            ;;
        STORE)
            opcode="000010"
            ;;
        ADD)
            opcode="000011"
            ;;
        SUB)
            opcode="000100"
            ;;
        QUIT)
            opcode="001000"
            ;;
        PRINT)
            opcode="001001"
            ;;
        *)

            echo "Error: unknown instruction" >&2
            exit 1
            ;;
    esac

    register_binary=$(to_binary "$register" 2) #register field must be 2 bits
    address_binary=$(to_binary "$address" 8) #address must be 8 bits

    first_byte_binary="${opcode}${register_binary}"
    first_byte=$((2#$first_byte_binary))
    second_byte=$((2#$address_binary))

    write_byte "$first_byte"
    write_byte "$second_byte"

done < <(tail -n +"$instruction_start" "$input_file")

