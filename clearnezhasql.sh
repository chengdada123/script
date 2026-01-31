#!/bin/bash
db_file1="/opt/nezha/dashboard/data/sqlite.db"
db_file2="/opt/nezha/dashboard_v0/data/sqlite.db"

if [ ! -f "$db_file1" ]; then
    echo "数据库文件 $db_file1 不存在"
    exit 1
fi


if [ ! -f "$db_file2" ]; then
    echo "数据库文件 $db_file2 不存在"
    exit 1
fi

sqlite3 "$db_file1" <<EOF
DELETE FROM service_histories;
VACUUM; -- 清理数据库以释放空间
EOF
echo "已成功清空 service_histories 表的数据"
curl -s -X POST https://api.telegram.org/XXXXXXXXXXXXX/sendMessage \
 -F chat_id='XXXXXXX' -F text='[已成功清空 service_histories 表的数据] 哪吒面板清理完成NZ'
sqlite3 "$db_file2" <<EOF
DELETE FROM monitor_histories;
VACUUM; -- 清理数据库以释放空间
EOF


echo "已成功清空 monitor_histories 表的数据"
curl -s -X POST https://api.telegram.org/XXXXXXXXXX/sendMessage \
 -F chat_id='XXXXXXXXXX' -F text='[已成功清空 monitor_histories 表的数据] 哪吒面板清理完成Server Status'
