#!/usr/bin/env python3
import os
from pathlib import Path

# --- CONFIGURATION ---
# Add or remove folders you want the script to completely ignore
IGNORED_DIRS = {'.git', 'node_modules', 'venv', '__pycache__', 'dist', 'build', '.idea', '.vscode'}
# Add the specific configuration files you want to catch and include
TARGET_CONFIGS = {'docker-compose.yml', 'package.json', 'requirements.txt', 'README.md'}

def generate_tree(dir_path, prefix=""):
    """Generates a text-based directory tree while ignoring specified folders."""
    tree_str = ""
    try:
        paths = sorted(list(Path(dir_path).iterdir()), key=lambda p: (p.is_file(), p.name.lower()))
    except Exception as e:
        return f"{prefix}[Error reading directory: {str(e)}]\n"

    paths = [p for p in paths if p.name not in IGNORED_DIRS]
    
    for i, path in enumerate(paths):
        is_last = (i == len(paths) - 1)
        connector = "└── " if is_last else "├── "
        
        if path.is_dir():
            tree_str += f"{prefix}{connector}{path.name}/\n"
            extension_prefix = "    " if is_last else "│   "
            tree_str += generate_tree(path, prefix + extension_prefix)
        else:
            tree_str += f"{prefix}{connector}{path.name}\n"
            
    return tree_str

def gather_critical_files(root_path):
    """Searches for target configuration files and returns their content wrapped in markdown."""
    gathered_content = ""
    
    for root, dirs, files in os.walk(root_path):
        # Modify dirs in-place to skip ignored directories
        dirs[:] = [d for d in dirs if d not in IGNORED_DIRS]
        
        for file in files:
            if file in TARGET_CONFIGS:
                file_path = Path(root) / file
                try:
                    relative_path = file_path.relative_to(root_path)
                except Exception:
                    relative_path = file_path
                
                # Determine language for markdown syntax highlighting
                lang = "yaml" if file.endswith(('.yml', '.yaml')) else "json" if file.endswith('.json') else "text"
                if file == "README.md": lang = "markdown"
                
                gathered_content += "\n### File: " + str(relative_path) + "\n"
                gathered_content += "```" + lang + "\n"
                try:
                    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                        gathered_content += f.read()
                except Exception as e:
                    gathered_content += f"[Error reading file: {str(e)}]"
                gathered_content += "\n```\n"
                
    return gathered_content

def main():
    root_dir = os.getcwd()
    output_filename = "repo_audit_packet.md"
    
    print("🚀 Initializing repository automation scan...")
    
    # 1. Generate Tree
    print("📁 Mapping repository file tree...")
    repo_tree = generate_tree(root_dir)
    
    # 2. Gather Configuration files
    print("📄 Extracting target build configurations and manifests...")
    manifest_contents = gather_critical_files(root_dir)
    
    # 3. Compile Master Packet using bulletproof string encapsulation
    print(f"✍️ Compiling master audit packet into {output_filename}...")
    
    packet_template = "# REPOSITORY ARCHITECTURAL AUDIT PACKET\n"
    packet_template += "Generated automatically for End-to-End LLM Evaluation.\n\n"
    packet_template += "## 1. REPOSITORY DIRECTORY TREE LAYOUT\n"
    packet_template += "```text\n.\n" + repo_tree + "```\n\n"
    packet_template += "## 2. CENTRAL BUILD MANIFESTS & INFRASTRUCTURE CONFIGS\n" + manifest_contents
    
    try:
        with open(output_filename, "w", encoding="utf-8") as out_file:
            out_file.write(packet_template)
        print(f"✅ Success! Your packet is ready at: {os.path.join(root_dir, output_filename)}")
    except Exception as e:
        print(f"❌ Failed to write file: {str(e)}")

if __name__ == "__main__":
    main()
