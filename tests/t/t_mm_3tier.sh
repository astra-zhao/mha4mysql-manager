. ./init.sh

POS1=`get_binlog_position $S1P`
mysql $M -e "change master to master_host='127.0.0.1', master_port=$S1P, master_user='rsandbox', master_password='rsandbox', master_log_file='mysql-bin.000001', master_log_pos=$POS1; start slave"

mysql $M test -e "insert into t1 values(2, 200, 'aaaaaa')"
sleep 1
mysql $S1 -e "set global read_only=1"
POS2=`get_binlog_position $S1P`
mysql $S2 -e "stop slave"
is_gtid_supported
if test $? = 1
then
mysql $S2 -e "change master to master_host='127.0.0.1', master_port=$S1P, master_user='rsandbox', master_password='rsandbox'"
else
mysql $S2 -e "change master to master_host='127.0.0.1', master_port=$S1P, master_user='rsandbox', master_password='rsandbox', master_log_file='mysql-bin.000001', master_log_pos=$POS2"
fi
mysql $S2 -e "start slave"

check_master $0 $S2P $S1P

masterha_check_repl --conf=$CONF > /dev/null 2>&1
fail_if_zero $0 $?
./run.sh
fail_if_zero $0 $?

./kill_m.sh

masterha_check_repl --conf=$CONF > /dev/null 2>&1
fail_if_zero $0 $?
./run.sh
fail_if_zero $0 $?

masterha_check_repl --conf=mha_test_multi.cnf > /dev/null 2>&1
fail_if_zero $0 $?
./run.sh --conf=mha_test_multi.cnf
fail_if_nonzero $0 $?

check_master $0 $S2P $S1P
mysql $S1 test -e "insert into t1 values(10000003, 300, 'bbbaaaaaaa');"
./check $0 3
