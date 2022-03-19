if [ -z "\$PAST_DATE" ]
then
    echo "If you want to suppress this input, run 'export PAST_DATE=<PAST_DATE>' on the command line"
    echo -n 'Input PAST_DATE: '
    read -r PAST_DATE
fi
grep -a upgraded /var/log/pacman.log| grep \$PAST_DATE > /tmp/lastupdates.txt                                                              
awk '{print \$4}' /tmp/lastupdates.txt > /tmp/lines1;awk '{print \$5}' /tmp/lastupdates.txt | sed 's/(/-/g' > /tmp/lines2
paste /tmp/lines1 /tmp/lines2 > /tmp/lines
tr -d "[:blank:]" < /tmp/lines > /tmp/packages
cd /var/cache/pacman/pkg/
for i in \$(cat /tmp/packages); do sudo pacman --noconfirm -U "\$i"*; done