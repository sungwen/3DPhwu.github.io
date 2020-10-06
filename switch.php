<?php
    
    // Deansoft -- https://www.setipcam.com/device/switch.php?id=m1afe34dea734&sw1=ON&duration=60&uid=18299829
    
    //             https://www.setipcam.com/device/switch.php?id=m5ecf7f038767&sw1=ON&duration=60&uid=18299829
 
    // parking -- https://www.setipcam.com/device/switch.php?id=m5ecf7f0b0a47&sw1=ON&duration=2&uid=_2173075
    
    //             https://www.setipcam.com/device/switch.php?id=m1afe34dea734&sw1=ON&uid=12345678&duration=60
    
    $sw0      = $_GET["sw0"];
    $sw1      = $_GET["sw1"];
    $sw2      = $_GET["sw2"];
    $sw3      = $_GET["sw3"];
    
    $sw5      = $_GET["sw5"];
    $sw6      = $_GET["sw6"];
    $sw7      = $_GET["sw7"];
    $sw8      = $_GET["sw8"];
    
    if ($_GET["D0"]) $sw0 = $_GET["D0"];
    if ($_GET["D1"]) $sw1 = $_GET["D1"];
    if ($_GET["D2"]) $sw2 = $_GET["D2"];
    if ($_GET["D3"]) $sw3 = $_GET["D3"];
    
    if ($_GET["D5"]) $sw5 = $_GET["D5"];
    if ($_GET["D6"]) $sw6 = $_GET["D6"];
    if ($_GET["D7"]) $sw7 = $_GET["D7"];
    if ($_GET["D8"]) $sw8 = $_GET["D8"];
 
    $log      = $_GET["dbg"];
    $switch6  = $_GET["6sw"];
    
    if ($switch6 != "") {

        $sw4 = $_GET["sw4"];
        if ($_GET["D4"]) $sw4 = $_GET["D4"];
        $sw9 = $_GET["sw9"];
        if ($_GET["D9"]) $sw9 = $_GET["D9"];

        if ($sw1 != "") {
            $op = "1";
            $sw = $sw1;
        }
        else if ($sw2 != "") {
            $op = "2";
            $sw = $sw2;
        }
        else if ($sw3 != "") {
            $op = "3";
            $sw = $sw3;
        }
        else if ($sw4 != "") {
            $op = "4";
            $sw = $sw4;
        }
        else if ($sw5 != "") {
            $op = "5";
            $sw = $sw5;
        }
        else if ($sw6 != "") {
            $op = "6";
            $sw = $sw6;
        }
        else if ($sw9 != "") {
            $op = "9";
            $sw = $sw9;
        }
        else if ($sw0 != "") {
            echo "Nothing Set<br>";
            $op = "0";
            $sw = $sw0;
        }

        if ($sw == "ON")
            $sw = "1";
        else if ($sw == "OFF")
            $sw = "0";
        else {
            echo "Nothing";
            exit;
        }

        // ./sw6 68C63AD6D7940002 3 1
        $aa = "./sw6 $switch6 $op $sw";     // 2173075 for WiFi Device, can't change!
        $bb = exec($aa);

        if ($log != "")
            echo "Run:[$aa], return:[$bb]<br>";

        echo "OK";
        if ($sw0 != "")
            echo "-$bb";
        exit;
    }

    // 16 byte binary blob
    $aes128Key = hash("md5", "*922_528709_!%", true);   // binary code
    $aes128Key = substr(bin2hex($aes128Key), 0, 16);    // size=16 hex code
