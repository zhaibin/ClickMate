#!/usr/bin/env python3
"""
Generate icon files from source icon.png
Creates multiple sizes and ICO file for Windows (including high-DPI support)
"""

from PIL import Image
import os
import sys
import struct
import io

def create_ico_with_all_sizes(images, output_path):
    """
    Create ICO file with multiple image sizes properly embedded.
    images: list of PIL Image objects, should be in RGBA mode
    """
    # ICO header: 2 bytes reserved, 2 bytes type (1=icon), 2 bytes count
    ico_header = struct.pack('<HHH', 0, 1, len(images))
    
    # Prepare image data
    image_data_list = []
    for img in images:
        # Convert to PNG format for each size
        png_buffer = io.BytesIO()
        img.save(png_buffer, format='PNG')
        image_data_list.append(png_buffer.getvalue())
    
    # Calculate offsets
    # Header is 6 bytes, each directory entry is 16 bytes
    current_offset = 6 + (16 * len(images))
    
    directory_entries = []
    for i, img in enumerate(images):
        width = img.size[0] if img.size[0] < 256 else 0  # 0 means 256
        height = img.size[1] if img.size[1] < 256 else 0
        
        data_size = len(image_data_list[i])
        
        # Directory entry: width, height, colors, reserved, planes, bpp, size, offset
        entry = struct.pack('<BBBBHHII', 
            width,      # width (0 = 256)
            height,     # height (0 = 256)
            0,          # color palette (0 = no palette)
            0,          # reserved
            1,          # color planes
            32,         # bits per pixel
            data_size,  # size of image data
            current_offset  # offset to image data
        )
        directory_entries.append(entry)
        current_offset += data_size
    
    # Write ICO file
    with open(output_path, 'wb') as f:
        f.write(ico_header)
        for entry in directory_entries:
            f.write(entry)
        for data in image_data_list:
            f.write(data)
    
    return True

def generate_icons():
    """Generate icon files from icon.png"""
    
    # Get project root directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    
    # Source and destination paths
    assets_icons_dir = os.path.join(project_root, 'assets', 'icons')
    source_icon = os.path.join(assets_icons_dir, 'icon.png')
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
        
        print(f"[INFO] Original image size: {img.size}")
        
        # Make image square (use the larger dimension)
        width, height = img.size
        if width != height:
            max_dim = max(width, height)
            # Create a new square image with transparent background
            square_img = Image.new('RGBA', (max_dim, max_dim), (0, 0, 0, 0))
            # Paste the original image centered
            offset_x = (max_dim - width) // 2
            offset_y = (max_dim - height) // 2
            square_img.paste(img, (offset_x, offset_y))
            img = square_img
            print(f"[INFO] Converted to square: {img.size}")
        
        # Create Windows resources directory if needed
        os.makedirs(windows_runner_resources, exist_ok=True)
        
        # ICO sizes for high-DPI support (sorted from smallest to largest)
        ico_sizes = [16, 24, 32, 48, 64, 128, 256]
        ico_images = []
        
        for size in ico_sizes:
            resized = img.resize((size, size), Image.Resampling.LANCZOS)
            ico_images.append(resized)
        
        # Generate ICO file using custom function for proper multi-size support
        ico_path = os.path.join(windows_runner_resources, 'app_icon.ico')
        create_ico_with_all_sizes(ico_images, ico_path)
        
        # Verify ICO file size
        ico_size = os.path.getsize(ico_path)
        print(f"[OK] Generated ICO with sizes: {ico_sizes}")
        print(f"     Path: {ico_path}")
        print(f"     File size: {ico_size / 1024:.1f} KB")
        
        # Generate individual PNG files for different sizes
        sizes_to_generate = [16, 24, 32, 48, 64, 128, 256, 512]
        
        for size in sizes_to_generate:
            filename = f'icon_{size}.png'
            resized = img.resize((size, size), Image.Resampling.LANCZOS)
            output_path = os.path.join(assets_icons_dir, filename)
            resized.save(output_path, 'PNG', optimize=True)
            print(f"[OK] Generated: {filename} ({size}x{size})")
        
        print("\n" + "=" * 50)
        print("[SUCCESS] All icon files generated successfully!")
        print("=" * 50)
        print(f"\nWindows ICO: {ico_path}")
        print(f"  - Contains sizes: {', '.join(map(str, ico_sizes))}")
        print(f"  - File size: {ico_size / 1024:.1f} KB")
        print(f"\nPNG files: {assets_icons_dir}/")
        print(f"  - icon_16.png to icon_512.png")
        print("\n[!] Rebuild the application for changes to take effect:")
        print("    flutter clean && flutter build windows --release")
        
        return True
        
    except Exception as e:
        print(f"[ERROR] Failed to generate icons: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == '__main__':
    success = generate_icons()
    sys.exit(0 if success else 1)
