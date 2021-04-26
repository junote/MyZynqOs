pushd $CONFIGS_DIR

if [ -f uscript.txt ]
then
    cp uscript.txt $IMAGES_DIR
else
    echo "uscript not exist in config_dir"
    exit 1
fi
popd
pushd $IMAGES_DIR
touch tmp
echo "echo \"create at $(date "+%Y%m%d%H%M%S")\"">tmp
cat uscript.txt>>tmp
mkimage -T script -C none -n "uscript 1" -d tmp uscript.bin
rm tmp
rm uscript.txt
popd