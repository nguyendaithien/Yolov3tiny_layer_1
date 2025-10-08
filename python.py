input_file = "wgt.txt"
out_bin_file = "output_256b.txt"
out_sv_file  = "lut.sv"
group_size = 16

vals = []
with open(input_file, "r") as f:
    for line in f:
        s = line.strip()
        if not s:
            continue
        parts = s.split()
        token = parts[-1]
        token = token.strip()
        if all(c in "01" for c in token):
            vals.append(token)

# Check width consistency
widths = [len(v) for v in vals] if vals else [16]
data_width = widths[0]
if any(w != data_width for w in widths):
    data_width = max(widths)
    vals = [v.zfill(data_width) for v in vals]

chunks = []
i = 0
while i < len(vals):
    chunk_vals = vals[i:i+group_size]
    if len(chunk_vals) < group_size:
        pad = ["0"*data_width] * (group_size - len(chunk_vals))
        chunk_vals = chunk_vals + pad
    # Reverse order (MSB <= LSB)
    concatenated = "".join(chunk_vals[::-1])
    chunks.append(concatenated)
    i += group_size

with open(out_bin_file, "w") as f:
    for c in chunks:
        f.write(c + "\n")

with open(out_sv_file, "w") as f:
    f.write("// generated case lines: address -> 256'bdata\n")
    for idx, c in enumerate(chunks):
        f.write(f"    32'd{idx} : data_out = 256'b{c};\n")

print(f"Input entries = {len(vals)}")
print(f"Group size = {group_size}")
print(f"Output lines = {len(chunks)}")
print(f"Wrote: {out_bin_file}, {out_sv_file}")

