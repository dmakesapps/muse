import os
import json
import sys

base_dir = "/Users/davis/Desktop/MUSE/Muse/Muse/Assets.xcassets"

def check_assets(directory):
    for root, dirs, files in os.walk(directory):
        if "Contents.json" in files:
            json_path = os.path.join(root, "Contents.json")
            try:
                with open(json_path, 'r') as f:
                    data = json.load(f)
                
                if "images" in data:
                    for img in data["images"]:
                        if "filename" in img:
                            img_path = os.path.join(root, img["filename"])
                            if not os.path.exists(img_path):
                                print(f"ERROR: Image missing: {img_path}")
                            else:
                                size = os.path.getsize(img_path)
                                if size == 0:
                                    print(f"ERROR: Image empty (0 bytes): {img_path}")
                                # else:
                                #     print(f"OK: {img_path} ({size} bytes)")
                
                if "colors" in data:
                    pass # Colors usually don't have filenames unless complex pattern
                    
            except json.JSONDecodeError:
                print(f"ERROR: Invalid JSON in {json_path}")
            except Exception as e:
                print(f"ERROR: reading {json_path}: {e}")

check_assets(base_dir)
print("Verification complete.")
