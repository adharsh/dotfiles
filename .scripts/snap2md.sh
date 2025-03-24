#!/bin/bash

# Disable glob pattern matching (*, ?, [])
# Example: 'echo *' prints "*" instead of matching files
set -f

# Source the API key file explicitly
[ -f "$HOME/.api_keys" ] && source "$HOME/.api_keys"

# Define the detailed prompt
read -r -d '' PROMPT << EOM
Transcribe the text in the provided image to markdown format, with the following specifications:
- Use standard markdown syntax for headings, lists, bold, italics, etc.
- For mathematical expressions, use KaTeX syntax.
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

echo "Temporary files:"
echo "Image: $TEMP_IMAGE"
echo "Base64: $TEMP_BASE64"
echo "JSON: $TEMP_JSON"

# Take a screenshot of selected area, check exit status and file size
echo "Select the area you want to capture..."
if ! maim -s -f png "$TEMP_IMAGE" || [ ! -s "$TEMP_IMAGE" ]; then
    echo "Failed to capture screenshot or screenshot was cancelled. Aborting."
    rm -f "$TEMP_IMAGE"
    exit 1
fi

# Start timing
start_time=$(date +%s.%N)

# If we get here, we have a valid screenshot. Now copy it to clipboard
# xclip -selection clipboard -t image/png < "$TEMP_IMAGE"

# Encode the image to base64 and save to a file
base64 "$TEMP_IMAGE" > "$TEMP_BASE64"

# Create the JSON payload using jq, reading the base64 image from the file
jq -n \
  --arg model "chatgpt-4o-latest" \
  --arg prompt "$PROMPT" \
  --rawfile image "$TEMP_BASE64" \
  '{
    model: $model,
    messages: [
      {
        role: "user",
        content: [
            {type: "text", text: $prompt},
            {
                type: "image_url", 
                image_url: {
                    url: "data:image/png;base64,\($image)", 
                    "detail": "high"
                }
            }
        ]
      }
    ],
    max_tokens: 4096
  }' > "$TEMP_JSON"

# Send the image to OpenAI API for analysis
RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d @"$TEMP_JSON")

# Clean up temporary files
rm "$TEMP_IMAGE" "$TEMP_BASE64" "$TEMP_JSON"

# Extract the markdown text from API response (glob pattern matching disabled)
MARKDOWN=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')

# Echo the full response for debugging
echo "Full API Response:"
echo "$RESPONSE"

# Copy the markdown to clipboard and print to screen
echo -e "\nExtracted Markdown:"
echo "$MARKDOWN" | tee >(xclip -selection clipboard)

# Calculate elapsed time
end_time=$(date +%s.%N)
elapsed=$(echo "$end_time - $start_time" | bc)
elapsed_rounded=$(printf "%.2f" "$elapsed")

notify-send "Transcription complete (${elapsed_rounded}s)" "Markdown copied to clipboard" -t 3000