/*
    $plaintext = "1517762376:59544934:12345678:1:ON:0";
    $cipher = "AES-128-CBC";
    $key = "2fe1b8af71627f4a";
    $ciphertext = openssl_encrypt($plaintext, $cipher, $key);
    echo "E:[$ciphertext]"."\n";
    $decrypted = openssl_decrypt($ciphertext, $cipher, $key);
    echo "D:[$decrypted]"."\n";

    //echo "K: $aes128Key <br>";
    // 2fe1b8af71627f4a
    
    echo phpversion()." -- ";
    if (phpversion() >= "7.0")
        echo "Large than 7.0<br>";
    else
        echo "Small than 7.0<br>";
    
    $a = rtrim(base64_encode(mcrypt_encrypt(MCRYPT_RIJNDAEL_128, $aes128Key, "1517762376:59544934:12345678:1:ON:0", MCRYPT_MODE_CBC)), "\0\3");
    // PCkp6mCrarwXpS8Wr6b4VHrYZxvI0L5I1qh+cSx/dHrIFlCdo+6YmuMF1AiBOhAa
    // PCkp6mCrarwXpS8Wr6b4VHrYZxvI0L5I1qh+cSx/dHr4gP91fgezscB7TkKD8p1a
    
//    openssl_encrypt($plaintext, $cipher, $key,
                    
    echo "D: [$a] <br>";
*/
    //-------------------------------------
    function myEncrypt($sValue, $change) {
        
        global $aes128Key;
        
        $sValue = time().":".$sValue;
        
        //echo "A: [$sValue] <br>";

        $str = rtrim(base64_encode(mcrypt_encrypt(MCRYPT_RIJNDAEL_128, $aes128Key, $sValue, MCRYPT_MODE_CBC)), "\0\3");
        if ($str == "")
            $str = openssl_encrypt($sValue, "AES-128-CBC", $aes128Key);
        
        //echo "B: [$str] <br>";
        
        if ($change == 1) {
            $str = str_replace("/","_", $str);  // "/" --> "_"
            $str = str_replace("+","$", $str);  // "+" --> "$"
        }
        return $str;
    }
    /*
    //-------------------------------------
    function myDecrypt($sValue, $change) {
        
        global $aes128Key;

        if ($change == 1) {
            $sValue = str_replace("$","+", $sValue);
            $sValue = str_replace("_","/", $sValue);
        }
        $str = rtrim(mcrypt_decrypt(MCRYPT_RIJNDAEL_128, $aes128Key, base64_decode($sValue), MCRYPT_MODE_CBC), "\0\3");
        if ($str == "")
            $str = openssl_decrypt($sValue, "AES-128-CBC", $aes128Key);
        
        return $str;
    }
    */
    $dbg      = $_GET["dbg"];
    $mac      = $_GET["id"];
    if ($_GET["mac"]) $mac = $_GET["mac"];
    $uid      = $_GET["uid"];

    $duration = $_GET["duration"];
    
    if (substr($mac, 0, 1) != "m")
        $mac = "m" . $mac;

    $path  = "/home/device/".$mac;
    if (! file_exists($path)) {
        
        echo "Fail";    // device no found
        echo "<br>Device No Found! mac=$mac";
        exit;
    }
    
    $device = file_get_contents($path."/passwd");   // $passwd.":".$uid
    $device = rtrim($device, "\n");
    $rr = explode(":", $device);
    
    if (0)
    if ($uid == "922528709") {
//        $uid = substr($uid, 1);
    }

    else if ($uid == "_2173075")
        $uid = substr($uid, 1);
    
    else if ($device == "") {
        
        echo "Fail<br>No passwd file !!!";    // error uid
        exit;
    }
    else if ($rr[1] != $uid) {
        
        echo "Fail<br>uid Error!".$rr[1];
        exit;
    }
    
    $passwd = $rr[0];
    if ($duration == "")
        $duration = "0";

    // $op = "x:ON/OFF:{duration}"  -- 1: sw1, 2:sw2, 3:sw3, 4:sw4
    if ($sw1 != "")
        $op = "1:$sw1:$duration";
    else if ($sw2 != "")
        $op = "2:$sw2:$duration";
    else if ($sw3 != "")
        $op = "3:$sw3:$duration";
    else if ($sw0 != "")
        $op = "0:$sw0:$duration";
    else if ($sw5 != "")
        $op = "5:$sw5:$duration";
    else if ($sw6 != "")
        $op = "6:$sw6:$duration";
    else if ($sw7 != "")
        $op = "7:$sw7:$duration";
    else if ($sw8 != "")
        $op = "8:$sw8:$duration";
    
    //echo "$passwd:$uid:$op<br>";
    
    // Enc(time:passwd:uid:{x:ON/OFF:{duration}})
    
    // https://www.setipcam.com/device/switch.php?id=m1afe34d3aa7a&sw1=ON&duration=100&uid=922528709
    
    $op0 = "$passwd:$uid:$op";
    if ($dbg != "")
    echo "key=$aes128Key,data=[$op0]<br>";
    
    $op = myEncrypt($op0, 0);
    // Ek("1522937902:52730045:922528709:1:ON:100")
    if ($dbg != "")
    echo "dat=[$op]<br>";

    // send to wifi device
    $aa = "pub ". substr($mac,1) ." 2173075 '$op'";     // 2173075 for WiFi Device, can't change!
    if ($log != "")
        echo $aa."<br>";
    exec($aa);

    echo "OK";

    exit;
?>
