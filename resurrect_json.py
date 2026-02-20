
import os
import shutil

ROOT_DIR = "."

def resurrect(path):
    print(f"Resurrecting {path}...")
    try:
        with open(path, 'r') as f:
            content = f.read()
            
        os.remove(path)
        with open(path, 'w') as f:
            f.write(content)
        
        print(f"  -> SUCCESS ({len(content)} bytes)")
        
    except Exception as e:
        print(f"  -> FAIL: {e}")

for root, dirs, files in os.walk(ROOT_DIR):
    for file in files:
        if file == "Contents.json":
            resurrect(os.path.join(root, file))

print("Resurrection complete.")
