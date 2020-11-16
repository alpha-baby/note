# docker 启动mysql

>参考 https://blog.csdn.net/zk673820543/article/details/77765428


Docker启动Mysql
-------------

### 一、单机版 Mysql

1. 拉取官方镜像，镜像地址：/mysql/”>https://hub.docker.com//mysql/
2. 拉取镜像：docker pull mysql
3. 准备Mysql数据存放目录，我这里是：/home/ljaer/mysql
4. 执行指令启动Mysql

    ```bash
    docker@default:~$ docker run --name mysql8.0-dev -v /home/ljaer/mysql:/var/lib/mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=123456 -d mysql:8.0
    ```

5. 检查结果

    ```bash
    docker@default:~$ docker ps -a                                
    CONTAINER ID        IMAGE               COMMAND                  CREATED    STATUS                     PORTS                                                                      NAMES
    b781ad5f9ade        mysql:8.0           "docker-entrypoint.s…"   4 minutes ago       Up 4 minutes               0.0.0.0:3306->3306/tcp, 33060/tcp                                          mysql8.0-dev
    ```

    docker@default:~$ cd /home/ljaer/mysql/
    docker@default:/home/ljaer/mysql$ ls
    auto.cnf            client-cert.pem     ib_logfile0         ibtmp1              private_key.pem     server-key.pem
    ca-key.pem          client-key.pem      ib_logfile1         mysql/              public_key.pem      sys/
    ca.pem              ib_buffer_pool      ibdata1             performance_schema/ server-cert.pem

6. 执行指令关闭Mysql

    ```bash
    docker@default:~$ docker stop mysql8.0-dev
    ```

7. 进入容器

    ```bash
    docker exec -it mysql8.0-dev bash
    ```

8. 进入MySQL

    ```bash
    mysql -u root -p
    ```

9. 查看配置文件

    ```bash
    cat /etc/mysql/my.conf
    ```

