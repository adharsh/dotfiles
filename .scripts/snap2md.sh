#!/bin/bash

# Disable glob pattern matching (*, ?, [])
# Example: 'echo *' prints "*" instead of matching files
set -f

# Source the API key file explicitly
# shellcheck source=/dev/null
[ -f "$HOME/.api_keys" ] && source "$HOME/.api_keys"

if [ -z "${OPENAI_API_KEY:-}" ]; then
    message="OPENAI_API_KEY is not set in $HOME/.api_keys"
    echo "$message" >&2
    notify-send "Screenshot transcription failed" "$message" -t 5000
    exit 1
fi

# Define the detailed prompt
read -r -d '' PROMPT << 'EOM'
Transcribe the text in the provided image as is. If and only if there's math, use katex with the following specifications:
- For inline (non-centered) mathematical expressions, use single dollar signs: $...$
- For block (centered) mathematical expressions, use double dollar signs: $$...$$
- When using dollar signs, place entire expression into a single line, examples:
  - $$\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}$$
  - $\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}$
  - NOT like:
    $$
    \text{This is a bad example: }\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}
    $$
- Never use \[ \] or \( \) for math mode. Only use dollar signs as described previously.
- Utilize KaTeX syntax for all mathematical notations
- Only use \dfrac and never \frac
- Output only the transcribed markdown text AS IS, without any additional modifications or explanations, comments, or enclosing ticks
Examples of markdown with KaTeX:
1. Inline math: The equation $E = mc^2$ represents Einstein's mass-energy equivalence.
2. Centered math:
$$\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}$$
3. Mixed markdown and KaTeX:
# Quadratic Formula
The solutions to a quadratic equation $ax^2 + bx + c = 0$ are given by:
$$x = \dfrac{-b \pm \sqrt{b^2 - 4ac}}{2a}$$
Where:
- $a \neq 0$
- The term under the square root ($b^2 - 4ac$) is called the discriminant
EOM

# Create temporary files
TEMP_IMAGE=$(mktemp)
TEMP_BASE64=$(mktemp)
TEMP_JSON=$(mktemp)

cleanup() {
    rm -f -- "$TEMP_IMAGE" "$TEMP_BASE64" "$TEMP_JSON"
}
trap cleanup EXIT

echo "Temporary files:"
echo "Image: $TEMP_IMAGE"
echo "Base64: $TEMP_BASE64"
echo "JSON: $TEMP_JSON"

# Take a screenshot of selected area, check exit status and file size
echo "Select the area you want to capture..."
if ! maim -s --hidecursor -f png "$TEMP_IMAGE" || [ ! -s "$TEMP_IMAGE" ]; then
    echo "Failed to capture screenshot or screenshot was cancelled. Aborting."
    exit 1
fi

# Start timing
start_time=$(date +%s.%N)

# If we get here, we have a valid screenshot. Now copy it to clipboard
# xclip -selection clipboard -t image/png < "$TEMP_IMAGE"

# Encode the image to base64 and save to a file
base64 --wrap=0 "$TEMP_IMAGE" > "$TEMP_BASE64"

# Create the JSON payload using jq, reading the base64 image from the file
jq -n \
  --arg model "gpt-5.6-luna" \
  --arg prompt "$PROMPT" \
  --rawfile image "$TEMP_BASE64" \
  '{
    model: $model,
    reasoning: {effort: "none"},
    service_tier: "fast",
    input: [
      {
        role: "user",
        content: [
          {type: "input_text", text: $prompt},
          {
            type: "input_image",
            image_url: "data:image/png;base64,\($image)",
            detail: "high"
          }
        ]
      }
    ],
    max_output_tokens: 4096
  }' > "$TEMP_JSON"

# Send the image to OpenAI API for analysis
if ! RESPONSE=$(curl --silent --show-error --fail-with-body \
  https://api.openai.com/v1/responses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d @"$TEMP_JSON"); then
    error_message=$(printf '%s' "$RESPONSE" | jq -r '.error.message // empty' 2>/dev/null)
    if [ -z "$error_message" ]; then
        error_message="The OpenAI API request failed; run snap2md.sh in a terminal for details."
    fi
    echo "$error_message" >&2
    notify-send "Screenshot transcription failed" "$error_message" -t 7000
    exit 1
fi

# Responses may contain reasoning or tool items before the assistant message, so
# locate output text by type instead of assuming it is the first output item.
if ! MARKDOWN=$(printf '%s' "$RESPONSE" | jq -er '
  [
    .output[]?
    | select(.type == "message")
    | .content[]?
    | select(.type == "output_text")
    | .text
  ]
  | join("")
  | select(length > 0)
'); then
    error_message=$(printf '%s' "$RESPONSE" | jq -r '
      .error.message
      // ([.output[]?.content[]? | select(.type == "refusal") | .refusal] | join(" ") | select(length > 0))
      // ("The response did not contain transcription text (status: " + (.status // "unknown") + ").")
    ' 2>/dev/null)
    if [ -z "$error_message" ]; then
        error_message="The OpenAI response was not valid JSON."
    fi
    echo "$error_message" >&2
    echo "Full API response:" >&2
    printf '%s\n' "$RESPONSE" >&2
    notify-send "Screenshot transcription failed" "$error_message" -t 7000
    exit 1
fi

# Echo the full response for debugging
echo "Full API Response:"
printf '%s\n' "$RESPONSE"

# Copy the markdown to clipboard and print to screen
echo -e "\nExtracted Markdown:"
printf '%s\n' "$MARKDOWN" | tee >(xclip -selection clipboard)

# Calculate elapsed time
end_time=$(date +%s.%N)
elapsed=$(echo "$end_time - $start_time" | bc)
elapsed_rounded=$(printf "%.2f" "$elapsed")

notify-send "Transcription complete (${elapsed_rounded}s)" "Markdown copied to clipboard" -t 3000
