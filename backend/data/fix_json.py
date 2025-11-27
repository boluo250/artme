import json
import os

file_path = 'artme/backend/data/AI_Draw_Prompts_EN.json'

if not os.path.exists(file_path):
    print(f"File not found: {file_path}")
    exit(1)

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the known issue: unescaped quotes inside a string
# "prompt": "... (yellow "POLICE" badge printed on chest) ..."
fixed_content = content.replace('(yellow "POLICE" badge', '(yellow \\"POLICE\\" badge')

try:
    data = json.loads(fixed_content)
    # If successful, write back formatted with 2 spaces indentation
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        # Add a newline at EOF
        f.write('\n')
    print("Successfully formatted JSON.")
except json.JSONDecodeError as e:
    print(f"Error parsing JSON: {e}")
    # Print context around error
    lines = fixed_content.splitlines()
    if e.lineno <= len(lines):
        print(f"Line {e.lineno}: {lines[e.lineno-1]}")

