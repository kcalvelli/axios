{
  lib,
  pkgs,
  python3Packages,
}:

pkgs.writers.writePython3Bin "icon-cleaner"
  {
    libraries = with python3Packages; [
      rembg
      pillow
    ];
  }
  ''
    import sys
    import os
    from rembg import remove

    if len(sys.argv) < 2:
        print(f"Usage: {os.path.basename(sys.argv[0])} <input_file>")
        sys.exit(1)

    input_path = sys.argv[1]

    # Handle output naming
    if input_path.lower().endswith('.png'):
        output_path = input_path[:-4] + "_clean.png"
    else:
        output_path = input_path + "_clean.png"

    print(f"Removing background from: {input_path}")

    try:
        with open(input_path, 'rb') as i:
            with open(output_path, 'wb') as o:
                input_data = i.read()
                output_data = remove(input_data)
                o.write(output_data)
        print(f"Success: {output_path}")
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
  ''
