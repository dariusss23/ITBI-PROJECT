#!/bin/bash
 
usage() {
    echo "Utilizare: $0 [opțiuni]"
    echo "Opțiuni:"
    echo "  -o OUTPUT   Specifică fișierul de ieșire pentru raport"
    echo "  -t FILE1 FILE2 Analizează diferențele între două fișiere typescript"
    echo "  -c FILE     Compară un fișier typescript cu starea curentă"
    echo "  -h          Afișează acest mesaj de ajutor"
    exit 1
}
 
DIR="."
OUTPUT="raport.txt"
 
while getopts ":s:o:t:c:h" opt; do
    case $opt in
        o) OUTPUT="$OPTARG" ;;
        t) 
            FILE1="$OPTARG"
            shift $((OPTIND - 1))
            FILE2="$1"
            shift
            ;;
        c) FILE1="$OPTARG"; COMPARE_CURRENT=1 ;;
        h) usage ;;
        *) echo "Opțiune necunoscută: $OPTARG"; usage ;;
    esac
done
shift $((OPTIND - 1))
 
generate_ls_snapshot() {
    local dir="$1"
    ls -l --time-style=long-iso "$dir" | awk '{print $1, $2, $3, $4, $5, $6, $7, $8, $9}' | sort > "$2"
}
 
analyze_disk_usage() {
    local file1="$1"
    local file2="$2"
    local output="$3"
 
    echo "Analiza utilizării spațiului pe disc:" >> "$output"
    echo "-------------------------------------" >> "$output"
 
    disk_file1=$(grep -A 1 "du -b" "$FILE1" | tail -n 1 | awk '{print $1}')
    disk_file2=$(grep -A 1 "du -b" "$FILE2" | tail -n 1 | awk '{print $1}')
 
    echo "$disk_file1 bytes in prima sesiune" >> "$output"
    echo "$disk_file2 bytes in a doua sesiune" >> "$output"
}
 
 
analyze_typescript_diff() {
    local file1="$1"
    local file2="$2"
    local output="$3"
 
    echo "Generare raport..." > "$output"
 
    grep -E "^(-|d)" "$file1" | awk '{print $9}' | sort > /tmp/files1.txt
    grep -E "^(-|d)" "$file2" | awk '{print $9}' | sort > /tmp/files2.txt
 
    comm -23 /tmp/files1.txt /tmp/files2.txt > /tmp/deleted_files.txt
    comm -13 /tmp/files1.txt /tmp/files2.txt > /tmp/added_files.txt
 
    if [[ -s /tmp/deleted_files.txt ]]; then
        echo "Fișiere șterse:" >> "$output"
        while read -r line; do
            echo "  - $line" >> "$output"
        done < /tmp/deleted_files.txt
    fi
 
    if [[ -s /tmp/added_files.txt ]]; then
        echo "Fișiere adăugate:" >> "$output"
        while read -r line; do
            echo "  + $line" >> "$output"
        done < /tmp/added_files.txt
    fi
 
    analyze_disk_usage "$file1" "$file2" "$output"
 
    echo "Raport generat în $output"
}
 
 
if [[ -n "$FILE1" && -n "$FILE2" ]]; then
    analyze_typescript_diff "$FILE1" "$FILE2" "$OUTPUT"
    exit 0
fi
 
extract_and_sort_typescript() {
    local input_file="$1"
    local output_file="$2"
 
    grep -E "^(-|d)" "$input_file" | awk '{print $9}' | tr -d '\r' | sort > "$output_file"
}
 
generate_and_sort_current() {
    local dir="$1"
    local output_file="$2"
 
    ls -l "$dir" | grep -E "^(-|d)" | awk '{print $9}' | tr -d '\r' | sort > "$output_file"
}
 
compare_with_current_state() {
    local typescript_file="$1"
    local dir="$2"
    local output="$3"
 
    echo "Generare raport..." > "$output"
 
    extract_and_sort_typescript "$typescript_file" /tmp/saved_files.txt
 
    generate_and_sort_current "$dir" /tmp/current_files.txt
 
    echo "Analiza modificărilor față de snapshot-ul salvat:" >> "$output"
    echo "-----------------------------------------------" >> "$output"
 
    comm -23 /tmp/saved_files.txt /tmp/current_files.txt > /tmp/deleted_files.txt
    comm -13 /tmp/saved_files.txt /tmp/current_files.txt > /tmp/added_files.txt
 
    if [[ -s /tmp/deleted_files.txt ]]; then
        echo "Fișiere șterse:" >> "$output"
        while read -r line; do
            echo "  - $line" >> "$output"
        done < /tmp/deleted_files.txt
    fi
 
    if [[ -s /tmp/added_files.txt ]]; then
        echo "Fișiere adăugate:" >> "$output"
        while read -r line; do
            echo "  + $line" >> "$output"
        done < /tmp/added_files.txt
    fi
 
    echo "-----------------------------------------------" >> "$output"
    echo "Analiza utilizării spațiului pe disc:" >> "$output"
    du -sb "$dir" | awk '{print "Dimensiunea curentă a directorului: "$1" bytes"}' >> "$output"
 
    echo "Raport generat în $output"
}
 
if [[ -n "$COMPARE_CURRENT" ]]; then
    compare_with_current_state "$FILE1" "$DIR" "$OUTPUT"
    exit 0
fi
 
usage
