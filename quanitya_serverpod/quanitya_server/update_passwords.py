#!/usr/bin/env python3

import yaml
import os

def extract_passwords_from_yaml(passwords_file):
    """Extract passwords from Serverpod's generated passwords.yaml file."""
    with open(passwords_file, 'r') as f:
        data = yaml.safe_load(f)
    
    return {
        'DEV_DB_PASSWORD': data['development']['database'],
        'DEV_REDIS_PASSWORD': data['development']['redis'],
        'TEST_DB_PASSWORD': data['test']['database'],
        'TEST_REDIS_PASSWORD': data['test']['redis']
    }

def replace_placeholders_in_file(file_path, passwords):
    """Replace password placeholders in a file."""
    if not os.path.exists(file_path):
        print(f"❌ File not found: {file_path}")
        return False
    
    # Read original content
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Replace placeholders
    original_content = content
    for placeholder, password in passwords.items():
        placeholder_pattern = '{{' + placeholder + '}}'
        content = content.replace(placeholder_pattern, password)
    
    # Write back if changes were made
    if content != original_content:
        with open(file_path, 'w') as f:
            f.write(content)
        print(f"✅ Updated {file_path}")
        return True
    else:
        print(f"ℹ️  No changes needed for {file_path}")
        return True

def main():
    try:
        # Extract passwords from generated passwords.yaml
        passwords = extract_passwords_from_yaml('config/passwords.yaml')
        print(f"🔑 Loaded passwords: {list(passwords.keys())}")
        
        # Update files
        files_to_update = [
            'docker-compose.yaml',
            'powersync_setup.sql', 
            'verify_powersync_setup.sh'
        ]
        
        for file_path in files_to_update:
            print(f"📝 Processing {file_path}...")
            replace_placeholders_in_file(file_path, passwords)
        
        print("🔐 Password configuration complete!")
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    main()