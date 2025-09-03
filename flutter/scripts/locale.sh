

JSON_FOLDER="app/assets/translations"
OUTPUT_FILE="common/lib/src/constants/locale_keys.dart"

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -input) JSON_FOLDER="$2"; shift ;;
    -output) OUTPUT_FILE="$2"; shift ;;
    *) echo "Unknown parameter: $1"; exit 1 ;;
  esac
  shift
done

if [ ! -d "$JSON_FOLDER" ]; then
  echo "Error: Folder not found: $JSON_FOLDER"
  exit 1
fi

to_camel_case() {
  local str="$1"
  str=$(echo "$str" | tr -cs '[:alnum:]' ' ')  
  echo "$str" | tr ' ' '\n' | awk 'NR==1{print tolower($1)} NR>1{print toupper(substr($1,1,1)) substr($1,2)}' | tr -d '\n'
}

TEMP_KEYS_FILE=$(mktemp)

find "$JSON_FOLDER" -type f -name "*.json" | while read -r json_file; do
  
  awk -F'"' '/:/{print $2}' "$json_file" >> "$TEMP_KEYS_FILE"
done

sort -u "$TEMP_KEYS_FILE" > "$TEMP_KEYS_FILE.sorted"

echo "sealed class LocaleKeys {" > "$OUTPUT_FILE"

while read -r key; do
  camel_case_key=$(to_camel_case "$key")
  echo "    static const $camel_case_key = '$key';" >> "$OUTPUT_FILE"
done < "$TEMP_KEYS_FILE.sorted"

cat <<EOL >> "$OUTPUT_FILE"
}
EOL

rm "$TEMP_KEYS_FILE" "$TEMP_KEYS_FILE.sorted"

echo "Locale Keys successfully generated: $OUTPUT_FILE"
exit 0