10. 修改密码加密方式(可选)

    ```bash
    发现登录不了，报错：navicat不支持caching_sha_password加密方式
    原因：mysql8.0使用新的密码加密方式：caching_sha_password
    解决方式：修改成旧的加密方式（mysql_native_password），并重置密码
    * select host,user,plugin from user;
    * alter user 'root'@'%' identified with mysql_native_password by '123456';
    ```

    ![](https://tva1.sinaimg.cn/large/0081Kckwly1gkr627ehy8j30jg0exmyy.jpg)

11. 可以使用navicat 等客户端远程连接上mysql



### 二、 docker 运行 mysql 主从备份，读写分离

#### 参考链接

[docker运行mysql主从备份，读写分离](http://blog.csdn.net/sunlihuo/article/details/54018843)

[mysql主从同步中show master status，结果为空](https://zhidao.baidu.com/question/590653086.html)

[docker mysql 主从配置](http://blog.csdn.net/qq362228416/article/details/48569293)

#### 1、拉取镜像

```bash
docker pull mysql/mysql-server 
```

当前使用的是最新版：5.7

#### 2、设置目录

为了使MySql的数据保持在宿主机上，先建立几个目录

```bash
docker@default:~$ sudo mkdir -pv /home/docker/mysql/data
created directory: '/home/docker/mysql/'
created directory: '/home/docker/mysql/data'
docker@default:~$ sudo mkdir -pv /home/docker/mysql/101
created directory: '/home/docker/mysql/101'
docker@default:~$ sudo mkdir -pv /home/docker/mysql/102
created directory: '/home/docker/mysql/102'
```

#### 3、设置主从服务器配置

```bash
docker@default:~$ sudo vi /home/docker/mysql/101/101.cnf

[mysqld]
log-bin=mysql-bin
server-id=101

docker@default:~$ sudo vi /home/docker/mysql/102/102.cnf

[mysqld]
log-bin=mysql-bin
server-id=102
```
    

#### 4、创建主从服务器容器

```bash
docker@default:~$docker create --name mysqlsrv101 -v /home/docker/mysql/data/mysql101:/var/lib/mysql -v /home/docker/mysql/101:/etc/mysql/conf.d -e MYSQL_ROOT_PASSWORD=123456 -p 3306:3306 mysql:5.7
docker@default:~$docker create --name mysqlsrv102 -v /home/docker/mysql/data/mysql102:/var/lib/mysql -v /home/docker/mysql/102:/etc/mysql/conf.d -e MYSQL_ROOT_PASSWORD=123456 -p 3316:3306 mysql:5.7
```


#### 5、启动容器

```bash
docker@default:~$ docker start mysqlsrv101
mysqlsrv101
docker@default:~$ docker start mysqlsrv102
mysqlsrv102
docker@default:~$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES
54a2a729c11b        mysql:5.7           "docker-entrypoint..."   24 seconds ago      Up 1 second         0.0.0.0:3316->3306/tcp   mysqlsrv102
45dfb1ba4f6b        mysql:5.7           "docker-entrypoint..."   32 seconds ago      Up 7 seconds        0.0.0.0:3306->3306/tcp   mysqlsrv101
```
    

#### 6、登录主服务器的mysql，查询master的状态

```bash
docker@default:~$ docker exec -it 45dfb /bin/bash
root@45dfb1ba4f6b:/# mysql -uroot -p 
Enter password: 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 3
Server version: 5.7.19-log MySQL Community Server (GPL)

Copyright (c) 2000, 2017, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show master status;
+------------------+----------+--------------+------------------+-------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+------------------+----------+--------------+------------------+-------------------+
| mysql-bin.000003 |      154 |              |                  |                   |
+------------------+----------+--------------+------------------+-------------------+
1 row in set (0.00 sec)

mysql> 
```
    

#### 7、主库创建用户

```bash
mysql> SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
Query OK, 0 rows affected (0.00 sec)

mysql> GRANT REPLICATION SLAVE ON *.* to 'backup'@'%' identified by '123456';
Query OK, 0 rows affected, 1 warning (0.00 sec)
```
    

#### 8、登录从服务器的mysql，设置与主服务器相关的配置参数

```bash
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
change master to master_host='192.168.99.100',master_user='backup',master_password='123456',master_log_file='mysql-bin.000003',master_log_pos=154;
```
    

*   master_host为docker的地址不能写127.0.0.1
*   master_user是在主库创建的用户
*   master\_log\_pos是主库show master status;查询出的Position

##### 启动服务

```bash
mysql> start slave;
Query OK, 0 rows affected (0.00 sec)
```

##### 查看服务状态

```bash
    mysql> show slave status \G;
    *************************** 1. row ***************************
                   Slave_IO_State: Waiting for master to send event
                      Master_Host: 192.168.99.100
                      Master_User: backup
                      Master_Port: 3306
                    Connect_Retry: 60
                  Master_Log_File: mysql-bin.000003
              Read_Master_Log_Pos: 724
                   Relay_Log_File: 54a2a729c11b-relay-bin.000002
                    Relay_Log_Pos: 890
            Relay_Master_Log_File: mysql-bin.000003
                 Slave_IO_Running: Yes
                Slave_SQL_Running: Yes
                  Replicate_Do_DB: 
              Replicate_Ignore_DB: 
               Replicate_Do_Table: 
           Replicate_Ignore_Table: 
          Replicate_Wild_Do_Table: 
      Replicate_Wild_Ignore_Table: 
                       Last_Errno: 0
                       Last_Error: 
                     Skip_Counter: 0
              Exec_Master_Log_Pos: 724
                  Relay_Log_Space: 1104
                  Until_Condition: None
                   Until_Log_File: 
                    Until_Log_Pos: 0
               Master_SSL_Allowed: No
               Master_SSL_CA_File: 
               Master_SSL_CA_Path: 
                  Master_SSL_Cert: 
                Master_SSL_Cipher: 
                   Master_SSL_Key: 
            Seconds_Behind_Master: 0
    Master_SSL_Verify_Server_Cert: No
                    Last_IO_Errno: 0
                    Last_IO_Error: 
                   Last_SQL_Errno: 0
                   Last_SQL_Error: 
      Replicate_Ignore_Server_Ids: 
                 Master_Server_Id: 101
                      Master_UUID: 234c1f34-8c63-11e7-8d0c-0242ac110002
                 Master_Info_File: /var/lib/mysql/master.info
                        SQL_Delay: 0
              SQL_Remaining_Delay: NULL
          Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
               Master_Retry_Count: 86400
                      Master_Bind: 
          Last_IO_Error_Timestamp: 
         Last_SQL_Error_Timestamp: 
                   Master_SSL_Crl: 
               Master_SSL_Crlpath: 
               Retrieved_Gtid_Set: 
                Executed_Gtid_Set: 
                    Auto_Position: 0
             Replicate_Rewrite_DB: 
                     Channel_Name: 
               Master_TLS_Version: 
    1 row in set (0.00 sec)
    
    ERROR: 
    No query specified
```
    

Slave\_IO\_State：

Waiting for master to send event 就是成功了

Connecting to master 多半是连接不通

主要参数

```txt
Slave\_IO\_Running: Yes

Slave\_SQL\_Running: Yes
```

之后主库的修改都能同步到从库了