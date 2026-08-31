import os
import re

def main():
    lib_dir = 'lib'
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if not file.endswith('.dart'):
                continue
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()

            original = content
            
            # Fix const Theme.of
            content = re.sub(r'const\s+([a-zA-Z0-9_]+\([^)]*Theme\.of)', r'\1', content)
            content = re.sub(r'const\s+(Theme\.of)', r'\1', content)
            
            # AppColors issue
            content = content.replace('AppColors.Theme.of(context).colorScheme.surface', 'AppColors.darkPrimaryLight')
            content = content.replace('AppColors.Theme.of(context).primaryColor', 'Color(0xFF0A2314)')

            # Fix CardTheme
            content = content.replace('cardTheme: CardTheme(', 'cardTheme: CardThemeData(')

            if content != original:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Fixed {path}")

if __name__ == '__main__':
    main()
