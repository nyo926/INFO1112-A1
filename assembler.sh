#!/bin/bash

if [ "$#" -eq 0 ]; then
    echo "usage: no argument is provided"
    exit 1
fi

if [ "$#" -gt 1 ]; then
    echo "usage: more than one arguments are provided"
    exit 1
fi

input_file="$1"

if [ -e "$input_file" ] && [ ! -f "$input_file" ]; then
    echo "usage: input is not a file or it does not exist"
    exit 1
fi

case "$input_file" in
    *.vsc)
        ;;
    *)
        echo "usage: input does not have the extension .vsc"
        exit 1
        ;;
esac

if [ ! -f "$input_file" ]; then
    echo "usage: input is not a file or it does not exist"
    exit 1
fi

output_file="${input_file%.vsc}.bin"

if [ ! -s "$input_file" ]; then
    rm -f "$output_file"
    echo "usage: the file is empty – no .bin file is produced"
    exit 1
fi


write_byte() {
    value=$1
    printf "\\$(printf '%03o' "$value")" >> "$output_file"
}


# Remove CR in case the provided file uses Windows line endings
n_values=$(sed -n '1p' "$input_file" | tr -d '\r')

static_values=()

for ((i=0; i<n_values; i++)); do
    line_number=$((i + 2))
    value=$(sed -n "${line_number}p" "$input_file" | tr -d '\r')
    static_values+=("$value")
done

instruction_start=$((n_values + 2))


: > "$output_file"

for value in "${static_values[@]}"; do
    write_byte "$value"
done


program_type="QUIT"

while IFS=',' read -r instruction register address || [ -n "$instruction" ]; do

    [ -z "$instruction" ] && continue

    case "$instruction" in
        LOAD)
            opcode=1
            ;;
        STORE)
            opcode=2
            ;;
        ADD)
            opcode=3
            program_type="ADD/SUB"
            ;;
        SUB)
            opcode=4
            program_type="ADD/SUB"
            ;;
        QUIT)
            opcode=8
            ;;
        PRINT)
            opcode=9
            ;;
        *)
            echo "Error: unknown instruction"
            rm -f "$output_file"
            exit 1
            ;;
    esac

    first_byte=$((opcode * 4 + register))
    second_byte=$address

    write_byte "$first_byte"
    write_byte "$second_byte"

done < <(tail -n +"$instruction_start" "$input_file" | tr -d '\r')


if [ "$program_type" = "QUIT" ]; then
    echo "It is a QUIT program"
else
    echo "It is an ADD/SUB program"
fi

echo "The content of the .bin file is"

od -An -tx1 -v "$output_file" | tr -s ' ' '\n' | sed '/^$/d'

exit 0