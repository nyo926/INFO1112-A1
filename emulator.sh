#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: bach emulator.sh <file.bin>" >&2
    exit 1
fi

input_file="$1"

if [ ! -f "$input_file" ]; then
    echo "Error: input file not found" >&2
    exit 1
fi

case "$input_file" in
    *.bin)
        ;;
    *)
        echo "Error: input file must be .bin file" >&2
        exit 1
        ;;

esac


memory=()
for ((i=0; i<256; i++)); do
    memory[$i]=0
done

registers=(0 0 0 0)

bytes=($(od -An -t u1 -v "$input_file"))

n_values=${bytes[0]}

for ((i=0; i<n_values; i++)); do
    memory[$i]=${bytes[$((i+1))]}
done

file_index=$((n_values + 1))
memory_index=$n_values

while [ "$file_index" -lt "${#bytes[@]}" ]; do
    memory[$memory_index]=${bytes[$file_index]}

    file_index=$((file_index + 1))
    memory_index=$((memory_index + 1))
done

program_counter=$n_values


while true; do

    first_byte=${memory[$program_counter]}
    second_byte=${memory[$((program_counter + 1))]}

    opcode=$((first_byte >> 2))
    register=$((first_byte & 3))
    address=$second_byte

    case "$opcode" in
        1)
            registers[$register]=${memory[$address]}
            ;;
        2)
            memory[$address]=${registers[$register]}
            ;;
        3)
            registers[$register]=$((
                registers[$register] + memory[$address]
            ))
            ;;
        4)
            if [ "${registers[$register]}" -ge "${memory[$address]}" ]; then
                registers[$register]=$((
                    registers[$register] - memory[$address]
                ))
            else
                echo "Error: subtraction would result in a negative value" >&2
            fi
            ;;
        8)
            break
            ;;
        9)
            echo "${registers[$register]}"
            ;;

        *)
            echo "Error: unknown opcoded" >&2
            exit 1
            ;;
    esac

    program_counter=$((program_counter + 2))

done

