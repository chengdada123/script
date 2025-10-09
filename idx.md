cd /tmp
wget https://www.xiecloud.cn/d/Share/DDSystem/Win10_22H2.vhd.gz

gunzip Win10_22H2.vhd.gz

qemu-img convert -f vpc -O qcow2 Win10_22H2.vhd winsrv2022.qcow2

rm -rf /home/user/vms/*.qcow2

cp winsrv2022.qcow2 /home/user/vms/winsrv2022.qcow2


cd /home/user/vms/

qemu-img resize winsrv2022.qcow2 100G



