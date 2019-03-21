#!/usr/local/bin/php -q
<?php

function WriteToDB($packet, $peer){

// Setting-up MySQL connection
$db_addres = 'DB_ADRES'; // Адрес Баззы данных
$db_user = 'DB_USER'; //Пользователь Базы данных
$db_password = 'DB_PASSWORD'; //Пароль пользоватлея Базы данных
$db_name = 'DB_NAME'; //Навзание Баззы данных движка
$tb_name = 'TABLE_NAME'; // Название таблицы движка

// Connecting and selecting db and table, also switching to unicode mode.
$link = mysqli_connect($db_addres, $db_user, $db_password);
mysqli_select_db($link, $db_name);
mysqli_query($link, "SET sql_mode = ''");
mysqli_query($link, 'SET NAMES utf8');    
    
$port_data = explode(':', $packet);

$rq = "SELECT * FROM ".$tb_name." WHERE host='".$peer."' AND proto='".$port_data[1]."' AND port=".$port_data[2];
$sql = mysqli_query($link, $rq);
if ($sql == TRUE) {
    if ( mysqli_num_rows($sql) > 0 ){
        $rq = "UPDATE ".$tb_name." SET state=".$port_data[3]." WHERE host='".$peer."' AND proto='".$port_data[1]."' AND port=".$port_data[2];        
    } else {
        $rq = "INSERT INTO ".$tb_name." (host, proto, port, state) VALUES ('".$peer."', '".$port_data[1]."', ".$port_data[2].", ".$port_data[3].");";
    }
    $sql = mysqli_query($link, $rq);
}

return mysqli_error($link);

/* close connection */
mysqli_close($link);

    
}


error_reporting(E_ALL);

/* Allow the script to hang around waiting for connections. */
set_time_limit(0);

/* Turn on implicit output flushing so we see what we're getting as it comes in. */
ob_implicit_flush();

$address = '0.0.0.0';
$port = 10001;

// Creating listener socket
if (($sock = socket_create(AF_INET, SOCK_STREAM, SOL_TCP)) === false) {
    echo "socket_create() failed: reason: " . socket_strerror(socket_last_error()) . "\n";
}

// Bindidng listner socket to designited ip and port
if (socket_bind($sock, $address, $port) === false) {
    echo "socket_bind() failed: reason: " . socket_strerror(socket_last_error($sock)) . "\n";
}

// Starting to listen for incommeng connections
if (socket_listen($sock, 5) === false) {
    echo "socket_listen() failed: reason: " . socket_strerror(socket_last_error($sock)) . "\n";
}

// Message for server side.
echo "Server Dispatcher listener..OK.\n";
echo "To quit, send 'quit'.\n";
echo "To shut down, send 'shutdown'.\n";

// Strating 1st loop,
// able to catch incomming connection
// and create second (sender) socket, to talkback with client
do {
    if (($msgsock = socket_accept($sock)) === false) {
        echo "socket_accept() failed: reason: " . socket_strerror(socket_last_error($sock)) . "\n";
        break;
    }
    /* Send something to client,
    (before listening for commands),
    for example: instructions. */  

    // This loop will read entire messgae from client,
    // talkback/report/do_other_things if nedded.
    do {	
		
        if (false === ($buf = socket_read($msgsock, 2048, PHP_NORMAL_READ))) {
            
            // Something wrong happen.
            // Reporting and breaking connection with client
            echo "PHP: Connection crashed.\n";
            echo "Reason: " . socket_strerror(socket_last_error($msgsock)) . "\n";
            break;
        } 
		
		// trim -removes spaces and other trash from both sides of string		
		if (!$buf = trim($buf)) {		
			// After trim, we have empty string!
            continue; // Ok, skip this cycle iteration!
        } 
		
        if ($buf == 'quit') {
            
            echo "Client disconnected.\n";
            break; // Clien connection break
        } 
		
        if ($buf == 'shutdown') {
            
            echo "Server down, by admin.\n";            
            socket_close($msgsock); // reciver socket close
            break 2; // break both sender and listener sockets
        } 
        
        if ( stripos($buf, 'SRV_DATA:') !== FALSE ){
			
			$peer = '127.0.0.1';
			$peer_res = FALSE;
            
            // Let's find out it's external ip
            $peer_res = socket_getpeername($msgsock, $peer);	
            
            $talkback = "Got your data... Thanks! \n";
			if ($peer_res){
				echo "Got info from $peer: $buf \n";
			} else {
				echo "Got anonymous info: $buf \n";
			}
            echo "Recording to DB ... ";
            
            $DBResponse = WriteToDB($buf, $peer);
            if ($DBResponse == ''){
                echo "OK! \n";
            } else {
                echo "DB_ERR: ".$DBResponse." \n";
            }

        } else {
            
            $talkback = "Quit spamming me, or you'll be banned! \n";
            echo "Got TRASH from $peer! \n";
			
        }        
                
        socket_write($msgsock, $talkback, strlen($talkback));   
        
    } while (true);
    socket_close($msgsock);
} while (true);
socket_close($sock);
?>