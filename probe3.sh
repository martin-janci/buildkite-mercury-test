df -h / /mnt/sda4 2>&1
findmnt -no SOURCE,FSTYPE,OPTIONS /mnt/sda4 2>&1
ls -ld /mnt/sda4 2>&1
ls -la /mnt/sda4 2>&1 | head -15
for d in /mnt/sda4 /mnt/sda4/buildkite-agent /mnt/sda4/cache; do
  if [ -d "$d" ]; then
    t="$d/.mercury-write-test.$$"
    if touch "$t" 2>/dev/null; then echo "writable: $d"; rm -f "$t"; else echo "NOT writable: $d"; fi
  fi
done
