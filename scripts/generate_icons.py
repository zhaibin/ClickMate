#!/usr/bin/env python3
"""
Generate icon files from source icon.png
Creates multiple sizes and ICO file for Windows
"""

from PIL import Image
import os
import sys

def generate_icons():
    """Generate icon files from icon.png"""
    
    # Get project root directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    
    # Source and destination paths
    source_icon = os.path.join(project_root, 'icon.png')
    windows_runner_resources = os.path.join(project_root, 'windows', 'runner', 'resources')
    
    if not os.path.exists(source_icon):
        print(f"[ERROR] Source icon not found: {source_icon}")
        return False
    
    print(f"[INFO] Loading source icon: {source_icon}")
    
    try:
        # Load source image
        img = Image.open(source_icon)
        
        # Ensure RGBA mode
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        print(f"[INFO] Source image size: {img.size}")
        
        # Create Windows resources directory if needed
        os.makedirs(windows_runner_resources, exist_ok=True)
        
        # Generate ICO file with multiple sizes (16, 32, 48, 64, 128, 256)
        ico_sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
        ico_images = []
        
        for size in ico_sizes:
            resized = img.resize(size, Image.Resampling.LANCZOS)
            ico_images.append(resized)
        
        # Save as ICO
        ico_path = os.path.join(windows_runner_resources, 'app_icon.ico')
        ico_images[0].save(
            ico_path,
            format='ICO',
            sizes=ico_sizes
        )
        print(f"[OK] Generated: {ico_path}")
        
        # Generate individual PNG files for different sizes
        sizes_to_generate = {
            'icon_16.png': (16, 16),
            'icon_32.png': (32, 32),
            'icon_48.png': (48, 48),
            'icon_64.png': (64, 64),
            'icon_128.png': (128, 128),
            'icon_256.png': (256, 256),
        }
        
        for filename, size in sizes_to_generate.items():
            resized = img.resize(size, Image.Resampling.LANCZOS)
            output_path = os.path.join(project_root, filename)
            resized.save(output_path, 'PNG')
            print(f"[OK] Generated: {output_path}")
        
        print("\n[SUCCESS] All icon files generated successfully!")
        print(f"  - ICO file: {ico_path}")
        print(f"  - PNG files: {project_root}/icon_*.png")
        
        return True
        
    except Exception as e:
        print(f"[ERROR] Failed to generate icons: {e}")
        return False

if __name__ == '__main__':
    success = generate_icons()
    sys.exit(0 if success else 1)

