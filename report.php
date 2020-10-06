<?php

    // SEND:http://www.setipcam.com/device/report.php?mac=m1afe34dea734&op=bcc10a79da627c9067b3c8b8c4323910

    // change next, report to web!
    // $web_report = "http://www.setipcam.com/device/report.php";

    $mac = $_GET["id"];
    if ($_GET["mac"] != "")
        $mac = $_GET["mac"];
    
    //$id  = $_GET["id"];
    $data  = $_GET["data"];
    
    if ($data != "") {
        
        //echo "dara=$data<br>";
        // [帧头_城市区号,序列号(SN),版本号,数据长度,数据项,帧尾]
        // [0755,00001,10,43,652,23,85,25,562,276,36,-,-,-,-,-,-,-,-]
        // [00493,54321,10,44,2240,3452,1500,13,537,276,16,-,-,-,-,-,-,-,-]
        // oz5dmOjei50WHRC4WF96rGa9MqDZGpAiU0Bk7n8aetZgmhELZ9/3B81FcQNdcMEvAc8tbcu6mzCLs7wISPp6wumXllb0GxtKHb8ypkB/5Y0=
        /*
         $rr[4] = 数据 1:CO2(ppm)     = 数据 1
         $rr[5] = 数据 2:VOC(ug/m3)   = 数据 2
         $rr[6] = 数据 3:HCHO(ug/m3)  = 数据 3
         $rr[7] = 数据 4:PM2.5(ug/m3) = 数据 4
         $rr[8] = 数据 5:湿度(%RH)     = 数据 5 / 10.0
         $rr[9] = 数据 6:温度(°C)      = 数据 6 / 10.0
         $rr[X] = 数据 7:PM10(ug/m3)  = 数据 7
         */
        
        // Note our use of ===.  Simply == would not work as expected
        // because the position of 'a' was the 0th (first) character.
        
        $data = str_replace(" ","+", $data);  // " " --> "+"

        $file = "/home/air/_add";
        file_put_contents($file, "---------------\n", FILE_APPEND | LOCK_EX);
        file_put_contents($file, date("F j, Y, g:i a")."--".$data."\n", FILE_APPEND | LOCK_EX);

        if (strpos($data, ",") === false) {
            
            $aes128Key = "f8695969973cfefc";    // substr(bin2hex(MD5("ALOHA$!*&Hello")), 0, 15)
                      // "3efc627fcb4780be";
            
            $str = mcrypt_decrypt(MCRYPT_RIJNDAEL_128, $aes128Key, base64_decode($data), MCRYPT_MODE_ECB);
            //echo "STR:[$data]<br>DEC:[$str]<br>";
            
            if ($str == "")
                $str = openssl_decrypt($data, "AES-128-ECB", $aes128Key);

            $data = $str;

            file_put_contents($file, date("F j, Y, g:i a")."--".$data."\n", FILE_APPEND | LOCK_EX);
        }
        
        $rr = explode(",", $data);
        //$id = $rr[1];
        //if ($id == "54321")
        if (intval($rr[0]) > 1533802500)
            $id = $rr[1];
        else
            $id = substr($rr[0],1);

//echo "ID: [$id]<br>";

if ($id == "")
    $id = "TEST";
        
        
        $path  = "/home/air/n$id";
//echo "id=$id<br>path=$path<br>";
        /*
        if (! file_exists($path)) {
            echo "zz";
            exit;
        }
         */
mkdir($path);

        $file  = $path."/6in1";
        $setfile = fopen($file, "w") or die("Unable to open file $file !");
        fwrite($setfile, $data);
        fclose($setfile);
        
//      echo "OK";
        echo "OK-".time();
//      echo "[OK-".time()."-15]";
        exit;
    }

    if (strstr($mac, "m"))
        $mac  = substr($mac, 1);
    
    // 16 byte binary blob
    $aes128Key = bin2hex(hash("md5", $mac."*_mQ", true));   // hex code
    $aes128Key = substr($aes128Key, 3, 16);    // size=16 hex code
    
    $path  = "/home/device/m".$mac;
    //echo "mac=[$mac]<br>path=[$path]<br>";

    if (! file_exists($path)) {
        
        mkdir($path);

//        echo "Fail";    // device no found
//        echo "<br>Device No Found!";
//        exit;
    }
    
    $op    = $_GET["op"];
    $aa = file_get_contents($path."/report");   // old status

    //echo "op=[$op]<br>";
    //echo "aa=[$aa]<br>";
    
    if ($op != "") {
        
        $op = str_replace(" ","+", $op);  // " " --> "+"
        $op = rtrim(mcrypt_decrypt(MCRYPT_RIJNDAEL_128, $aes128Key, hex2bin($op), MCRYPT_MODE_ECB), "\0\3");

        // DEV,0,0,0,0,1,0,0,0,0,99999
        //echo "op dec=[$op]<br>";

        $rr = explode(",", $op);
        $ty = $rr[0];

        if ($ty != "DNF"         // "DNF": deansoft
            && $ty != "_"        // "_": New Device
            && $ty != "PAK"      // "PAK": parking gate
            && $ty != "PRT"      // "PRT": printer
            && $ty != "RED"      // "PRT": printer
            && $ty != "DEV") {   // "DEV": Device
            echo "Fail";
            exit;
        }
        
        $sw0 = $rr[1];  // D0
        
        if ($ty == "RED") {
            
            $str = "";
            if ($sw0 == "1")      // enter
                $str = "$mac:進入熱區!";
            else if ($sw0 == "0")
                $str = "$mac:離開熱區!";
            
            echo "OK-".time();
                    
            // send to LINE
            /*
            $headers = array(
                             'Content-Type:multipart/form-data',
                             'Authorization:Bearer 2keqXx741J4VBaxjHJdcC87u8yvew3sNrl6GB3Tptss'
                             );
            $message = array(
                             'message' => $str
                             );
            $ch = curl_init();
            curl_setopt($ch , CURLOPT_URL , "https://notify-api.line.me/api/notify");
            curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, $message);
            $result = curl_exec($ch);
            curl_close($ch);
             */
            exec("curl http://127.0.0.1/device/send.php?m=$str");
            exit;
        }
        
        $sw1 = $rr[2];  // D1
        $sw2 = $rr[3];  // D2

        if ($ty != "_") {
            $sw5 = $rr[6];
            $sw6 = $rr[7];
            $sw7 = $rr[8];
            $sw8 = $rr[9];
            $seq = $rr[10];
        }
    }
    
    //echo "sw0=$sw0,sw1=$sw1,sw2=$sw2<br>";

    $file = "/home/device/_add";
    file_put_contents($file, $mac ." -- ". $rr[0] . " -- ". date("F j, Y, g:i a")."\n", FILE_APPEND | LOCK_EX);
    
    if ($aa != $op) {

        $file  = $path."/report";
        $setfile = fopen($file, "w") or die("Unable to open file report !");
        fwrite($setfile, $op);
        fclose($setfile);
        
        //$file  = $path."/status-".time();
        //$setfile = fopen($file, "w") or die("Unable to open file status !");
        //fwrite($setfile, "sw1=$sw1,sw2=$sw2");
        //fclose($setfile);

    }
    
    echo "OK-".time();
    
    if ($seq == "99999") {
        // device restart
        
    }
    
    if ($rr[0] != "DNF")
    if ($web_report != "")
        file_get_contents($web_report."?time=".time()."&sw1=$sw1&sw2=$sw2");
?>
